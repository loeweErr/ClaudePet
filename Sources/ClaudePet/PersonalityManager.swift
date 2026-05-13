import Foundation

/// Disk shape for `~/Library/Application Support/ClaudePet/personality.json`.
///
/// This file is the single source of truth for the cat's persona settings.
/// ClaudePet itself doesn't auto-inject the system prompt anywhere — the
/// file is the export that an outer tool (e.g. openclaw-weixin's launchd
/// plist's `CLAUDE_SYSTEM_PROMPT` env var) can read or copy from.
struct PersonalityFile: Codable {
    var presetId: String
    var systemPrompt: String
    var replyCharLimit: Int
    var ttsEnabled: Bool

    static let path: URL = {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSHomeDirectory())
        return base
            .appendingPathComponent("ClaudePet", isDirectory: true)
            .appendingPathComponent("personality.json")
    }()

    static func load() -> PersonalityFile? {
        guard let data = try? Data(contentsOf: path) else { return nil }
        return try? JSONDecoder().decode(PersonalityFile.self, from: data)
    }

    func save() {
        let dir = PersonalityFile.path.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        if let data = try? encoder.encode(self) {
            try? data.write(to: PersonalityFile.path, options: .atomic)
        }
    }
}
