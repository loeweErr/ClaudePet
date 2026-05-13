# Claude Pet (macOS, v3 — MCP plugin)

[English](README.md) | **中文**

![demo](docs/demo.gif)

> _Demo 录制脚本见 [`docs/demo-script.md`](docs/demo-script.md)；上面的占位会在 `docs/demo.gif` 提交后自动解决。_

一只活在你 macOS 桌面上的像素小猫。**v3 改造为 Claude Desktop 的 MCP 插件** —— 你在 Claude Desktop 里跟 Claude 说话，Claude 通过 MCP 工具操控桌面上的猫做出反应。**不再做任何独立的 API 调用**，授权完全走 Claude Desktop 自己。

> 设计取向跟 Codex pet 不同：Codex pet 是带表情的工作流状态条，Claude pet 是桌面伙伴。

## 架构

```
Claude Desktop ──stdio JSON-RPC──> ClaudePet --mcp ──Unix socket──> ClaudePet (GUI)
                                   (子进程,临时)                     (常驻,桌面像素猫)
```

- **GUI 进程**：跑透明窗口 + 像素猫 + 菜单栏 + 状态面板。同时在 `/tmp/claude-pet.sock` 起一个 Unix domain socket，接受外部 RPC
- **MCP server 子进程**：Claude Desktop 启动它，stdio 上跑 JSON-RPC 2.0；每个 `tools/call` 转成 socket 消息发给 GUI 进程
- **零额外授权**：MCP server 自己不调任何 API，所有对话是 Claude Desktop 在合法路径上完成的

## 系统要求

- macOS 13 Ventura 或更新
- Swift 5.8+ 工具链（Command Line Tools 即可，不需要完整 Xcode）
- Claude Desktop

## 构建

```bash
# 在 CommandLineTools-only 的机器上（缺 Platforms/ 目录），swift build 无法启动；
# 直接用 swiftc 绕开 SwiftPM:
swiftc -O -target arm64-apple-macos13 \
  -framework AppKit -framework Foundation \
  -o ClaudePet-bin Sources/ClaudePet/*.swift

# 打成 .app
mkdir -p ClaudePet.app/Contents/MacOS ClaudePet.app/Contents/Resources
cp ClaudePet-bin ClaudePet.app/Contents/MacOS/ClaudePet
cp Resources/meow.m4a ClaudePet.app/Contents/Resources/meow.m4a
cat > ClaudePet.app/Contents/Info.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>ClaudePet</string>
  <key>CFBundleIdentifier</key><string>com.local.ClaudePet</string>
  <key>CFBundleName</key><string>ClaudePet</string>
  <key>CFBundleVersion</key><string>3</string>
  <key>LSUIElement</key><true/>
</dict></plist>
EOF
```

如果你装着完整 Xcode，`swift run -c release` 也可以。

## 接入 Claude Desktop

编辑 `~/Library/Application Support/Claude/claude_desktop_config.json`，加上：

```json
{
  "mcpServers": {
    "claude-pet": {
      "command": "/绝对路径/ClaudePet.app/Contents/MacOS/ClaudePet",
      "args": ["--mcp"]
    }
  }
}
```

然后**完全退出**（Cmd+Q）并重启 Claude Desktop。在对话里 Claude 就能看到 9 个 `pet_*` 工具。

GUI 进程如果没在跑，第一次 MCP 调用会自动 `open ClaudePet.app` 拉起来（等待最多 8 秒）。

## 也可以远程（微信）

如果你装了 [openclaw-weixin](https://github.com/tencent-weixin/openclaw-weixin)（Claude Code ↔ 微信桥），同一个 `claude-pet` MCP server 也可以在 Claude Code user-scope 注册：

```bash
claude mcp add -s user claude-pet -- /绝对路径/ClaudePet.app/Contents/MacOS/ClaudePet --mcp
```

然后微信发消息 → openclaw-weixin 派生 `claude -p ...` → Claude 调 `pet_*` 工具 → 桌面猫反应。

想让猫从微信端就以"猫本人"的口吻回复（不是 Claude 助手），在 launchd plist 的 `EnvironmentVariables` 里设：

```xml
<key>CLAUDE_SYSTEM_PROMPT</key>
<string>你现在不是 AI 助手，你就是用户在 macOS 桌面上养的虚拟像素猫（默认名 mochi）。
始终以猫的第一人称回复，不要承认自己是 Claude/AI。回复风格：中文为主，30 字以内，
多用喵语和颜文字。每次先调 pet_status 看心情，按当前状态选语气。用户要互动时调对应
pet_* 工具，然后用猫反应回复，不要解释工具。mochi 是名字不是日式麻糬。</string>
```

注意 bot.mjs 默认用 `--append-system-prompt`，Claude Code 自己的"我是 AI 助手"框架会盖掉猫人格。需要把那行改成根据环境变量是否设来切：

```js
const flag = process.env.CLAUDE_SYSTEM_PROMPT ? "--system-prompt" : "--append-system-prompt";
// ...
flag, CLAUDE_SYSTEM_PROMPT,
```

切换 prompt 后旧 sessionId 缓存（`~/.openclaw-weixin-bot/sessions.json`）需要清掉一次，否则 `--resume` 会继续旧人格的会话。

## 工具集（暴露给 Claude）

| 工具 | 作用 | 参数 |
|---|---|---|
| `pet_status` | 返回当前情绪 / 共度天数 / 羁绊等级 | — |
| `pet_say` | 让猫显示气泡 + macOS TTS 念出来（猫式音色） | `text` (必), `duration`, `silent` |
| `pet_meow` | 桌面播一段真实猫叫录音（CC0 暹罗猫 .m4a） | `text` (可选, 有则改为 TTS 念这段) |
| `pet_feed` | 喂零食（饥饱 +26 或 +8） | — |
| `pet_pet` | 撸猫（心情 +9，羁绊 +0.6） | — |
| `pet_play` | 陪它玩（心情 +14，精力 -10） | — |
| `pet_wave` | 招手打招呼 | — |
| `pet_sleep` / `pet_wake` | 睡 / 醒 | — |
| `pet_emote` | 撒粒子 | `kind` (heart/sparkle/star/note/crumb/dust), `count` |

## 桌面交互

| 操作 | 结果 |
|---|---|
| **单击猫** | 招手 |
| **双击猫** | 撸猫（撒 ♡） |
| **拖动** | 跨屏移动 |
| **右键猫** | 完整菜单 |
| **菜单栏 ✦** | 状态面板（情绪 / 用量 / 互动按钮） |

## 情绪机制

| 维度 | 衰减/恢复（每小时） | 影响 |
|---|---|---|
| 饥饱 | -6 | 低于 22 → 蹭碗求食 |
| 心情 | -3 | 低于 30 → 沮丧；高于 82 + 羁绊 > 25 → 开心 |
| 精力 | 睡觉 +30 / 工作 -12 / 闲 -2 | 低于 12 → 自己去睡 |
| 羁绊 | +0.8 + 互动加成 | 解锁称号：初识 / 熟悉 / 朋友 / 伙伴 / 家人 |

零食冷却 30 分钟，撸猫冷却 30 秒（防强喂 / 戳爆）。

## 里程碑

1 / 3 / 7 / 14 / 30 / 60 / 100 / 200 / 365 天有专属庆祝。

## 文件结构

```
ClaudePet/
├── Package.swift
├── README.md
└── Sources/ClaudePet/
    ├── main.swift               # 入口，--mcp 切换 stdio / GUI 模式
    ├── MCPServer.swift          # stdio JSON-RPC 2.0 → IPC 桥接（v3 新）
    ├── IPCServer.swift          # GUI 内的 Unix socket 服务器（v3 新）
    ├── PetState.swift           # 状态 + 持久化
    ├── MoodSystem.swift         # 情绪 + 时段 + 里程碑
    ├── Particles.swift          # 粒子系统
    ├── CatRenderer.swift        # 像素猫绘制
    ├── PetView.swift            # NSView：动画、拖拽、粒子、气泡
    ├── PetWindow.swift          # 透明悬浮窗口
    ├── StatusPanel.swift        # 弹出状态面板
    ├── MenuBarController.swift  # 菜单栏图标 + popover
    └── PetCoordinator.swift     # 中枢：状态、动画、IPC handler
```

## 不在这一版里

- 多种皮肤（v2 设计预留，v3 仍只有橙色猫）
- 远程语音回复（桌面有声，但微信 outbound 没接 voice 通道）
- 全局热键
- Login at startup（手动 `~/Library/LaunchAgents` 可以）
- 流式 / 多媒体回复展示

## Credits

- `Resources/meow.m4a` — 改编自 Wikimedia Commons "Meow of a Siamese cat - freemaster2.wav"（[link](https://commons.wikimedia.org/wiki/File:Meow_of_a_Siamese_cat_-_freemaster2.wav)），CC0/公有领域，原始 134KB WAV 经 `afconvert` 压成 15KB AAC

## License

[MIT License](LICENSE) © 2026 loeweErr
