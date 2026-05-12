import AppKit

// --- Dispatch on mode ---
let args = ProcessInfo.processInfo.arguments
if args.contains("--mcp") {
    // stdio MCP server bridging Claude Desktop to the running GUI process.
    // No AppKit. Exits when stdin closes.
    MCPServer().run()
    exit(0)
}

// --- GUI mode (default) ---

final class AppDelegate: NSObject, NSApplicationDelegate {
    var coordinator: PetCoordinator!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let state = PetState.load()
        coordinator = PetCoordinator(state: state)
        coordinator.showWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator?.state.save()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // menubar-only, no dock icon
app.run()
