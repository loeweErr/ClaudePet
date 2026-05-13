# 小红书风格图文 — 3 篇草稿

小红书的语感：第一人称 + 真实小情绪 + 表情符号但不过载 + 9 张图位 + 标签拼接。每篇都附图位说明，等截图齐了直接套。

---

## 帖子 1 — 「我用 Claude 在桌面养了只猫」

**封面图**：`docs/screenshots/hero.png`（猫 + 状态面板）

**标题**：我用 Claude 在桌面养了只猫，结果上班变温柔了 ฅ

**正文**：

```
朋友们，我犯病了 ✦

最近做了个东西叫 ClaudePet，是一只活在 macOS 桌面上的像素猫，
跟 Claude Desktop 接通了。

我跟 Claude 说："给猫喂点零食吧"，Claude 调用 pet_feed 工具，
桌面上的猫真的凑过去吃饭，撒一地饼干屑。

不是 ChatGPT 那种回复"好的我已经喂了"的虚假交互。
是真的桌面上有动画。

养了两周，发现一件神奇的事：
我跟 Claude 说话的语气变软了 (｡◕‿◕｡)
不是因为 Claude 有感情，
而是因为猫在看，而且猫记得。

它有羁绊值，从初识 → 熟悉 → 朋友 → 伙伴 → 家人。
一起 7 天有专属庆祝。30 天会撒一大堆星星。
365 天会说"一年了 ♡ 谢谢你"。

我打开终端的次数变多了，只为了看看它。
———

技术上：MIT 开源，macOS 13+，Swift 写的。
不需要任何额外 API key，全部走 Claude Desktop 自己的授权。
brew 一行装。

GitHub 搜 ClaudePet，链接在评论区 ✦

#claude #macos #开发者日常 #桌面美化 #ai养成
#chatgpt替代 #程序员日常 #小猫
```

**图位**（9 图）：
1. 封面：hero.png
2. 在 Claude Desktop 输入"喂猫" → 工具调用展开截图
3. 猫吃饭 + 碎屑粒子动画 frame
4. 状态面板放大：羁绊 / 心情 / 共度天数
5. 三个皮肤并排：mochi / shadow / snow
6. 菜单栏 ✦ 切换皮肤截图
7. 庆祝里程碑动画 frame（撒星星）
8. 双击猫撒爱心
9. 全家福（结束图）：cat + Claude Desktop 一起

---

## 帖子 2 — 「摸鱼时间一只电子猫拯救了我」

**封面图**：cat 在 sleep pose（蜷缩 + ZZZ）

**标题**：摸鱼时间被一只电子猫救了，专注力回来了 zzz✦

**正文**：

```
番茄钟用了三年，每次都被通知打断 (>﹏<)
直到我接通了 ClaudePet。

操作流程：
1. 跟 Claude 说"开 25 分钟番茄钟，让 mochi 睡到结束"
2. Claude 调用番茄钟 MCP + pet_sleep
3. 桌面上那只猫真的蜷起来开始打呼
4. 菜单栏图标变成 ✦💤
5. 25 分钟后 Claude 自动唤醒 + pet_emote sparkle
6. 撒一脸星星 ✨

效果：
✓ 通知不再打扰我
✓ 但我能看到右下角有一只睡觉的猫
✓ 视觉提醒比声音/弹窗温柔 1000 倍
✓ 而且看着 sleeping cat 莫名其妙就想坚持下去

不打扰、有陪伴、有仪式感 = 最好的专注工具。

完整配方在 GitHub，docs/recipes/focus-guard.md 直接抄。

#番茄钟 #专注力 #摸鱼 #程序员 #开发者工具
#claude #macos #桌面美化 #ai #自律
```

**图位**：
1. 封面：sleeping cat + 菜单栏 ✦💤
2. Claude Desktop 启动番茄钟的对话截图
3. 猫睡觉动画 + ZZZ 字
4. 25 分钟过去截图（钟表示意）
5. wake-up + sparkle 爆发 frame
6. 配方文档截图（focus-guard.md）

---

## 帖子 3 — 「程序员浪漫：让 Claude 帮我养猫」

**封面图**：`docs/screenshots/skins.png`（三皮肤并排）

**标题**：程序员浪漫 = 让 AI 帮我养电子猫，还能自己换皮肤 ฅ^•ﻌ•^ฅ

**正文**：

```
开源新作 ClaudePet 上线，桌面养猫这件事，被 MCP 重新定义了。

✦ 你在 Claude Desktop 里说"让猫睡觉"
✦ Claude 调用 pet_sleep
✦ 桌面上那只像素猫真的蜷起来
✦ 没有任何额外 API 费用
✦ 没有任何额外授权
✦ 全部走你已经付钱的 Claude Desktop

10 个工具 (pet_status / pet_feed / pet_pet / pet_play / 
pet_wave / pet_say / pet_meow / pet_sleep / pet_wake / 
pet_emote)，覆盖一只猫的全部社交需求。

最让我得意的两个细节：
1. 皮肤系统是配色板 JSON，不是 PNG
   想换猫的颜色？复制一份 JSON，改 10 个十六进制色号。
   蓝紫色暮光猫 / 粉紫色独角兽猫 / 纯黑色暗夜猫，30 秒搞定。

2. 桌面双击猫会撒一地爱心 ♡
   这个是隐藏的彩蛋。说话的时候记得双击它。

⚠ macOS 13+，brew 一行装：
brew install --cask loeweErr/tap/claude-pet

GitHub 搜 ClaudePet，求 star 求 PR 求自定义皮肤 ♡

#开源 #程序员 #ai #claude #桌面养成
#macos #pixelart #电子宠物 #github推荐
```

**图位**：
1. 封面：skins.png
2. 调色板 JSON 截图（palette.json 编辑器视图）
3. mochi 单图 close-up
4. shadow 单图 close-up
5. snow 单图 close-up
6. 双击撒爱心 frame
7. brew install 命令终端截图
8. GitHub 仓库主页截图

---

## 发布节奏建议

第 0 周：先发帖子 1（产品故事），引流到 GitHub  
第 1 周：发帖子 2（专注配方），证明实用价值  
第 2 周：发帖子 3（皮肤），鼓励 UGC

每篇隔几天再编辑一次（小红书喜欢"编辑过"的笔记，会再分发一次流量）。
评论区主动回复前 5 条，提到 GitHub 链接。
