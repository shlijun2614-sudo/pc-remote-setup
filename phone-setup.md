# 手机端配置指南

## 需要安装的 App

| App | 用途 | 下载 |
|-----|------|------|
| **Tailscale** | 组建加密私网，让手机能访问 PC | App Store / Google Play / 应用商店 |
| **Termius** | SSH 客户端，连接 PC 终端 | App Store / Google Play |

## 第一步：Tailscale

1. 安装 Tailscale App
2. 用 **和 PC 同一个账号** 登录（Google / Microsoft / GitHub）
3. 登录后，你会在设备列表中看到你的 PC（例如 `PC-20240401SMVS`）
4. 确认 PC 显示为 `online`

## 第二步：Termius

### 新建 Host

打开 Termius → **Hosts** → 点击 **+** 新建：

| 字段 | 填写内容 |
|------|----------|
| **Label** | 任意，例如 `PC-Home` |
| **Address** | PC 的 Tailscale IP（例如 `100.105.64.13`） |
| **Port** | `22` |
| **Username** | PC 的 Windows 用户名（例如 `Administrator`） |

### 导入 SSH 私钥

**如果你希望密码免输入（推荐）：**

1. Termius → **Keychain** → **New Key** → **Import Private Key** → **Paste**
2. 从 PC 上复制私钥内容：

```bash
# 在 PC 的 Git Bash 中执行
cat ~/.ssh/id_ed25519_termius
```

3. 将输出的内容完整复制到 Termius 的粘贴框
4. Key Name: 任意，例如 `PC-Home-Key`
5. Passphrase: 留空

回到刚才新建的 Host → **Authentication** → 选择 **Key** → 选择刚导入的 key。

**如果不用密钥（输入密码）：**

Authentication 选择 **Password**，保存。每次连接时输入 Windows 登录密码。

## 第三步：连接并使用

1. 在 Termius 中点击你创建的 Host
2. 看到命令提示符 `~$` 即连接成功
3. 运行 Claude Code：

```bash
# 接续之前的会话
claude --resume

# 或新开会话
claude

# R 语言（如果已安装）
/d/Rlanguage/bin/Rscript -e 'sqrt(2)'
```

## 常用操作

| 操作 | Termius 方法 |
|------|-------------|
| 复制文本 | 长按选择 → 复制 |
| 粘贴 | 长按空白处 → 粘贴 |
| Tab 键 | 键盘上方功能栏有 Tab 按钮 |
| Ctrl+C / Ctrl+Z | 键盘上方功能栏有 Ctrl 按钮 |
| 横屏模式 | 手机旋转 90 度，Termius 自动适配 |
| 字体大小 | Termius 设置 → Terminal → Font Size |
| 主题 | Termius 设置 → Terminal → Theme |

## 多 PC 管理

如果你有多个电脑都配置了 Tailscale + SSH，每台电脑会有**不同的 Tailscale IP**。在 Termius 中分别为每台电脑创建一个 Host，用各自的 IP 连接。

```
Host 1: PC-Home      → 100.105.64.13
Host 2: PC-School    → 100.74.124.2
```
