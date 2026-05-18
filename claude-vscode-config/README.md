# VSCode + Claude Code 配置同步

本仓库包含让 Claude Code 在 VSCode 中**无需权限弹窗**的配置文件。

## 文件说明

| 文件 | 对应路径 | 作用 |
|---|---|---|
| `global-settings.json` | `~/.claude/settings.json` | Claude Code 全局设置(权限模式、主题等) |
| `global-settings-local.json` | `~/.claude/settings.local.json` | Claude Code 全局本地设置(环境变量等) |
| `vscode-settings.json` | VSCode 用户设置 JSON | VSCode 扩展的权限配置 |

## 核心配置

所有文件共同实现 **零权限弹窗**：
- `permissions.defaultMode: "bypassPermissions"` — 全局跳过所有权限确认
- `skipDangerousModePermissionPrompt: true` — 不显示危险模式警告
- `claudeCode.allowDangerouslySkipPermissions: true` — VSCode 扩展允许跳过权限
- `claudeCode.initialPermissionMode: "bypassPermissions"` — VSCode 扩展默认 bypass 模式

## 安装步骤

### 1. Claude Code 全局配置

**Windows:**
```powershell
# 创建 Claude Code 配置目录
mkdir -Force "$env:USERPROFILE\.claude"

# 复制配置文件
copy global-settings.json "$env:USERPROFILE\.claude\settings.json"
copy global-settings-local.json "$env:USERPROFILE\.claude\settings.local.json"
```

**macOS/Linux:**
```bash
mkdir -p ~/.claude
cp global-settings.json ~/.claude/settings.json
cp global-settings-local.json ~/.claude/settings.local.json
```

### 2. VSCode 扩展设置

1. 打开 VSCode
2. `Ctrl+Shift+P` → `Preferences: Open User Settings (JSON)`
3. 将 `vscode-settings.json` 的内容**合并**到现有 settings.json 中

### 3. 填入 API Token

编辑 `~/.claude/settings.json` 和 `~/.claude/settings.local.json`：
```json
"env": {
    "ANTHROPIC_AUTH_TOKEN": "YOUR_TOKEN_HERE",
    "ANTHROPIC_BASE_URL": "https://api.kimi.com/coding/"
}
```

### 4. 重启 VSCode

关闭并重新打开 VSCode，Claude Code 扩展将读取新配置。

## 注意事项

- `ANTHROPIC_AUTH_TOKEN` 是敏感信息，已从同步文件中移除，需手动填入
- `additionalDirectories` 中的路径可能需要根据新设备调整
- bypassPermissions 模式下 Claude 可以执行任何操作，请确保只在可信环境中使用

## 原始配置来源

- 生成日期: 2026-05-19
- 生成设备: Windows 11 + VSCode + Claude Code 扩展 2.1.143
