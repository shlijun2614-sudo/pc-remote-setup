#Requires -RunAsAdministrator
<#
.SYNOPSIS
    一键配置 Windows PC 的 Tailscale + OpenSSH + SSH 密钥认证
.DESCRIPTION
    下载并安装 Tailscale、启用 OpenSSH Server、生成 SSH 密钥、配置防火墙
.NOTES
    必须以管理员身份运行 PowerShell
#>

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " PC 远程控制环境一键配置脚本" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# === 1. Tailscale ===
Write-Host "[1/5] 检查/安装 Tailscale..." -ForegroundColor Yellow

$TailscaleDir = "D:\Tailscale"
$TailscaleExe = "$TailscaleDir\tailscale.exe"

if (Test-Path $TailscaleExe) {
    Write-Host "      Tailscale 已安装" -ForegroundColor Green
    & $TailscaleExe version | Select-Object -First 1
} else {
    Write-Host "      下载 Tailscale..." -ForegroundColor Yellow
    $MsiUrl = "https://pkgs.tailscale.com/stable/tailscale-setup-latest-amd64.msi"
    $MsiPath = "$env:TEMP\tailscale-setup.msi"
    Invoke-WebRequest -Uri $MsiUrl -OutFile $MsiPath -UseBasicParsing

    Write-Host "      安装到 $TailscaleDir ..." -ForegroundColor Yellow
    $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$MsiPath`"", "/quiet", "/norestart", "INSTALLDIR=`"$TailscaleDir`"", "ALLUSERS=1" -Wait -PassThru
    if ($proc.ExitCode -ne 0 -and $proc.ExitCode -ne 3010) {
        Write-Error "Tailscale 安装失败，退出码: $($proc.ExitCode)"
    }
    Remove-Item $MsiPath -ErrorAction SilentlyContinue
    Write-Host "      Tailscale 安装完成" -ForegroundColor Green
}

# 检查 Tailscale 服务
$tsService = Get-Service -Name "Tailscale" -ErrorAction SilentlyContinue
if (-not $tsService -or $tsService.Status -ne 'Running') {
    Write-Host "      启动 Tailscale 服务..." -ForegroundColor Yellow
    if (-not $tsService) {
        Write-Error "Tailscale 服务未找到，安装可能未成功"
    }
    Start-Service -Name "Tailscale"
}

# Tailscale 认证状态
$tsStatus = & $TailscaleExe status 2>$null
if ($tsStatus -match "Logged out") {
    Write-Host "      Tailscale 未登录，正在启动认证..." -ForegroundColor Yellow
    Write-Host "      请打开浏览器访问下面的链接完成登录：" -ForegroundColor Cyan
    & $TailscaleExe up 2>&1 | ForEach-Object { Write-Host "      $_" -ForegroundColor Cyan }
} else {
    Write-Host "      Tailscale 已登录" -ForegroundColor Green
    $tsStatus | Select-Object -First 5 | ForEach-Object { Write-Host "      $_" }
}

Write-Host ""

# === 2. OpenSSH Server ===
Write-Host "[2/5] 检查/安装 OpenSSH Server..." -ForegroundColor Yellow

$sshCap = Get-WindowsCapability -Online -Name "OpenSSH.Server*" | Select-Object -First 1
if ($sshCap.State -ne "Installed") {
    Write-Host "      安装 OpenSSH Server..." -ForegroundColor Yellow
    Add-WindowsCapability -Online -Name $sshCap.Name
} else {
    Write-Host "      OpenSSH Server 已安装" -ForegroundColor Green
}

$sshService = Get-Service -Name "sshd" -ErrorAction SilentlyContinue
if (-not $sshService -or $sshService.Status -ne 'Running') {
    Write-Host "      启动 sshd 服务..." -ForegroundColor Yellow
    Start-Service sshd
    Set-Service -Name sshd -StartupType Automatic
} else {
    Write-Host "      sshd 已在运行" -ForegroundColor Green
}

# 防火墙
$fwRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
if (-not $fwRule) {
    Write-Host "      创建防火墙规则..." -ForegroundColor Yellow
    New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (sshd)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}
Write-Host "      OpenSSH 配置完成" -ForegroundColor Green
Write-Host ""

# === 3. SSH 密钥 ===
Write-Host "[3/5] 生成 SSH 密钥对..." -ForegroundColor Yellow

$SshDir = "$env:USERPROFILE\.ssh"
$KeyFile = "$SshDir\id_ed25519_termius"
$PubFile = "$KeyFile.pub"

if (-not (Test-Path $SshDir)) {
    New-Item -ItemType Directory -Path $SshDir -Force | Out-Null
}

if (Test-Path $KeyFile) {
    Write-Host "      密钥对已存在: $KeyFile" -ForegroundColor Green
} else {
    Write-Host "      生成 ed25519 密钥对..." -ForegroundColor Yellow
    ssh-keygen -t ed25519 -f $KeyFile -N '""' -C "termius-mobile" | Out-Null
    Write-Host "      密钥对生成完成" -ForegroundColor Green
}

Write-Host ""

# === 4. 配置密钥认证 ===
Write-Host "[4/5] 配置 SSH 密钥认证..." -ForegroundColor Yellow

$AdminKeysFile = "$env:ProgramData\ssh\administrators_authorized_keys"
$PubKeyContent = Get-Content $PubFile -Raw

if (Test-Path $AdminKeysFile) {
    $ExistingKeys = Get-Content $AdminKeysFile -Raw
    if ($ExistingKeys -match [regex]::Escape($PubKeyContent.Trim())) {
        Write-Host "      公钥已存在于 administrators_authorized_keys" -ForegroundColor Green
    } else {
        Write-Host "      追加公钥到 administrators_authorized_keys..." -ForegroundColor Yellow
        Add-Content -Path $AdminKeysFile -Value $PubKeyContent -NoNewline
    }
} else {
    Write-Host "      创建 administrators_authorized_keys..." -ForegroundColor Yellow
    Set-Content -Path $AdminKeysFile -Value $PubKeyContent -NoNewline -Encoding utf8NoBOM
}

# 修复权限（Windows OpenSSH 对管理员账户的密钥文件有严格要求）
icacls "$AdminKeysFile" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F" | Out-Null
Write-Host "      权限已修复" -ForegroundColor Green

Write-Host ""

# === 5. 汇总信息 ===
Write-Host "[5/5] 配置完成！" -ForegroundColor Green
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " 请记录以下信息用于手机端配置：" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Tailscale IP
$tsStatusLines = & $TailscaleExe status 2>$null
$tailscaleIP = ($tsStatusLines | Select-String "^(\d+\.\d+\.\d+\.\d+)").Matches.Groups[1].Value
if ($tailscaleIP) {
    Write-Host "  Tailscale IP: $tailscaleIP" -ForegroundColor Green
} else {
    Write-Host "  Tailscale 尚未分配 IP（请先完成认证登录）" -ForegroundColor Yellow
}

# 用户名
Write-Host "  SSH 用户名: $env:USERNAME" -ForegroundColor Green
Write-Host "  SSH 端口: 22" -ForegroundColor Green
Write-Host ""
Write-Host "  私钥文件: $KeyFile" -ForegroundColor Yellow
Write-Host "  公钥文件: $PubFile" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Termius 连接地址: $tailscaleIP:22" -ForegroundColor Green
Write-Host ""
Write-Host "  Claude Code 恢复会话命令:" -ForegroundColor Cyan
Write-Host "      claude --resume" -ForegroundColor White
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " 下一步：在手机 Termius 中导入私钥并连接" -ForegroundColor Cyan
Write-Host " 详见 phone-setup.md" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
