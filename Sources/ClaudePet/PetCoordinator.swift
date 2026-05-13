import AppKit
import ServiceManagement

/// Central brain. Owns state, animates the pet, runs task workflows,
/// and wires events between the cat view, status panel, and menubar.
final class PetCoordinator: NSObject, PetViewDelegate, StatusPanelDelegate, IPCRequestHandler {

    var state: PetState
    let window: PetWindow
    let view: PetView
    let menuBar: MenuBarController
    private var statusMode: StatusMode = .idle
    private let ipcServer = IPCServer()
    private let audio = PetAudio()
    private let hotKeys = HotKeyManager()

    // Timers
    private var taskTimers: [Timer] = []
    private var chatterTimer: Timer?
    private var walkTimer: Timer?
    private var saveTimer: Timer?
    private var bubbleClearTimer: Timer?
    private var usageTickTimer: Timer?
    private var idleSleepTimer: Timer?
    private var lastInteract: Date = Date()

    init(state: PetState) {
        self.state = state
        self.window = PetWindow()
        self.view = PetView(frame: NSRect(origin: .zero, size: PetView.viewSize))
        self.menuBar = MenuBarController()
        super.init()

        window.contentView = view
        view.delegate = self
        menuBar.panel.delegate = self

        // Restore the saved skin (falls back to mochi if the id is unknown,
        // e.g. a community skin that was uninstalled).
        SkinManager.shared.activate(id: self.state.skinId)
        self.state.skinId = SkinManager.shared.active.id

        // Initial position
        placeInitial()

        // Boot greeting — time-aware
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.deliverBootGreeting()
        }

        // Periodic timers
        usageTickTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.tickUsage()
            self?.tickMood()
            self?.checkMilestones()
        }
        saveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.state.save()
        }
        chatterTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            self?.maybeChatter()
        }
        scheduleWalk()
        idleSleepTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.checkIdleSleep()
            self?.checkMoodActions()
        }

        // Start IPC for MCP plugin bridge
        ipcServer.handler = self
        ipcServer.start()

        // Global hot keys (⌃⌥P summon, ⌃⌥H toggle, ⌃⌥F feed)
        hotKeys.onAction = { [weak self] action in self?.handleHotKey(action) }
        if self.state.hotkeysEnabled { hotKeys.enable() }

        // Apply persisted launch-at-login preference. SMAppService is
        // idempotent so re-applying on every launch is safe.
        applyLaunchAtLogin()

        refreshPanel()
    }

    deinit {
        ipcServer.stop()
    }

    // MARK: - Boot / Daily greeting

    private func deliverBootGreeting() {
        let cal = Calendar.current
        let firstToday = !cal.isDate(state.lastGreetingDate, inSameDayAs: Date())
        if firstToday && state.hasPlaced {
            // Time-of-day greeting (first launch of the day)
            let msg = DayPhase.current().greeting(name: state.name, days: state.daysWithPet)
            say(msg, duration: 3.4)
            state.lastGreetingDate = Date()
            if DayPhase.current() == .lateNight {
                view.emit(.dust, count: 4, life: 1.8)
            } else {
                view.emit(.sparkle, count: 5, life: 1.6)
            }
        } else if !state.hasPlaced {
            // True first launch
            say("hi! 我是 \(state.name) ♡", duration: 3.0)
            view.emit(.heart, count: 6, life: 1.4)
            state.lastGreetingDate = Date()
        } else {
            // Returning later same day
            say("我回来啦 ✦", duration: 2.0)
        }
    }

    func showWindow() {
        window.orderFrontRegardless()
    }

    // MARK: - Positioning

    private func placeInitial() {
        if state.hasPlaced {
            window.setFrameOrigin(NSPoint(x: state.posX, y: state.posY))
        } else {
            guard let screen = NSScreen.main else { return }
            let visible = screen.visibleFrame
            let origin = NSPoint(x: visible.maxX - PetView.viewSize.width - 60,
                                 y: visible.minY + 60)
            window.setFrameOrigin(origin)
            state.posX = origin.x; state.posY = origin.y
            state.hasPlaced = true
        }
    }

    private func savePosition() {
        let f = window.frame
        state.posX = f.origin.x; state.posY = f.origin.y
    }

    // MARK: - Speech bubble

    private func say(_ text: String, duration: TimeInterval = 2.2, voice: Bool = true) {
        view.bubbleText = text
        bubbleClearTimer?.invalidate()
        bubbleClearTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.view.bubbleText = nil
        }
        if voice {
            audio.speak(text, catty: true)
        }
    }

    // MARK: - Status

    private func setStatus(_ mode: StatusMode) {
        statusMode = mode
        refreshPanel()
        // menubar emoji
        let emoji: String
        switch mode {
        case .idle:     emoji = "✦"
        case .thinking: emoji = "✦…"
        case .running:  emoji = "✦⚙"
        case .review:   emoji = "✦!"
        case .done:     emoji = "✦✓"
        case .sleeping: emoji = "✦💤"
        case .limit:    emoji = "✦⊘"
        }
        menuBar.setStatusEmoji(emoji)
    }

    private func refreshPanel() {
        menuBar.panel.render(state: state, status: statusMode)
    }

    // MARK: - Behaviors

    func wave() {
        if view.pose == .sleep { say("zzz… 不要吵我"); return }
        lastInteract = Date()
        let greetings = ["nya~ ♡", "喵!", "看到你了 (>ᴗ•)", "hi hi", "*开心地踩奶*", "mrrrp!"]
        say(greetings.randomElement()!)
        view.pose = .wave
        view.emit(.sparkle, count: 4, speed: 30, life: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            guard let self = self else { return }
            if self.view.pose == .wave { self.view.pose = .idle }
        }
    }

    func pet() {
        if view.pose == .sleep {
            // gentle wake — affection
            view.pose = .idle
            setStatus(.idle)
        }
        lastInteract = Date()
        state.mood.pet()
        view.emit(.heart, count: 5, speed: 35, life: 1.2)
        let bubbles = ["♡", "purr…", "好舒服~", "mrrr ♡", "*眯眼*"]
        say(bubbles.randomElement()!, duration: 1.6)
        refreshPanel()
    }

    func feed() {
        if view.pose == .sleep { say("zzz… 待会再吃"); return }
        lastInteract = Date()
        let wasFull = state.mood.hunger > 80
        state.mood.feed()
        view.pose = .eat
        if wasFull {
            say("已经很饱了…谢谢", duration: 1.8)
            view.emit(.heart, count: 2, life: 1.0)
        } else {
            let lines = ["嗯！好吃 ✦", "*开心咀嚼*", "om nom nom", "谢谢你 ♡"]
            say(lines.randomElement()!, duration: 2.0)
            view.emit(.crumb, count: 5, speed: 25, life: 1.0)
            view.emit(.heart, count: 2, life: 1.4)
        }
        // eat animation lasts ~2.4s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { [weak self] in
            if self?.view.pose == .eat { self?.view.pose = .idle }
        }
        refreshPanel()
    }

    func playWith() {
        if view.pose == .sleep { say("zzz… 起不来"); return }
        if state.mood.energy < 15 { say("太累了…改天吧 (｡-_-｡)"); return }
        lastInteract = Date()
        state.mood.play()
        view.pose = .play
        let lines = ["*扑!*", "mrr! 抓住啦", "再来再来", "嘿嘿~"]
        say(lines.randomElement()!, duration: 2.0)
        view.emit(.star, count: 5, life: 1.2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.view.emit(.sparkle, count: 4, life: 1.0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) { [weak self] in
            if self?.view.pose == .play { self?.view.pose = .idle }
        }
        refreshPanel()
    }

    func sleep() {
        if view.pose == .sleep { say("已经在睡了… zzz"); return }
        view.pose = .sleep
        say("\(state.name) 蜷起来了 💤", duration: 2.4)
        setStatus(.sleeping)
    }

    func wake() {
        if view.pose != .sleep { return }
        view.pose = .idle
        say("呼啊~ *伸懒腰*")
        setStatus(.idle)
    }

    func runTask(prompt: String? = nil) {
        if statusMode.isBusy { say("正在忙呢…"); return }
        let limit = state.model.windowLimit
        if state.windowCount >= limit {
            setStatus(.limit)
            say("5小时上限到了，等会儿吧 (>_<)", duration: 2.8)
            return
        }
        if view.pose == .sleep { view.pose = .idle }
        lastInteract = Date()

        // Bump usage
        let beforePct = Double(state.windowCount) / Double(limit)
        state.windowCount += 1
        state.totalMsgs += 1
        if state.model == .opus {
            state.opusUsedMin += Double.random(in: 3...7)
        }
        let afterPct = Double(state.windowCount) / Double(limit)
        refreshPanel()
        if beforePct < 0.7 && afterPct >= 0.7 { say("用量过半啦…⚠", duration: 2.4) }
        else if beforePct < 0.9 && afterPct >= 0.9 { say("快到上限了！", duration: 2.4) }

        // Workflow
        view.pose = .work
        setStatus(.thinking)
        let preview: String
        if let p = prompt {
            let trimmed = p.count > 14 ? String(p.prefix(14)) + "…" : p
            preview = "让我想想：「\(trimmed)」"
        } else {
            preview = "让我想想…"
        }
        say(preview, duration: 2.0)

        let think = state.model.thinkSeconds
        cancelTaskTimers()
        scheduleTask(after: think) { [weak self] in
            self?.setStatus(.running)
            self?.say("drafting…")
            self?.scheduleTask(after: 2.4) {
                self?.setStatus(.review)
                self?.say("写好啦~ 看看？")
                self?.scheduleTask(after: 2.4) {
                    self?.setStatus(.done)
                    self?.view.pose = .idle
                    self?.wave()
                    self?.scheduleTask(after: 2.6) {
                        self?.setStatus(.idle)
                    }
                }
            }
        }
    }

    private func scheduleTask(after delay: TimeInterval, _ block: @escaping () -> Void) {
        let t = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in block() }
        taskTimers.append(t)
    }
    private func cancelTaskTimers() {
        taskTimers.forEach { $0.invalidate() }
        taskTimers.removeAll()
    }

    // MARK: - Idle behavior (mood-aware)

    private func maybeChatter() {
        guard view.pose != .sleep, !statusMode.isBusy else { return }
        // Mood needs override generic chatter when strong
        let need = state.mood.dominantNeed
        let urgency: Double
        switch need {
        case .hungry, .tired, .lonely: urgency = 0.65
        case .joyful: urgency = 0.55
        case .content: urgency = 0.35
        }
        if Double.random(in: 0..<1) < urgency {
            // Most chatter pulls from the dominant need
            if Double.random(in: 0..<1) < 0.75 {
                say(need.idleBubble, duration: 1.8)
                if need == .joyful { view.emit(.note, count: 2, life: 1.2) }
                if need == .hungry { view.emit(.dust, count: 2, life: 1.0) }
            } else if let ambient = DayPhase.current().ambientComment {
                say(ambient, duration: 2.0)
            }
        }
    }

    /// Checks for actions that the pet does autonomously based on mood.
    private func checkMoodActions() {
        guard view.pose == .idle, !statusMode.isBusy else { return }
        let m = state.mood
        // Very tired → go to sleep on its own
        if m.energy < 12 && Double.random(in: 0..<1) < 0.6 {
            sleep()
            return
        }
        // Joyful + bond enough → spontaneous purr/dance with emoji
        if m.dominantNeed == .joyful && Double.random(in: 0..<1) < 0.18 {
            view.emit(.heart, count: 3, life: 1.4)
        }
    }

    private func scheduleWalk() {
        let interval = Double.random(in: 12...22)
        walkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.maybeWalk()
            self?.scheduleWalk()
        }
    }
    private func maybeWalk() {
        guard view.pose != .sleep, !statusMode.isBusy else { return }
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let w = PetView.viewSize.width
        let h = PetView.viewSize.height
        let nx = CGFloat.random(in: visible.minX + 40 ... visible.maxX - w - 40)
        let ny = CGFloat.random(in: visible.minY + 40 ... visible.maxY - h - 40)
        let cur = window.frame.origin
        view.facingRight = nx >= cur.x
        window.animateOrigin(to: NSPoint(x: nx, y: ny), duration: 1.4)
    }

    private func checkIdleSleep() {
        if view.pose == .idle && !statusMode.isBusy {
            let idle = Date().timeIntervalSince(lastInteract)
            if idle > 90 && Double.random(in: 0..<1) < 0.5 {
                sleep()
            }
        }
    }

    // MARK: - Usage rollover

    private func tickUsage() {
        let now = Date()
        if now.timeIntervalSince(state.windowStart) >= PetState.windowDuration {
            state.windowStart = now
            state.windowCount = 0
            if view.pose != .sleep { say("窗口刷新了，可以继续了 ♡", duration: 2.4) }
            if statusMode == .limit { setStatus(.idle) }
        }
        let weekStart = PetState.weekStartTs()
        if weekStart > state.weekStart {
            state.weekStart = weekStart
            state.opusUsedMin = 0
        }
        refreshPanel()
    }

    // MARK: - Mood tick + milestones

    private func tickMood() {
        let isSleeping = view.pose == .sleep
        let isWorking = statusMode.isBusy
        state.mood.tick(now: Date(), isSleeping: isSleeping, isWorking: isWorking)
        refreshPanel()
    }

    private func checkMilestones() {
        let day = state.daysWithPet
        guard !state.shownMilestones.contains(day) else { return }
        if let msg = Milestone.message(for: day, name: state.name) {
            state.shownMilestones.append(day)
            say(msg, duration: 4.0)
            view.emit(.star, count: 8, speed: 50, life: 1.8)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.view.emit(.heart, count: 6, life: 2.0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.view.emit(.sparkle, count: 8, life: 1.6)
            }
            state.save()
        }
    }

    // MARK: - Rename modal

    private func openRename() {
        let alert = NSAlert()
        alert.messageText = "改个名字"
        alert.informativeText = "给你的小猫起个名字（最多 16 字符）"
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        input.stringValue = state.name
        alert.accessoryView = input
        let resp = alert.runModal()
        if resp == .alertFirstButtonReturn {
            let v = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !v.isEmpty {
                let old = state.name
                state.name = String(v.prefix(16))
                say("\(old) → \(state.name) ♡")
                state.save()
            }
        }
    }

    // MARK: - PetViewDelegate

    func petWasClicked() {
        lastInteract = Date()
        wave()
    }
    func petWasDoubleClicked() {
        pet()
    }
    func petWasRightClicked(with event: NSEvent, in view: NSView) {
        let menu = NSMenu()

        let petItem = NSMenuItem(title: "♡ 摸摸它", action: #selector(menuPet), keyEquivalent: "")
        petItem.target = self
        menu.addItem(petItem)

        let feedItem = NSMenuItem(title: "🐟 喂零食", action: #selector(menuFeed), keyEquivalent: "")
        feedItem.target = self
        menu.addItem(feedItem)

        let playItem = NSMenuItem(title: "🧶 陪它玩", action: #selector(menuPlay), keyEquivalent: "")
        playItem.target = self
        menu.addItem(playItem)

        menu.addItem(NSMenuItem.separator())

        let waveItem = NSMenuItem(title: "招手", action: #selector(menuWave), keyEquivalent: "")
        waveItem.target = self
        menu.addItem(waveItem)

        let sleepItem = NSMenuItem(
            title: self.view.pose == .sleep ? "叫醒" : "让它睡觉",
            action: #selector(menuSleep), keyEquivalent: "")
        sleepItem.target = self
        menu.addItem(sleepItem)

        let taskItem = NSMenuItem(title: "运行任务", action: #selector(menuTask), keyEquivalent: "")
        taskItem.target = self
        menu.addItem(taskItem)

        menu.addItem(NSMenuItem.separator())

        // Switch Skin submenu
        let skinItem = NSMenuItem(title: "切换皮肤", action: nil, keyEquivalent: "")
        let skinSubmenu = NSMenu()
        SkinManager.shared.reloadFromDisk()
        let activeID = SkinManager.shared.active.id
        for skin in SkinManager.shared.skins {
            let prefix = skin.isBuiltIn ? "" : "· "
            let item = NSMenuItem(title: "\(prefix)\(skin.displayName)",
                                  action: #selector(menuSwitchSkin(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.representedObject = skin.id
            if skin.id == activeID { item.state = .on }
            skinSubmenu.addItem(item)
        }
        skinSubmenu.addItem(NSMenuItem.separator())
        let openSkinDir = NSMenuItem(title: "打开社区皮肤文件夹…",
                                     action: #selector(menuOpenSkinFolder),
                                     keyEquivalent: "")
        openSkinDir.target = self
        skinSubmenu.addItem(openSkinDir)
        let browseCommunity = NSMenuItem(title: "浏览社区皮肤…",
                                         action: #selector(menuBrowseCommunitySkins),
                                         keyEquivalent: "")
        browseCommunity.target = self
        skinSubmenu.addItem(browseCommunity)
        skinItem.submenu = skinSubmenu
        menu.addItem(skinItem)

        let renameItem = NSMenuItem(title: "改名…", action: #selector(menuRename), keyEquivalent: "")
        renameItem.target = self
        menu.addItem(renameItem)

        let centerItem = NSMenuItem(title: "居中", action: #selector(menuCenter), keyEquivalent: "")
        centerItem.target = self
        menu.addItem(centerItem)

        // Global hot keys toggle
        let hotkeyItem = NSMenuItem(
            title: "全局热键 (⌃⌥⌘P 召唤 / ⌃⌥H 收起 / ⌃⌥F 喂)",
            action: #selector(menuToggleHotKeys),
            keyEquivalent: "")
        hotkeyItem.target = self
        hotkeyItem.state = state.hotkeysEnabled ? .on : .off
        menu.addItem(hotkeyItem)

        // Launch at login toggle
        let loginItem = NSMenuItem(
            title: "开机自启",
            action: #selector(menuToggleLaunchAtLogin),
            keyEquivalent: "")
        loginItem.target = self
        loginItem.state = state.launchAtLogin ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem.separator())

        let resetItem = NSMenuItem(title: "重置位置", action: #selector(menuReset), keyEquivalent: "")
        resetItem.target = self
        menu.addItem(resetItem)

        let quitItem = NSMenuItem(title: "退出", action: #selector(menuQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        NSMenu.popUpContextMenu(menu, with: event, for: view)
    }
    func petWasDragged(toScreen origin: NSPoint) {
        lastInteract = Date()
        savePosition()
    }
    func petDragEnded() {
        state.save()
        say("啊咧?", duration: 1.0)
    }

    // MARK: - Menu actions

    @objc private func menuPet()  { pet() }
    @objc private func menuFeed() { feed() }
    @objc private func menuPlay() { playWith() }
    @objc private func menuWave() { wave() }
    @objc private func menuSleep() { if view.pose == .sleep { wake() } else { sleep() } }
    @objc private func menuTask() { runTask() }
    @objc private func menuRename() { openRename() }
    @objc private func menuCenter() {
        guard let s = NSScreen.main else { return }
        let f = s.visibleFrame
        let o = NSPoint(x: f.midX - PetView.viewSize.width/2,
                        y: f.midY - PetView.viewSize.height/2)
        window.animateOrigin(to: o, duration: 0.6)
        savePosition()
        say("就位 ฅ")
    }
    @objc private func menuReset() {
        // Position-only reset — keep mood, bond, and the days you've shared
        state.hasPlaced = false
        state.posX = 0; state.posY = 0
        placeInitial()
        savePosition()
        view.pose = .idle
        setStatus(.idle)
        view.emit(.sparkle, count: 4, life: 1.2)
        say("回到老地方 ♡")
        state.save()
        refreshPanel()
    }
    @objc private func menuQuit() {
        state.save()
        NSApp.terminate(nil)
    }

    @objc private func menuSwitchSkin(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        let active = SkinManager.shared.activate(id: id)
        state.skinId = active.id
        view.needsDisplay = true
        say("\(active.displayName) ✦", duration: 1.6)
        view.emit(.sparkle, count: 5, life: 1.2)
        state.save()
    }

    @objc private func menuOpenSkinFolder() {
        let dir = SkinManager.communityDir
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        NSWorkspace.shared.open(dir)
    }

    @objc private func menuBrowseCommunitySkins() {
        if let url = URL(string: "https://github.com/loeweErr/claude-pet-skins") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Hot keys

    private func handleHotKey(_ action: HotKeyManager.Action) {
        switch action {
        case .summon:
            let mouse = NSEvent.mouseLocation
            // mouseLocation is in screen coords (bottom-left origin),
            // PetWindow.setFrameOrigin uses the same convention.
            let size = PetView.viewSize
            let target = NSPoint(x: mouse.x - size.width / 2,
                                 y: mouse.y - size.height / 2)
            window.animateOrigin(to: target, duration: 0.35)
            savePosition()
            view.emit(.sparkle, count: 5, life: 1.0)
            say("到啦~ ฅ", duration: 1.4)
        case .toggle:
            if window.isVisible {
                window.orderOut(nil)
            } else {
                window.orderFrontRegardless()
            }
        case .feed:
            feed()
        }
    }

    @objc private func menuToggleHotKeys() {
        state.hotkeysEnabled.toggle()
        if state.hotkeysEnabled {
            hotKeys.enable()
            say("热键已启用", duration: 1.4)
        } else {
            hotKeys.disable()
            say("热键已禁用", duration: 1.4)
        }
        state.save()
    }

    // MARK: - Launch at login

    private func applyLaunchAtLogin() {
        if state.launchAtLogin {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }

    @objc private func menuToggleLaunchAtLogin() {
        let willEnable = !state.launchAtLogin
        do {
            if willEnable {
                try SMAppService.mainApp.register()
                state.launchAtLogin = true
                // First-enable explanation (the menu item is the only entry
                // point, so the first toggle on each install is "first time").
                say("这样早上开机就能看到我啦 ฅ^•ﻌ•^ฅ", duration: 3.0)
                view.emit(.heart, count: 4, life: 1.4)
            } else {
                try SMAppService.mainApp.unregister()
                state.launchAtLogin = false
                say("不再开机自启 zzz", duration: 1.6)
            }
            state.save()
        } catch {
            say("开机自启切换失败 (>_<)", duration: 2.0)
            FileHandle.standardError.write(Data(
                "[launch] \(willEnable ? "register" : "unregister") failed: \(error)\n".utf8
            ))
        }
    }

    // MARK: - StatusPanelDelegate

    func statusPanelDidChangeModel(_ model: ClaudeModel) {
        state.model = model
        say("切到 \(model.label)", duration: 1.8)
        state.save()
        refreshPanel()
    }
    func statusPanelDidSubmit(prompt: String) { runTask(prompt: prompt) }
    func statusPanelDidRequestWave()   { wave() }
    func statusPanelDidRequestSleep()  { view.pose == .sleep ? wake() : sleep() }
    func statusPanelDidRequestRename() { openRename() }
    func statusPanelDidRequestQuit()   { state.save(); NSApp.terminate(nil) }
    func statusPanelDidRequestPet()    { pet() }
    func statusPanelDidRequestFeed()   { feed() }
    func statusPanelDidRequestPlay()   { playWith() }

    // MARK: - IPCRequestHandler (called from background thread; dispatch to main)

    func handleIPC(method: String, params: [String: Any]) -> String {
        switch method {
        case "pet_status":
            return statusReport()
        case "pet_say":
            let text = (params["text"] as? String) ?? ""
            let duration = (params["duration"] as? Double) ?? 3.0
            let silent = (params["silent"] as? Bool) ?? false
            guard !text.isEmpty else { return "error: missing 'text'" }
            say(text, duration: duration, voice: !silent)
            return "OK · \(state.name) is saying: \(text)\(silent ? " (silent)" : "")"
        case "pet_meow":
            let text = (params["text"] as? String) ?? ""
            if text.isEmpty {
                audio.meow()
                view.emit(.note, count: 2, life: 1.0)
                return "OK · \(state.name) meowed"
            } else {
                say(text, duration: 3.0, voice: true)
                return "OK · \(state.name) meowed: \(text)"
            }
        case "pet_feed":
            feed()
            return "OK · fed \(state.name). hunger=\(Int(state.mood.hunger))/100"
        case "pet_pet":
            pet()
            return "OK · petted \(state.name). happiness=\(Int(state.mood.happiness))/100 bond=\(Int(state.mood.bond))"
        case "pet_play":
            playWith()
            return "OK · played with \(state.name). happiness=\(Int(state.mood.happiness))/100 energy=\(Int(state.mood.energy))"
        case "pet_wave":
            wave()
            return "OK · \(state.name) waved at you"
        case "pet_sleep":
            sleep()
            return "OK · \(state.name) went to sleep"
        case "pet_wake":
            wake()
            return "OK · \(state.name) is awake"
        case "pet_emote":
            let kindStr = (params["kind"] as? String) ?? "sparkle"
            let count = (params["count"] as? Int) ?? 5
            guard let kind = particleKind(from: kindStr) else {
                return "error: unknown kind '\(kindStr)' (valid: heart, sparkle, star, crumb, dust, note)"
            }
            view.emit(kind, count: min(20, max(1, count)), life: 1.4)
            return "OK · emitted \(count)x \(kindStr)"
        default:
            return "error: unknown method '\(method)'"
        }
    }

    private func statusReport() -> String {
        let m = state.mood
        let lvl = m.bondLevel
        let need: String
        switch m.dominantNeed {
        case .hungry: need = "hungry"
        case .tired:  need = "tired"
        case .lonely: need = "lonely"
        case .content:need = "content"
        case .joyful: need = "joyful"
        }
        return """
        name: \(state.name)
        day: \(state.daysWithPet)
        bond: \(lvl.rawValue) (\(Int(m.bond))/100)
        hunger: \(Int(m.hunger))/100
        happiness: \(Int(m.happiness))/100
        energy: \(Int(m.energy))/100
        dominant_need: \(need)
        pose: \(poseName(view.pose))
        status: \(statusMode.label)
        pets: \(m.totalPets) · treats: \(m.totalTreats) · plays: \(m.totalPlays)
        """
    }

    private func particleKind(from s: String) -> ParticleKind? {
        switch s.lowercased() {
        case "heart":   return .heart
        case "sparkle": return .sparkle
        case "star":    return .star
        case "crumb":   return .crumb
        case "dust":    return .dust
        case "note":    return .note
        default:        return nil
        }
    }

    private func poseName(_ p: CatPose) -> String {
        switch p {
        case .idle:  return "idle"
        case .work:  return "work"
        case .sleep: return "sleep"
        case .wave:  return "wave"
        case .eat:   return "eat"
        case .play:  return "play"
        }
    }
}
