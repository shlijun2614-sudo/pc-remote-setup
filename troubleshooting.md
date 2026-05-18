# 问题排查指南

## Tailscale 相关问题

### PC 显示 offline

**症状**：`tailscale status` 显示 `Logged out` 或 PC 节点显示 `offline`

**排查步骤**：

```cmd
# 1. 检查 Tailscale 服务
sc query Tailscale

# 2. 检查网络连通性
"D:\Tailscale\tailscale.exe" netcheck

# 3. 重新认证
"D:\Tailscale\tailscale.exe" up
```

**常见原因**：
- 切换 WiFi 后需要重新认证
- 校园网/公司网屏蔽了 Tailscale 控制平面 (`controlplane.tailscale.com`)
- 电脑休眠后 Tailscale 断开

**校园网限制**：
- 部分大学校园网会屏蔽 Tailscale 的注册服务器
- 症状：能上网但 `tailscale up` 报错连接超时
- 解决：切换到手机热点或其他网络重试

### 两台设备都在线但互相 ping 不通

```cmd
# 检查防火墙
tailscale status
# 确认对方节点不是 "offline"
```

如果都是 online 但无法通信，可能是：
- UDP 被防火墙拦截 → Tailscale 会自动 fallback 到 DERP 中继（较慢但可用）
- Windows 防火墙拦截了 Tailscale 虚拟网卡

## SSH 连接问题

### Connection refused / Connection timed out

**排查步骤**：

```powershell
# 1. 确认 sshd 在运行
Get-Service sshd

# 2. 确认端口监听
Get-NetTCPConnection -LocalPort 22

# 3. 确认防火墙
Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' | Select-Object Enabled

# 4. 本地测试
ssh localhost
```

### Permission denied (publickey)

**原因**：私钥不匹配或权限问题

**排查**：

```powershell
# 检查 authorized_keys 文件存在
Test-Path "$env:ProgramData\ssh\administrators_authorized_keys"

# 检查权限（必须是 Administrators 和 SYSTEM 独占）
icacls "$env:ProgramData\ssh\administrators_authorized_keys"

# 重新生成密钥并配置
ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\id_ed25519_termius" -N '""'
# 然后重新执行 setup-windows.ps1 的第 4-5 步
```

## 校园网 / 网络限制

### 校园网完全无法使用 Tailscale

如果校园网对 Tailscale 做了深度屏蔽，备选方案：

#### 方案 A：VS Code Tunnel（推荐，免费）

PC 上已安装 VS Code 时：

```cmd
# 启动隧道
code tunnel

# 或安装为服务自动启动
code tunnel service install --accept-server-license-terms --name my-pc
```

手机浏览器访问：`https://vscode.dev/tunnel/my-pc`

优点：走 Microsoft 服务器，校园网几乎不拦。
缺点：手机浏览器体验较挤。

#### 方案 B：frp + VPS（最稳，需要服务器）

购买廉价 VPS（阿里云/腾讯云轻量应用服务器，约 ¥9/月）：

```bash
# VPS 上运行 frps (服务端)
frps -c frps.ini

# PC 上运行 frpc (客户端)
frpc -c frpc.ini
```

配置指向 PC 的 SSH 端口，手机直接 SSH 到 VPS 的公网 IP + 映射端口。

#### 方案 C：Oracle Cloud 永久免费 VPS

Oracle Cloud 提供 Always Free 套餐（ARM 服务器，免费永久）：

- 注册需要国际信用卡（Visa/Mastercard 双标）
- 区域选择日本东京或韩国首尔
- 注册成功后搭建 frp 或 WireGuard

#### 方案 D：手机热点

最省事的方案：需要远程时把 PC 切到手机热点，Tailscale 立即恢复。

## Claude Code 相关问题

### claude 命令找不到

```bash
# 检查 Claude Code CLI 路径
where claude

# 如果不在 PATH，使用完整路径调用
# 或添加到用户 PATH:
# [系统属性] → [环境变量] → 编辑 Path，添加 Claude Code 所在目录
```

### 会话恢复失败

```bash
# 列出最近会话
claude --resume

# 或指定会话 ID
claude --resume <session-id>

# 查看所有会话
ls ~/.claude/projects/
```

## 手机端问题

### Termius 连接超时

1. 确认 Tailscale App 已打开且登录
2. 确认 PC 在 Tailscale 中显示 online
3. 检查输入的 IP 是否正确（Tailscale IP 不是公网 IP）
4. 尝试切换手机网络（WiFi / 4G / 5G）

### 私钥导入失败

- 确保复制了完整的私钥内容（包括 `-----BEGIN OPENSSH PRIVATE KEY-----` 和 `-----END OPENSSH PRIVATE KEY-----`）
- 确保没有多余的空格或换行
- 如果 Termius 提示格式错误，尝试在 PC 上用 `ssh-keygen -m PEM` 重新生成

## 日志收集

如果上述方法都无效，收集以下信息寻求帮助：

```cmd
# Tailscale 日志
"D:\Tailscale\tailscale.exe" bugreport

# SSH 服务日志
Get-WinEvent -LogName "OpenSSH/Operational" | Select-Object -First 20

# Tailscale 服务日志
sc query Tailscale
"D:\Tailscale\tailscale.exe" status
"D:\Tailscale\tailscale.exe" netcheck
```
