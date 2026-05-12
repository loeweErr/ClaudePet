import Foundation
import Darwin

/// Implements just enough of the Model Context Protocol (stdio + JSON-RPC 2.0)
/// to expose pet tools to Claude Desktop. Bridges each `tools/call` over the
/// Unix domain socket to the running GUI process.
final class MCPServer {

    private var nextIPCID: Int = 1

    func run() {
        ensurePetRunning()
        while let line = readLine(strippingNewline: true) {
            guard !line.isEmpty, let data = line.data(using: .utf8) else { continue }
            handleLine(data)
        }
    }

    // MARK: - Pet launching

    private func ensurePetRunning() {
        if isSocketAlive() { return }

        // Walk up from our executable path:
        //   .../ClaudePet.app/Contents/MacOS/ClaudePet
        // → .../ClaudePet.app
        let exe = ProcessInfo.processInfo.arguments[0]
        let url = URL(fileURLWithPath: exe)
            .deletingLastPathComponent()  // MacOS
            .deletingLastPathComponent()  // Contents
            .deletingLastPathComponent()  // .app

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-a", url.path]
        do {
            try task.run()
        } catch {
            FileHandle.standardError.write(Data("[mcp] failed to launch pet: \(error)\n".utf8))
            return
        }

        // Wait up to 8 seconds for the socket to come up
        for _ in 0..<80 {
            if isSocketAlive() { return }
            Thread.sleep(forTimeInterval: 0.1)
        }
    }

    private func isSocketAlive() -> Bool {
        guard FileManager.default.fileExists(atPath: IPC.socketPath) else { return false }
        let fd = connectToSocket()
        if fd >= 0 { close(fd); return true }
        return false
    }

    // MARK: - JSON-RPC handling

    private func handleLine(_ data: Data) {
        guard let req = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        let method = (req["method"] as? String) ?? ""
        let id = req["id"]
        let params = (req["params"] as? [String: Any]) ?? [:]

        // Notifications (no id) → no response
        let isNotification = id == nil

        switch method {
        case "initialize":
            if !isNotification {
                send(id: id, result: [
                    "protocolVersion": "2024-11-05",
                    "capabilities": ["tools": [String: Any]()],
                    "serverInfo": ["name": "claude-pet", "version": "0.3.0"],
                    "instructions": """
                    These tools control a virtual pixel-art cat pet that lives on the user's macOS \
                    desktop (a small animated cat overlaid on the screen, with mood, hunger, energy, \
                    and bond stats). The pet's default name is 'mochi' but the user may have renamed it.

                    When the user mentions:
                      - their pet, cat, kitty, kitten, 小猫, 猫, 宠物, mochi/Mochi/モチ, or any \
                        renamed identifier of the cat
                      - feeding, petting, stroking, playing with, waving at, or putting the pet \
                        to sleep
                      - the pet's mood, hunger, energy, happiness, bond, or how it's "doing"

                    you should use the appropriate `pet_*` tool. Call `pet_status` first if you \
                    need context about the current state. Use `pet_say` to relay short messages \
                    to the user through the cat's speech bubble. Use `pet_emote` to express \
                    emotion via particle effects.

                    Do NOT use these tools for unrelated topics (e.g. mochi the Japanese rice cake).
                    """,
                ])
            }

        case "notifications/initialized":
            return  // ack only, no response

        case "tools/list":
            if !isNotification {
                send(id: id, result: ["tools": Tools.list])
            }

        case "tools/call":
            let text = callTool(params: params)
            if !isNotification {
                send(id: id, result: [
                    "content": [["type": "text", "text": text.text]],
                    "isError": text.isError,
                ])
            }

        case "ping":
            if !isNotification {
                send(id: id, result: [String: Any]())
            }

        default:
            if !isNotification {
                send(id: id, error: -32601, message: "Method not found: \(method)")
            }
        }
    }

    private struct ToolResult {
        let text: String
        let isError: Bool
    }

    private func callTool(params: [String: Any]) -> ToolResult {
        let name = (params["name"] as? String) ?? ""
        let args = (params["arguments"] as? [String: Any]) ?? [:]

        if !Tools.names.contains(name) {
            return ToolResult(text: "Unknown tool: \(name)", isError: true)
        }

        let myID = nextIPCID; nextIPCID += 1
        let req: [String: Any] = ["id": myID, "method": name, "params": args]

        switch sendIPC(req) {
        case .success(let text):
            return ToolResult(text: text, isError: text.hasPrefix("error"))
        case .failure(let why):
            return ToolResult(text: "Could not reach pet GUI: \(why)", isError: true)
        }
    }

    // MARK: - IPC client

    private enum IPCError: Error, CustomStringConvertible {
        case connect, write, read, decode
        var description: String {
            switch self {
            case .connect: return "connect failed"
            case .write:   return "write failed"
            case .read:    return "read failed"
            case .decode:  return "decode failed"
            }
        }
    }

    private func connectToSocket() -> Int32 {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { return -1 }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        IPC.socketPath.withCString { src in
            withUnsafeMutableBytes(of: &addr.sun_path) { dst in
                let dstPtr = dst.baseAddress!.assumingMemoryBound(to: CChar.self)
                _ = strncpy(dstPtr, src, dst.count - 1)
            }
        }
        let addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)
        let rc = withUnsafePointer(to: &addr) { ptr -> Int32 in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                connect(fd, sa, addrLen)
            }
        }
        if rc != 0 { close(fd); return -1 }
        return fd
    }

    private func sendIPC(_ req: [String: Any]) -> Result<String, IPCError> {
        let fd = connectToSocket()
        guard fd >= 0 else { return .failure(.connect) }
        defer { close(fd) }

        guard let data = try? JSONSerialization.data(withJSONObject: req) else {
            return .failure(.write)
        }
        var line = data
        line.append(0x0A)

        let writeResult = line.withUnsafeBytes { buf -> Bool in
            var sent = 0
            while sent < buf.count {
                let n = write(fd, buf.baseAddress!.advanced(by: sent), buf.count - sent)
                if n <= 0 { return false }
                sent += n
            }
            return true
        }
        if !writeResult { return .failure(.write) }

        // Read one line of response
        var buffer = Data()
        var chunk = [UInt8](repeating: 0, count: 4096)
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline {
            let n = read(fd, &chunk, chunk.count)
            if n <= 0 { return .failure(.read) }
            buffer.append(chunk, count: Int(n))
            if buffer.contains(0x0A) { break }
        }
        guard let nl = buffer.firstIndex(of: 0x0A) else { return .failure(.read) }
        let lineData = buffer.subdata(in: 0..<nl)

        guard let obj = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
            return .failure(.decode)
        }
        return .success((obj["result"] as? String) ?? "(empty)")
    }

    // MARK: - JSON-RPC output

    private func send(id: Any?, result: [String: Any]) {
        var msg: [String: Any] = ["jsonrpc": "2.0", "result": result]
        if let id = id { msg["id"] = id }
        writeStdout(msg)
    }

    private func send(id: Any?, error code: Int, message: String) {
        var msg: [String: Any] = [
            "jsonrpc": "2.0",
            "error": ["code": code, "message": message] as [String: Any],
        ]
        if let id = id { msg["id"] = id }
        writeStdout(msg)
    }

    private func writeStdout(_ obj: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: obj) else { return }
        var line = data
        line.append(0x0A)
        FileHandle.standardOutput.write(line)
    }
}

// MARK: - Tool definitions

private enum Tools {
    static let names: Set<String> = [
        "pet_status", "pet_say", "pet_meow", "pet_feed", "pet_pet", "pet_play",
        "pet_wave", "pet_sleep", "pet_wake", "pet_emote",
    ]

    static let list: [[String: Any]] = [
        [
            "name": "pet_status",
            "description": "Get the current state of the user's on-screen desktop cat pet (default name: mochi). Returns mood, hunger, energy, happiness, bond, current pose, and interaction counts. Use whenever the user asks how their pet/cat is doing.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "pet_say",
            "description": "Display a short speech bubble above the on-screen desktop cat pet AND speak the text aloud through macOS TTS in a catty voice (high pitch). Use to relay short messages through the cat. Keep text under ~40 characters for best display + audio.",
            "inputSchema": [
                "type": "object",
                "properties": [
                    "text": ["type": "string", "description": "Text to display in the speech bubble and speak aloud."],
                    "duration": ["type": "number", "description": "Seconds to keep the bubble visible (default 3.0)."],
                    "silent": ["type": "boolean", "description": "If true, only show the bubble without speaking aloud (default false)."],
                ],
                "required": ["text"],
            ],
        ],
        [
            "name": "pet_meow",
            "description": "Make the on-screen desktop cat meow audibly through macOS TTS. With no text, plays a random short meow (喵~/喵呜/mrrr~). With text, speaks that text aloud in the catty voice AND shows it as a bubble. Use sparingly for emphasis or greeting.",
            "inputSchema": [
                "type": "object",
                "properties": [
                    "text": ["type": "string", "description": "Optional text to speak. If omitted, plays a random short meow sound."],
                ],
            ],
        ],
        [
            "name": "pet_feed",
            "description": "Feed a treat to the user's on-screen desktop cat pet. Raises hunger and a little happiness/bond. Use when the user asks to feed the cat or give it a snack.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "pet_pet",
            "description": "Pet (stroke) the user's on-screen desktop cat. Raises happiness and bond. Repeated rapid pets are diminishing. Use when the user wants to pet, stroke, or hug the cat.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "pet_play",
            "description": "Play with the user's on-screen desktop cat (chase a string toy). Raises happiness and bond, lowers energy. Use when the user wants to play with the cat.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "pet_wave",
            "description": "Have the on-screen desktop cat wave at the user. Use to make the pet greet the user.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "pet_sleep",
            "description": "Send the on-screen desktop cat to sleep.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "pet_wake",
            "description": "Wake the on-screen desktop cat up.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "pet_emote",
            "description": "Emit a small particle effect above the on-screen desktop cat to express emotion. Valid kinds: heart (affection), sparkle (delight), star (excitement), note (singing/playful), crumb (eating), dust (sleepy/sad).",
            "inputSchema": [
                "type": "object",
                "properties": [
                    "kind": [
                        "type": "string",
                        "enum": ["heart", "sparkle", "star", "crumb", "dust", "note"],
                    ],
                    "count": ["type": "integer", "description": "1-20 particles (default 5)."],
                ],
                "required": ["kind"],
            ],
        ],
    ]
}
