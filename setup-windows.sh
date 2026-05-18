#!/usr/bin/env bash
# Windows PC 远程控制环境一键配置脚本 (Git Bash)
# 必须以管理员身份运行

set -e

echo "=========================================="
echo " PC 远程控制环境一键配置脚本 (Bash)"
echo "=========================================="
echo ""

# === 1. Tailscale ===
echo "[1/5] 检查/安装 Tailscale..."

TAILSCALE_DIR="/d/Tailscale"
TAILSCALE_EXE="$TAILSCALE_DIR/tailscale.exe"

if [ -f "$TAILSCALE_EXE" ]; then
    echo "      Tailscale 已安装"
    "$TAILSCALE_EXE" version 2>/dev/null | head -1
else
    echo "      下载 Tailscale..."
    MSI_URL="https://pkgs.tailscale.com/stable/tailscale-setup-latest-amd64.msi"
    MSI_PATH="/tmp/tailscale-setup.msi"
    curl -L -o "$MSI_PATH" "$MSI_URL" 2>/dev/null

    echo "      安装到 $TAILSCALE_DIR ..."
    MSI_WIN_PATH=$(cygpath -w "$MSI_PATH")
    msiexec //i "$MSI_WIN_PATH" //quiet //norestart "INSTALLDIR=$TAILSCALE_DIR" ALLUSERS=1
    rm -f "$MSI_PATH"
    echo "      Tailscale 安装完成"
fi

# 检查服务
if sc query Tailscale 2>/dev/null | grep -q "RUNNING"; then
    echo "      Tailscale 服务运行中"
else
    echo "      启动 Tailscale 服务..."
    net start Tailscale 2>/dev/null || true
fi

# 认证状态
TS_STATUS=$("$TAILSCALE_EXE" status 2>/dev/null | head -5)
if echo "$TS_STATUS" | grep -q "Logged out"; then
    echo "      Tailscale 未登录，启动认证..."
    "$TAILSCALE_EXE" up 2>&1
else
    echo "      Tailscale 已登录"
    echo "$TS_STATUS"
fi

echo ""

# === 2. OpenSSH Server ===
echo "[2/5] 检查/安装 OpenSSH Server..."

SSH_STATE=$(powershell -Command "(Get-WindowsCapability -Online -Name 'OpenSSH.Server*').State" 2>/dev/null)
if [ "$SSH_STATE" != "Installed" ]; then
    echo "      安装 OpenSSH Server..."
    powershell -Command "Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0"
else
    echo "      OpenSSH Server 已安装"
fi

if sc query sshd 2>/dev/null | grep -q "RUNNING"; then
    echo "      sshd 已在运行"
else
    echo "      启动 sshd 服务..."
    powershell -Command "Start-Service sshd; Set-Service -Name sshd -StartupType Automatic"
fi

echo "      OpenSSH 配置完成"
echo ""

# === 3. SSH 密钥 ===
echo "[3/5] 生成 SSH 密钥对..."

SSH_DIR="/c/Users/$USER/.ssh"
KEY_FILE="$SSH_DIR/id_ed25519_termius"
PUB_FILE="$KEY_FILE.pub"

mkdir -p "$SSH_DIR"

if [ -f "$KEY_FILE" ]; then
    echo "      密钥对已存在: $KEY_FILE"
else
    echo "      生成 ed25519 密钥对..."
    ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -C "termius-mobile"
    echo "      密钥对生成完成"
fi

echo ""

# === 4. 配置密钥认证 ===
echo "[4/5] 配置 SSH 密钥认证..."

ADMIN_KEYS="/c/ProgramData/ssh/administrators_authorized_keys"
PUB_KEY=$(cat "$PUB_FILE")

if [ -f "$ADMIN_KEYS" ]; then
    if grep -qF "$PUB_KEY" "$ADMIN_KEYS" 2>/dev/null; then
        echo "      公钥已存在于 administrators_authorized_keys"
    else
        echo "      追加公钥..."
        echo "$PUB_KEY" >> "$ADMIN_KEYS"
    fi
else
    echo "      创建 administrators_authorized_keys..."
    echo "$PUB_KEY" > "$ADMIN_KEYS"
fi

# 修复权限
icacls.exe "$ADMIN_KEYS" //inheritance:r //grant "Administrators:F" //grant "SYSTEM:F" 2>/dev/null
echo "      权限已修复"

echo ""

# === 5. 汇总 ===
echo "[5/5] 配置完成！"
echo ""
echo "=========================================="
echo " 请记录以下信息用于手机端配置："
echo "=========================================="
echo ""

TAILSCALE_IP=$("$TAILSCALE_EXE" status 2>/dev/null | head -1 | awk '{print $1}')
if [ -n "$TAILSCALE_IP" ] && [ "$TAILSCALE_IP" != "100.xxx.xxx.xxx" ]; then
    echo "  Tailscale IP: $TAILSCALE_IP"
else
    echo "  Tailscale 尚未分配 IP（请先完成认证登录）"
fi

echo "  SSH 用户名: $USER"
echo "  SSH 端口: 22"
echo ""
echo "  私钥文件: $KEY_FILE"
echo "  公钥文件: $PUB_FILE"
echo ""
[ -n "$TAILSCALE_IP" ] && echo "  Termius 连接地址: $TAILSCALE_IP:22"
echo ""
echo "  Claude Code 恢复会话命令:"
echo "      claude --resume"
echo ""
echo "=========================================="
echo " 下一步：在手机 Termius 中导入私钥并连接"
echo " 详见 phone-setup.md"
echo "=========================================="
