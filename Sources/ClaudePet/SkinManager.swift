import Foundation
import AppKit

/// Discovers built-in and community skins and exposes the currently active
/// one. Community skins live at:
///
///   ~/Library/Application Support/ClaudePet/skins/<id>/palette.json
///
/// Each `palette.json` matches `SkinManifest`. Files that fail to parse are
/// logged to stderr and skipped — bad community skins must never crash the
/// app.
final class SkinManager {

    static let shared = SkinManager()

    private(set) var skins: [Skin] = Skin.builtIns
    private(set) var active: Skin = .mochi

    private init() {
        reloadFromDisk()
    }

    /// Re-scan the community skins directory. Built-ins are always present.
    func reloadFromDisk() {
        var found = Skin.builtIns
        let dir = SkinManager.communityDir
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(atPath: dir.path) else {
            skins = found
            return
        }
        for entry in entries.sorted() {
            let manifest = dir.appendingPathComponent(entry).appendingPathComponent("palette.json")
            guard fm.fileExists(atPath: manifest.path) else { continue }
            do {
                let data = try Data(contentsOf: manifest)
                let m = try JSONDecoder().decode(SkinManifest.self, from: data)
                let skin = Skin(
                    id: entry,
                    displayName: m.displayName ?? entry,
                    palette: m.colors,
                    author: m.author,
                    license: m.license,
                    isBuiltIn: false
                )
                found.append(skin)
            } catch {
                FileHandle.standardError.write(Data(
                    "[skins] skipped \(entry): \(error)\n".utf8
                ))
            }
        }
        skins = found
        // If the user had picked a community skin that vanished, fall back.
        if !skins.contains(where: { $0.id == active.id }) {
            active = .mochi
        }
    }

    /// Activate the skin with the given id. Returns the new active skin
    /// (falls back to mochi if the id is unknown).
    @discardableResult
    func activate(id: String) -> Skin {
        if let s = skins.first(where: { $0.id == id }) {
            active = s
        } else {
            active = .mochi
        }
        return active
    }

    static var communityDir: URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSHomeDirectory())
        return base
            .appendingPathComponent("ClaudePet", isDirectory: true)
            .appendingPathComponent("skins", isDirectory: true)
    }
}

/// Disk schema for community skins. Mirrors `Skin` minus the id (which is
/// the directory name) and the isBuiltIn flag.
private struct SkinManifest: Decodable {
    let displayName: String?
    let author: String?
    let license: String?
    let colors: CatPalette
}
