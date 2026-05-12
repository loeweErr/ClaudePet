import AppKit

final class MenuBarController {

    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    let panel = StatusPanelController()

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "✦"
            button.font = NSFont.systemFont(ofSize: 16, weight: .medium)
            button.toolTip = "Claude Pet"
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover.contentViewController = panel
        popover.behavior = .transient
        popover.animates = true
    }

    func setStatusEmoji(_ emoji: String) {
        statusItem.button?.title = emoji
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds,
                         of: sender,
                         preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
