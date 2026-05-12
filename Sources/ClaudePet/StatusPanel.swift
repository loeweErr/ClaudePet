import AppKit

protocol StatusPanelDelegate: AnyObject {
    func statusPanelDidChangeModel(_ model: ClaudeModel)
    func statusPanelDidSubmit(prompt: String)
    func statusPanelDidRequestWave()
    func statusPanelDidRequestSleep()
    func statusPanelDidRequestRename()
    func statusPanelDidRequestQuit()
    func statusPanelDidRequestPet()
    func statusPanelDidRequestFeed()
    func statusPanelDidRequestPlay()
}

final class StatusPanelController: NSViewController {

    weak var delegate: StatusPanelDelegate?

    private let planLabel = NSTextField(labelWithString: "PRO")
    private let modelPopup = NSPopUpButton()
    private let statusDot = NSView()
    private let statusLabel = NSTextField(labelWithString: "")
    private let statusText = NSTextField(labelWithString: "")
    private let statusDetail = NSTextField(labelWithString: "")
    private let winLabel = NSTextField(labelWithString: "")
    private let winBar = ProgressBar()
    private let winMeta = NSTextField(labelWithString: "")
    private let opusLabel = NSTextField(labelWithString: "")
    private let opusBar = ProgressBar()
    private let opusMeta = NSTextField(labelWithString: "")

    // Pet identity / mood
    private let petHeader = NSTextField(labelWithString: "")
    private let bondMeta = NSTextField(labelWithString: "")
    private let hungerLabel = NSTextField(labelWithString: "")
    private let hungerBar = ProgressBar()
    private let happyLabel = NSTextField(labelWithString: "")
    private let happyBar = ProgressBar()
    private let energyLabel = NSTextField(labelWithString: "")
    private let energyBar = ProgressBar()
    private let bondLabel = NSTextField(labelWithString: "")
    private let bondBar = ProgressBar()

    private let input = NSTextField()
    private let petBtn = NSButton(title: "♡ 摸摸", target: nil, action: nil)
    private let feedBtn = NSButton(title: "🐟 喂", target: nil, action: nil)
    private let playBtn = NSButton(title: "🧶 玩", target: nil, action: nil)
    private let waveBtn = NSButton(title: "👋 招手", target: nil, action: nil)
    private let sleepBtn = NSButton(title: "😴 睡觉", target: nil, action: nil)
    private let renameBtn = NSButton(title: "✎ 改名", target: nil, action: nil)
    private let quitBtn = NSButton(title: "退出", target: nil, action: nil)

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 380))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor(red: 0.10, green: 0.07, blue: 0.16, alpha: 0.95).cgColor

        // Plan badge styling
        planLabel.font = NSFont.systemFont(ofSize: 10, weight: .bold)
        planLabel.textColor = .white
        planLabel.drawsBackground = false
        planLabel.wantsLayer = true
        planLabel.layer?.masksToBounds = true
        planLabel.layer?.backgroundColor = NSColor(red: 0.85, green: 0.46, blue: 0.34, alpha: 1).cgColor
        planLabel.layer?.cornerRadius = 3
        planLabel.alignment = .center

        // Model popup
        for m in ClaudeModel.allCases {
            modelPopup.addItem(withTitle: "✦ " + m.label)
            modelPopup.lastItem?.representedObject = m
        }
        modelPopup.target = self
        modelPopup.action = #selector(modelChanged(_:))

        // Status dot
        statusDot.wantsLayer = true
        statusDot.layer?.cornerRadius = 4

        // Labels
        styleHeader(statusLabel)
        styleBody(statusText)
        styleMono(statusDetail)
        styleHeader(winLabel)
        styleMono(winMeta)
        styleHeader(opusLabel)
        styleMono(opusMeta)

        // Pet header (big name + day count)
        petHeader.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        petHeader.textColor = .white
        styleMono(bondMeta)

        styleHeader(hungerLabel)
        styleHeader(happyLabel)
        styleHeader(energyLabel)
        styleHeader(bondLabel)

        for bar in [hungerBar, happyBar, energyBar, bondBar] {
            bar.mode = .mood
        }

        // Input
        input.placeholderString = "试试发条消息给 Claude…"
        input.font = NSFont.systemFont(ofSize: 12)
        input.target = self
        input.action = #selector(submitInput)
        input.bezelStyle = .roundedBezel

        // Buttons
        for b in [petBtn, feedBtn, playBtn, waveBtn, sleepBtn, renameBtn, quitBtn] {
            b.bezelStyle = .rounded
            b.controlSize = .small
            b.target = self
        }
        petBtn.action   = #selector(tappedPet)
        feedBtn.action  = #selector(tappedFeed)
        playBtn.action  = #selector(tappedPlay)
        waveBtn.action  = #selector(tappedWave)
        sleepBtn.action = #selector(tappedSleep)
        renameBtn.action = #selector(tappedRename)
        quitBtn.action  = #selector(tappedQuit)

        // ===== Layout =====
        let top = NSStackView(views: [planLabel, modelPopup])
        top.orientation = .horizontal
        top.spacing = 8
        top.alignment = .centerY
        planLabel.widthAnchor.constraint(equalToConstant: 44).isActive = true
        planLabel.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let statusRow = NSStackView(views: [statusDot, statusLabel])
        statusRow.orientation = .horizontal
        statusRow.spacing = 8
        statusRow.alignment = .centerY
        statusDot.widthAnchor.constraint(equalToConstant: 8).isActive = true
        statusDot.heightAnchor.constraint(equalToConstant: 8).isActive = true

        // Pet identity row
        let petHeaderRow = NSStackView(views: [petHeader])
        petHeaderRow.orientation = .horizontal

        // 4 mood rows: short label + bar (compact)
        let moodGrid = NSStackView(views: [
            makeMoodRow(hungerLabel, hungerBar),
            makeMoodRow(happyLabel,  happyBar),
            makeMoodRow(energyLabel, energyBar),
            makeMoodRow(bondLabel,   bondBar),
        ])
        moodGrid.orientation = .vertical
        moodGrid.alignment = .leading
        moodGrid.spacing = 4

        let winRow = NSStackView(views: [makeBlock(winLabel, winBar, winMeta)])
        let opusRow = NSStackView(views: [makeBlock(opusLabel, opusBar, opusMeta)])

        let careRow = NSStackView(views: [petBtn, feedBtn, playBtn])
        careRow.distribution = .fillEqually
        careRow.spacing = 6
        let btnRow1 = NSStackView(views: [waveBtn, sleepBtn])
        btnRow1.distribution = .fillEqually
        btnRow1.spacing = 6
        let btnRow2 = NSStackView(views: [renameBtn, quitBtn])
        btnRow2.distribution = .fillEqually
        btnRow2.spacing = 6

        let v = NSStackView(views: [
            top,
            divider(),
            petHeaderRow, bondMeta,
            moodGrid,
            divider(),
            statusRow, statusText, statusDetail,
            divider(),
            winRow,
            opusRow,
            divider(),
            input,
            careRow,
            btnRow1, btnRow2,
        ])
        v.orientation = .vertical
        v.alignment = .leading
        v.spacing = 8
        v.edgeInsets = NSEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        v.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(v)
        NSLayoutConstraint.activate([
            v.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            v.topAnchor.constraint(equalTo: container.topAnchor),
            v.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            input.widthAnchor.constraint(equalToConstant: 268),
        ])

        preferredContentSize = NSSize(width: 300, height: 580)

        view = container
    }

    private func styleHeader(_ t: NSTextField) {
        t.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        t.textColor = NSColor.white.withAlphaComponent(0.55)
        t.maximumNumberOfLines = 1
    }
    private func styleBody(_ t: NSTextField) {
        t.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        t.textColor = .white
    }
    private func styleMono(_ t: NSTextField) {
        t.font = NSFont(name: "Menlo", size: 11) ?? NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        t.textColor = NSColor.white.withAlphaComponent(0.55)
    }
    private func divider() -> NSView {
        let d = NSView()
        d.wantsLayer = true
        d.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.08).cgColor
        d.heightAnchor.constraint(equalToConstant: 1).isActive = true
        d.widthAnchor.constraint(equalToConstant: 268).isActive = true
        return d
    }
    private func makeBlock(_ label: NSTextField, _ bar: ProgressBar, _ meta: NSTextField) -> NSView {
        let s = NSStackView(views: [label, bar, meta])
        s.orientation = .vertical
        s.alignment = .leading
        s.spacing = 3
        bar.heightAnchor.constraint(equalToConstant: 5).isActive = true
        bar.widthAnchor.constraint(equalToConstant: 268).isActive = true
        return s
    }
    private func makeMoodRow(_ label: NSTextField, _ bar: ProgressBar) -> NSView {
        let s = NSStackView(views: [label, bar])
        s.orientation = .horizontal
        s.alignment = .centerY
        s.spacing = 8
        label.widthAnchor.constraint(equalToConstant: 80).isActive = true
        bar.heightAnchor.constraint(equalToConstant: 6).isActive = true
        bar.widthAnchor.constraint(equalToConstant: 180).isActive = true
        return s
    }

    // ===== Public render =====
    func render(state: PetState, status: StatusMode) {
        planLabel.stringValue = state.plan.uppercased()

        // model popup
        for (i, item) in modelPopup.itemArray.enumerated() {
            if (item.representedObject as? ClaudeModel) == state.model {
                modelPopup.selectItem(at: i)
            }
        }

        let dotColor: NSColor
        switch status {
        case .idle, .sleeping, .limit:
            dotColor = NSColor.gray
        case .review, .done:
            dotColor = NSColor(red: 0.85, green: 0.46, blue: 0.34, alpha: 1)
        case .thinking, .running:
            dotColor = NSColor(red: 0.98, green: 0.74, blue: 0.14, alpha: 1)
        }
        statusDot.layer?.backgroundColor = dotColor.cgColor
        statusLabel.stringValue = status.label.uppercased()
        statusText.stringValue = status.headline
        statusDetail.stringValue = status.detail

        let limit = state.model.windowLimit
        winLabel.stringValue = "5-HOUR MESSAGES        \(state.windowCount) / \(limit)"
        let winPct = min(1.0, Double(state.windowCount) / Double(limit))
        winBar.percent = winPct
        let remain = PetState.windowDuration - Date().timeIntervalSince(state.windowStart)
        winMeta.stringValue = "resets in " + fmtDuration(max(0, remain))

        let opusPct = min(1.0, state.opusUsedMin / PetState.opusWeeklyBudget)
        opusLabel.stringValue = "WEEKLY OPUS            \(Int(opusPct * 100))%"
        opusBar.percent = opusPct
        let weekRemain = PetState.weekDuration - Date().timeIntervalSince(state.weekStart)
        opusMeta.stringValue = "resets " + fmtWeekReset(weekRemain)

        // ===== Pet identity + mood =====
        let bondLvl = state.mood.bondLevel
        petHeader.stringValue = "\(state.name)  ·  day \(state.daysWithPet)"
        bondMeta.stringValue = "羁绊：\(bondLvl.emoji) \(bondLvl.rawValue)   pets \(state.mood.totalPets) · treats \(state.mood.totalTreats) · plays \(state.mood.totalPlays)"

        let m = state.mood
        hungerLabel.stringValue = "🍣 饥饱   \(Int(m.hunger))"
        hungerBar.percent = m.hunger / 100
        happyLabel.stringValue = "😊 心情   \(Int(m.happiness))"
        happyBar.percent = m.happiness / 100
        energyLabel.stringValue = "⚡ 精力   \(Int(m.energy))"
        energyBar.percent = m.energy / 100
        bondLabel.stringValue = "♡ 羁绊    \(Int(m.bond))"
        bondBar.percent = m.bond / 100
    }

    private func fmtDuration(_ s: TimeInterval) -> String {
        let h = Int(s) / 3600
        let m = (Int(s) % 3600) / 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        return "\(m)m"
    }
    private func fmtWeekReset(_ s: TimeInterval) -> String {
        let d = Date().addingTimeInterval(s)
        let df = DateFormatter()
        df.dateFormat = "EEE HH:mm"
        return df.string(from: d)
    }

    // ===== Actions =====
    @objc private func modelChanged(_ sender: NSPopUpButton) {
        if let m = sender.selectedItem?.representedObject as? ClaudeModel {
            delegate?.statusPanelDidChangeModel(m)
        }
    }
    @objc private func submitInput() {
        let v = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !v.isEmpty {
            delegate?.statusPanelDidSubmit(prompt: v)
            input.stringValue = ""
        }
    }
    @objc private func tappedPet()   { delegate?.statusPanelDidRequestPet() }
    @objc private func tappedFeed()  { delegate?.statusPanelDidRequestFeed() }
    @objc private func tappedPlay()  { delegate?.statusPanelDidRequestPlay() }
    @objc private func tappedWave() { delegate?.statusPanelDidRequestWave() }
    @objc private func tappedSleep() { delegate?.statusPanelDidRequestSleep() }
    @objc private func tappedRename() { delegate?.statusPanelDidRequestRename() }
    @objc private func tappedQuit() { delegate?.statusPanelDidRequestQuit() }
}

// MARK: - Simple progress bar

final class ProgressBar: NSView {
    enum Mode {
        /// Usage bars: more is worse. Red at high %.
        case usage
        /// Mood bars: more is better. Red at low %.
        case mood
    }
    var mode: Mode = .usage { didSet { needsDisplay = true } }
    var percent: Double = 0 { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let bg = CGPath(roundedRect: bounds, cornerWidth: 2.5, cornerHeight: 2.5, transform: nil)
        ctx.addPath(bg)
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.08).cgColor)
        ctx.fillPath()

        let fillWidth = bounds.width * CGFloat(min(1.0, max(0.0, percent)))
        guard fillWidth > 0 else { return }
        let fillRect = NSRect(x: 0, y: 0, width: fillWidth, height: bounds.height)
        let fillPath = CGPath(roundedRect: fillRect, cornerWidth: 2.5, cornerHeight: 2.5, transform: nil)

        let red    = NSColor(red: 0.92, green: 0.27, blue: 0.27, alpha: 1)
        let orange = NSColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1)
        let coral  = NSColor(red: 0.85, green: 0.46, blue: 0.34, alpha: 1)
        let teal   = NSColor(red: 0.30, green: 0.78, blue: 0.62, alpha: 1)
        let mint   = NSColor(red: 0.55, green: 0.85, blue: 0.50, alpha: 1)

        let color: NSColor
        switch mode {
        case .usage:
            if percent >= 0.9 { color = red }
            else if percent >= 0.7 { color = orange }
            else { color = coral }
        case .mood:
            if percent <= 0.2 { color = red }
            else if percent <= 0.4 { color = orange }
            else if percent <= 0.7 { color = mint }
            else { color = teal }
        }
        ctx.addPath(fillPath)
        ctx.setFillColor(color.cgColor)
        ctx.fillPath()
    }
}
