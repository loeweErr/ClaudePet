import AppKit

/// Borderless, transparent, always-on-top window that hosts the cat sprite
/// and is visible on every Space.
final class PetWindow: NSWindow {

    init() {
        let size = PetView.viewSize
        let frame = NSRect(origin: .zero, size: size)
        super.init(contentRect: frame,
                   styleMask: [.borderless],
                   backing: .buffered,
                   defer: false)

        // Transparent and shadow-less; we draw our own
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false

        // Float above other apps
        self.level = .floating

        // Visible on every Space and across full-screen apps
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]

        // Don't show in Mission Control or app switcher
        self.isExcludedFromWindowsMenu = true

        // No window dragging on background (we handle it manually in the view)
        self.isMovableByWindowBackground = false

        // Allow window to be smaller than its content
        self.minSize = size
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    // Pass through to PetView for hit testing — already handled by transparent areas

    /// Animate the window's origin to a new screen position with easing.
    func animateOrigin(to newOrigin: NSPoint, duration: TimeInterval = 0.8) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.animator().setFrameOrigin(newOrigin)
        }
    }
}
