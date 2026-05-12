import AppKit

protocol PetViewDelegate: AnyObject {
    func petWasClicked()
    func petWasDoubleClicked()
    func petWasRightClicked(with event: NSEvent, in view: NSView)
    func petWasDragged(toScreen origin: NSPoint)
    func petDragEnded()
}

/// The cat sprite view. Sized so the cat sits at the bottom-center,
/// with room above for a speech bubble.
final class PetView: NSView {

    // ===== Layout constants =====
    /// total view size — also the window size
    static let viewSize = NSSize(width: 160, height: 220)
    /// cat sprite frame inside the view (viewBox is 64×80 scaled by 1.5)
    private let catFrame = NSRect(x: 32, y: 60, width: 96, height: 120)

    weak var delegate: PetViewDelegate?

    // ===== Public state =====
    var pose: CatPose = .idle {
        didSet { needsDisplay = true }
    }
    var bubbleText: String? {
        didSet { needsDisplay = true }
    }
    /// Facing direction (true = facing right). When false, sprite is flipped horizontally.
    var facingRight: Bool = true {
        didSet { needsDisplay = true }
    }

    // ===== Animation state =====
    private var bobPhase: CGFloat = 0
    private var gearAngle: CGFloat = 0
    private var waveAngle: CGFloat = -10
    private var waveDirection: CGFloat = 1
    private var blinkActive = false
    private var animTimer: Timer?
    private var blinkTimer: Timer?

    // ===== Particles =====
    let particles = ParticleSystem()
    private var lastTickTime: Date = Date()

    /// Emit a burst of particles centered on the cat's head/body.
    func emit(_ kind: ParticleKind, count: Int = 6,
              offset: NSPoint = .zero, speed: CGFloat = 40,
              life: TimeInterval = 1.4) {
        // Default origin: just above the cat's head
        let origin = NSPoint(x: catFrame.midX + offset.x,
                             y: catFrame.minY + 30 + offset.y)
        particles.emit(kind: kind, at: origin, count: count, speed: speed, life: life)
        needsDisplay = true
    }

    // ===== Drag state =====
    private var dragStartScreen: NSPoint?
    private var dragStartWindowOrigin: NSPoint?
    private var dragMoved = false
    private var pendingClickWork: DispatchWorkItem?

    override var isFlipped: Bool { true }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        startAnimation()
        scheduleBlink()
    }
    required init?(coder: NSCoder) { fatalError() }

    deinit {
        animTimer?.invalidate()
        blinkTimer?.invalidate()
    }

    // ===== Animation loop (≈30fps) =====
    private func startAnimation() {
        animTimer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = Date()
            let dt = now.timeIntervalSince(self.lastTickTime)
            self.lastTickTime = now
            self.bobPhase += 0.07
            self.gearAngle = (self.gearAngle + 8).truncatingRemainder(dividingBy: 360)
            // wave bobs between -10 and 15 degrees
            self.waveAngle += self.waveDirection * 4
            if self.waveAngle > 15 { self.waveAngle = 15; self.waveDirection = -1 }
            if self.waveAngle < -10 { self.waveAngle = -10; self.waveDirection = 1 }
            self.particles.update(dt: dt)
            self.needsDisplay = true
        }
    }

    private func scheduleBlink() {
        let delay = Double.random(in: 2.5...6.0)
        blinkTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self, self.pose == .idle else {
                self?.scheduleBlink(); return
            }
            self.blinkActive = true
            self.needsDisplay = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                self.blinkActive = false
                self.needsDisplay = true
                self.scheduleBlink()
            }
        }
    }

    // ===== Drawing =====
    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)

        // bob offset (vertical sin)
        let bob = sin(bobPhase) * 3

        // ----- Cat -----
        ctx.saveGState()
        // Place cat
        ctx.translateBy(x: catFrame.minX, y: catFrame.minY)
        // Mirror horizontally if facing left
        if !facingRight {
            ctx.translateBy(x: catFrame.width, y: 0)
            ctx.scaleBy(x: -1, y: 1)
        }
        // Bob (only in idle / wave / work, not sleep)
        let bobY: CGFloat = (pose == .sleep) ? 0 : bob
        // Shadow
        drawShadow(ctx, scale: catFrame.width / 64)

        let scale = catFrame.width / 64
        CatRenderer.draw(pose: pose,
                         ctx: ctx,
                         scale: scale,
                         blink: blinkActive,
                         gearAngle: gearAngle,
                         waveAngle: waveAngle,
                         bobOffset: bobY)
        ctx.restoreGState()

        // ----- Particles (above cat, under bubble) -----
        particles.draw(in: ctx)

        // ----- Speech bubble -----
        if let text = bubbleText, !text.isEmpty {
            drawBubble(ctx, text: text)
        }
    }

    private func drawShadow(_ ctx: CGContext, scale: CGFloat) {
        // soft ellipse shadow at cat's feet
        ctx.saveGState()
        ctx.setFillColor(NSColor.black.withAlphaComponent(0.25).cgColor)
        let shadowRect = CGRect(x: 8 * scale,
                                y: 74 * scale,
                                width: 48 * scale,
                                height: 6 * scale)
        ctx.fillEllipse(in: shadowRect)
        ctx.restoreGState()
    }

    private func drawBubble(_ ctx: CGContext, text: String) {
        let font = NSFont(name: "Menlo", size: 12) ??
                   NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(red: 0.10, green: 0.08, blue: 0.22, alpha: 1)
        ]
        let attrString = NSAttributedString(string: text, attributes: attrs)
        let textSize = attrString.size()
        let padX: CGFloat = 12, padY: CGFloat = 7
        let bubbleSize = NSSize(width: ceil(textSize.width) + padX * 2,
                                height: ceil(textSize.height) + padY * 2)

        // Place bubble centered above the cat
        let cx = catFrame.midX
        let by = catFrame.minY - bubbleSize.height - 8
        let bubbleRect = NSRect(x: cx - bubbleSize.width / 2,
                                y: max(4, by),
                                width: bubbleSize.width,
                                height: bubbleSize.height)

        // Shadow under bubble
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: 3),
                      blur: 8,
                      color: NSColor.black.withAlphaComponent(0.25).cgColor)
        let path = CGPath(roundedRect: bubbleRect, cornerWidth: 12, cornerHeight: 12, transform: nil)
        ctx.addPath(path)
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fillPath()
        ctx.restoreGState()

        // Tail of bubble
        ctx.beginPath()
        ctx.move(to: NSPoint(x: cx - 6, y: bubbleRect.maxY))
        ctx.addLine(to: NSPoint(x: cx + 6, y: bubbleRect.maxY))
        ctx.addLine(to: NSPoint(x: cx,     y: bubbleRect.maxY + 6))
        ctx.closePath()
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fillPath()

        // Text — draw with NSGraphicsContext for proper attributed string
        let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: true)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsCtx
        attrString.draw(at: NSPoint(x: bubbleRect.minX + padX,
                                    y: bubbleRect.minY + padY))
        NSGraphicsContext.restoreGraphicsState()
    }

    // ===== Hit testing — only inside cat bounds are interactive =====
    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        if catFrame.insetBy(dx: -4, dy: -4).contains(local) { return self }
        return nil
    }

    // ===== Mouse interaction =====
    override func mouseDown(with event: NSEvent) {
        dragStartScreen = NSEvent.mouseLocation
        dragStartWindowOrigin = window?.frame.origin
        dragMoved = false
    }
    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStartScreen,
              let origin = dragStartWindowOrigin else { return }
        let cur = NSEvent.mouseLocation
        let dx = cur.x - start.x
        let dy = cur.y - start.y
        if abs(dx) > 3 || abs(dy) > 3 { dragMoved = true }
        let newOrigin = NSPoint(x: origin.x + dx, y: origin.y + dy)
        window?.setFrameOrigin(newOrigin)
        delegate?.petWasDragged(toScreen: newOrigin)
    }
    override func mouseUp(with event: NSEvent) {
        if dragMoved {
            delegate?.petDragEnded()
            return
        }
        if event.clickCount >= 2 {
            pendingClickWork?.cancel()
            pendingClickWork = nil
            delegate?.petWasDoubleClicked()
        } else {
            let work = DispatchWorkItem { [weak self] in
                self?.delegate?.petWasClicked()
            }
            pendingClickWork = work
            DispatchQueue.main.asyncAfter(
                deadline: .now() + NSEvent.doubleClickInterval,
                execute: work
            )
        }
    }
    override func rightMouseDown(with event: NSEvent) {
        delegate?.petWasRightClicked(with: event, in: self)
    }
}
