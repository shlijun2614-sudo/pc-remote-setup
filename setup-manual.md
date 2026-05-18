# Windows PC 手动安装指南

如果你不想用一键脚本，按下面步骤手动操作。

## 1. 安装 Tailscale 到 D 盘

下载最新稳定版：

```bash
curl -L -o tailscale-setup.msi "https://pkgs.tailscale.com/stable/tailscale-setup-latest-amd64.msi"
```

静默安装到 D:\Tailscale：

```cmd
msiexec /i tailscale-setup.msi /quiet /norestart INSTALLDIR="D:\Tailscale" ALLUSERS=1
```

## 2. 启动并认证 Tailscale

```cmd
"D:\Tailscale\tailscale.exe" up
```

终端会输出一个授权链接，例如：

```
To authenticate, visit:
    https://login.tailscale.com/a/xxxxx
```

用浏览器打开链接，用任意账号（Google / Microsoft / GitHub）登录授权。

认证成功后，查看状态：

```cmd
"D:\Tailscale\tailscale.exe" status
```

记录你的 **Tailscale IP**（例如 `100.xxx.xxx.xxx`），手机 SSH 要用这个 IP。

## 3. 启用 OpenSSH Server

以管理员身份运行 PowerShell：

```powershell
# 安装 OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# 启动服务并设为开机自启
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# 确认防火墙规则已创建
Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP'
```

确认端口监听：

```powershell
Get-NetTCPConnection -LocalPort 22 | Select-Object LocalAddress, State
```

应该显示 `0.0.0.0:22` 状态为 `Listen`。

## 4. 生成 SSH 密钥对

在 Git Bash 或 PowerShell 中：

```bash
ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519_termius" -N "" -C "termius-mobile"
```

会生成两个文件：
- `id_ed25519_termius` — 私钥（不要上传/分享）
- `id_ed25519_termius.pub` — 公钥

## 5. 配置密钥认证

Windows OpenSSH 对管理员账户使用集中式授权文件：

```powershell
# 创建授权文件
cat "$env:USERPROFILE\.ssh\id_ed25519_termius.pub" | Out-File -FilePath "$env:ProgramData\ssh\administrators_authorized_keys" -Encoding utf8NoBOM

# 设置正确权限（必须只有 Administrators 和 SYSTEM 有权限）
icacls "$env:ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
```

**注意**：如果不是管理员账户，公钥放在 `%USERPROFILE%\.ssh\authorized_keys`。

## 6. 确认 Claude Code CLI 可用

```bash
claude --version
```

如果报错 "command not found"，需要把 Claude Code CLI 加到 PATH，或记录完整路径。

## 7. 手机端配置

见 [phone-setup.md](./phone-setup.md)
