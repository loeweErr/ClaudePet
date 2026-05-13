# Personality

The cat's personality controls three things:

- **The system prompt** mochi speaks with (mostly matters for the WeChat bridge — see below)
- **Reply character cap** that truncates every speech bubble + TTS line
- **TTS toggle** — flip if the audio is bothering you

Open the editor: **right-click mochi → 人格…**

## Built-in presets

| id | name | vibe | example reply |
|---|---|---|---|
| `default` | 中性 | balanced, neutral | "嗯！谢谢你 ♡" |
| `tsundere` | 傲娇 | sharp on the outside, soft inside | "哼…才不是因为想你呢" |
| `clingy` | 粘人 | clingy and warm | "想你了!! 再多摸一下嘛~ (｡>﹏<｡) ♡" |
| `elder` | 老干部 | slow, dignified, caring | "嗯…年轻人，记得喝水" |
| `anime` | 二次元 | catgirl-energy bilingual | "～にゃ! ご主人～ 一起玩!" |

Pick any preset and the editor pre-fills the system prompt. Edit the prompt in the textarea to make any preset your own — the popup auto-switches to **custom** when the prompt diverges from the canonical preset text.

## How it actually takes effect

| What you change | Where it affects |
|---|---|
| **Preset / system prompt** | Saved into `~/Library/Application Support/ClaudePet/personality.json`. ClaudePet itself **does not auto-inject this anywhere**. The file is an *export* for tools running the cat persona externally (see WeChat bridge below). |
| **Reply char limit** | Every `pet_say`, every idle chatter line, every milestone bubble is truncated to this length before showing + speaking. |
| **TTS toggle** | Off → bubbles still appear but audio.speak() is skipped globally. The `pet_say { silent: true }` per-call flag still works on top. |

## WeChat bridge sync (manual)

If you run mochi through [openclaw-weixin](https://github.com/tencent-weixin/openclaw-weixin), you want the cat persona to be the system prompt Claude Code uses for outbound WeChat replies. ClaudePet **does not** touch your launchd plist (too risky on a shared machine), so the sync is one manual paste:

```bash
# 1. Find the prompt
cat ~/Library/Application\ Support/ClaudePet/personality.json | python3 -c '
import json, sys; print(json.load(sys.stdin)["systemPrompt"])'

# 2. Open your openclaw-weixin launch plist
open ~/Library/LaunchAgents/com.openclaw.weixin.plist

# 3. Paste the prompt as the value of CLAUDE_SYSTEM_PROMPT in EnvironmentVariables.
#    Then reload:
launchctl unload ~/Library/LaunchAgents/com.openclaw.weixin.plist
launchctl load   ~/Library/LaunchAgents/com.openclaw.weixin.plist
```

Once the env var is wired, every WeChat message → `claude -p` invocation will speak in the chosen persona.

> Make sure `bot.mjs` uses `--system-prompt` (not `--append-system-prompt`) when the env var is set — see the main README's WeChat section for the one-line patch. Otherwise Claude's "I am an AI assistant" framing overrides your cat persona.

## personality.json schema

```json
{
  "presetId": "tsundere",
  "systemPrompt": "你是 mochi …",
  "replyCharLimit": 25,
  "ttsEnabled": true
}
```

You can also hand-edit this file (no editor restart needed for the WeChat bridge — `launchctl unload/load` re-reads the env var). The next time the **人格…** editor opens, it shows whatever's on disk.

## Reset

To restore defaults: delete `personality.json` and re-open the editor; the dialog seeds itself from the `default` preset. Your PetState (skin, hot keys, days-together) is unaffected.
