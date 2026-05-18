# PC 手机远程控制方案 (Tailscale + OpenSSH + Termius)

用于 Windows PC 通过手机随时随地 SSH 远程控制，运行 Claude Code 等 CLI 工具。

## 架构

```
手机 (Termius App)
  |
  v
Tailscale 加密私网
  |
  v
PC (OpenSSH Server, 端口 22)
  |
  v
Claude Code / R / 任意 CLI
```

## 前提条件

- Windows 10/11 PC (管理员权限)
- iOS/Android 手机
- 同一个 Tailscale 账号
- GitHub 账号 (用于本仓库)

## 快速开始

在新电脑上执行以下步骤：

### 方式一：PowerShell 一键脚本（推荐）

以管理员身份打开 PowerShell，执行：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
iwr -useb https://raw.githubusercontent.com/shlijun2614-sudo/pc-remote-setup/main/setup-windows.ps1 | iex
```

### 方式二：手动逐步执行

见 [setup-manual.md](./setup-manual.md)

### 方式三：本地脚本

将本仓库克隆到新电脑，运行：

```bash
# Git Bash
./setup-windows.sh
```

或

```powershell
# PowerShell
.\setup-windows.ps1
```

## 手机端配置

见 [phone-setup.md](./phone-setup.md)

## 常见问题

见 [troubleshooting.md](./troubleshooting.md)

## 校园网限制说明

本方案依赖 Tailscale 控制平面 (`login.tailscale.com`)。

- **家庭 WiFi / 手机热点**：Tailscale 正常连通
- **部分校园网**：可能屏蔽 Tailscale 控制平面，导致设备显示 offline

如果遇到校园网屏蔽，备选方案：
1. 切到手机热点使用
2. 购买廉价 VPS + frp 自建隧道（见 troubleshooting）
3. VS Code Tunnel（走 Microsoft 服务器，校园网通常不拦）

## 文件说明

| 文件 | 用途 |
|------|------|
| `setup-windows.ps1` | Windows 一键安装脚本 (PowerShell) |
| `setup-windows.sh` | Windows 安装脚本 (Git Bash) |
| `setup-manual.md` | 手动逐步安装指南 |
| `phone-setup.md` | 手机 Termius + Tailscale 配置 |
| `troubleshooting.md` | 问题排查和备选方案 |
