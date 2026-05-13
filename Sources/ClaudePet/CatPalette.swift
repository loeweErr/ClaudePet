import AppKit

/// Named slots used by `CatRenderer` when drawing the procedural pixel cat.
/// Skins do not change shape — only colors. Spritesheet support is intentionally
/// deferred so that contributing a new look only requires editing palette.json.
struct CatPalette: Codable {
    let primary:      RGBA
    let primaryDark:  RGBA
    let primaryLight: RGBA
    let belly:        RGBA
    let cheek:        RGBA
    let cheekDeep:    RGBA
    let eye:          RGBA
    let highlight:    RGBA
    let iris:         RGBA
    let accent:       RGBA

    var primaryColor:      NSColor { primary.nsColor }
    var primaryDarkColor:  NSColor { primaryDark.nsColor }
    var primaryLightColor: NSColor { primaryLight.nsColor }
    var bellyColor:        NSColor { belly.nsColor }
    var cheekColor:        NSColor { cheek.nsColor }
    var cheekDeepColor:    NSColor { cheekDeep.nsColor }
    var eyeColor:          NSColor { eye.nsColor }
    var highlightColor:    NSColor { highlight.nsColor }
    var irisColor:         NSColor { iris.nsColor }
    var accentColor:       NSColor { accent.nsColor }
}

/// Codable-friendly RGBA in 0..1 floats. Hex strings are accepted on decode
/// (`"#RRGGBB"` or `"#RRGGBBAA"`) so that palette.json files stay readable.
struct RGBA: Codable {
    let r: Double
    let g: Double
    let b: Double
    let a: Double

    init(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let s = try container.decode(String.self)
        guard let parsed = RGBA.parseHex(s) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid hex color: \(s) (expected #RRGGBB or #RRGGBBAA)")
        }
        self = parsed
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(toHex())
    }

    var nsColor: NSColor {
        NSColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
    }

    func toHex() -> String {
        let R = Int((r * 255).rounded())
        let G = Int((g * 255).rounded())
        let B = Int((b * 255).rounded())
        let A = Int((a * 255).rounded())
        if A == 255 {
            return String(format: "#%02X%02X%02X", R, G, B)
        }
        return String(format: "#%02X%02X%02X%02X", R, G, B, A)
    }

    static func parseHex(_ s: String) -> RGBA? {
        var hex = s
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6 || hex.count == 8 else { return nil }
        guard let v = UInt64(hex, radix: 16) else { return nil }
        let r, g, b, a: Double
        if hex.count == 8 {
            r = Double((v >> 24) & 0xFF) / 255
            g = Double((v >> 16) & 0xFF) / 255
            b = Double((v >>  8) & 0xFF) / 255
            a = Double( v        & 0xFF) / 255
        } else {
            r = Double((v >> 16) & 0xFF) / 255
            g = Double((v >>  8) & 0xFF) / 255
            b = Double( v        & 0xFF) / 255
            a = 1
        }
        return RGBA(r, g, b, a)
    }
}

// MARK: - Skin envelope

/// A skin = a palette plus author/license metadata. Bundled skins are
/// constructed in code; community skins are loaded from
/// `~/Library/Application Support/ClaudePet/skins/<name>/palette.json`.
struct Skin {
    let id: String
    let displayName: String
    let palette: CatPalette
    let author: String?
    let license: String?
    let isBuiltIn: Bool
}

extension Skin {

    static let mochi = Skin(
        id: "mochi",
        displayName: "Mochi (orange)",
        palette: CatPalette(
            primary:      RGBA(0.91, 0.53, 0.29),
            primaryDark:  RGBA(0.72, 0.39, 0.20),
            primaryLight: RGBA(0.96, 0.73, 0.48),
            belly:        RGBA(1.00, 0.94, 0.83),
            cheek:        RGBA(1.00, 0.62, 0.78),
            cheekDeep:    RGBA(0.85, 0.44, 0.63),
            eye:          RGBA(0.10, 0.06, 0.03),
            highlight:    RGBA(1.00, 1.00, 1.00),
            iris:         RGBA(0.37, 0.79, 0.31),
            accent:       RGBA(0.98, 0.75, 0.14)
        ),
        author: "loeweErr",
        license: "MIT",
        isBuiltIn: true
    )

    static let shadow = Skin(
        id: "shadow",
        displayName: "Shadow (black)",
        palette: CatPalette(
            primary:      RGBA(0.30, 0.30, 0.34),
            primaryDark:  RGBA(0.16, 0.16, 0.20),
            primaryLight: RGBA(0.46, 0.46, 0.52),
            belly:        RGBA(0.82, 0.83, 0.86),
            cheek:        RGBA(0.95, 0.62, 0.74),
            cheekDeep:    RGBA(0.78, 0.42, 0.58),
            eye:          RGBA(0.06, 0.04, 0.04),
            highlight:    RGBA(1.00, 1.00, 1.00),
            iris:         RGBA(0.96, 0.78, 0.18), // amber, classic black-cat eye
            accent:       RGBA(0.62, 0.78, 0.96)  // cool blue gear
        ),
        author: "loeweErr",
        license: "MIT",
        isBuiltIn: true
    )

    static let snow = Skin(
        id: "snow",
        displayName: "Snow (white)",
        palette: CatPalette(
            primary:      RGBA(0.96, 0.96, 0.97),
            primaryDark:  RGBA(0.78, 0.80, 0.84),
            primaryLight: RGBA(1.00, 1.00, 1.00),
            belly:        RGBA(1.00, 1.00, 1.00),
            cheek:        RGBA(1.00, 0.74, 0.84),
            cheekDeep:    RGBA(0.86, 0.50, 0.66),
            eye:          RGBA(0.10, 0.06, 0.03),
            highlight:    RGBA(0.85, 0.92, 1.00),
            iris:         RGBA(0.34, 0.62, 0.92), // ice blue
            accent:       RGBA(0.98, 0.75, 0.14)
        ),
        author: "loeweErr",
        license: "MIT",
        isBuiltIn: true
    )

    static let builtIns: [Skin] = [.mochi, .shadow, .snow]
}
