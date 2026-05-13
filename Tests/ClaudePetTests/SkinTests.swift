import XCTest
@testable import ClaudePet

final class SkinTests: XCTestCase {

    // MARK: - RGBA hex parsing

    func testRGBAParsesSixDigitHex() {
        let c = RGBA.parseHex("#AABBCC")
        XCTAssertNotNil(c)
        XCTAssertEqual(c?.r ?? 0, 170.0/255, accuracy: 0.001)
        XCTAssertEqual(c?.g ?? 0, 187.0/255, accuracy: 0.001)
        XCTAssertEqual(c?.b ?? 0, 204.0/255, accuracy: 0.001)
        XCTAssertEqual(c?.a ?? 0, 1.0, accuracy: 0.001)
    }

    func testRGBAParsesEightDigitHexWithAlpha() {
        let c = RGBA.parseHex("#AABBCC80")
        XCTAssertEqual(c?.a ?? 0, 128.0/255, accuracy: 0.001)
    }

    func testRGBAToleratesMissingHash() {
        XCTAssertNotNil(RGBA.parseHex("AABBCC"))
    }

    func testRGBARejectsInvalidHex() {
        XCTAssertNil(RGBA.parseHex("#GGGGGG"))
        XCTAssertNil(RGBA.parseHex("#FFF"))         // wrong length
        XCTAssertNil(RGBA.parseHex(""))
    }

    func testRGBARoundTripsHex() {
        let c = RGBA(0.5, 0.25, 0.75, 1.0)
        let s = c.toHex()
        let parsed = RGBA.parseHex(s)
        XCTAssertEqual(parsed?.r ?? 0, c.r, accuracy: 0.01)
        XCTAssertEqual(parsed?.g ?? 0, c.g, accuracy: 0.01)
        XCTAssertEqual(parsed?.b ?? 0, c.b, accuracy: 0.01)
    }

    // MARK: - Skin built-ins

    func testThreeBuiltInSkinsAreShipped() {
        XCTAssertEqual(Skin.builtIns.count, 3)
        XCTAssertEqual(Skin.builtIns.map { $0.id }, ["mochi", "shadow", "snow"])
        for s in Skin.builtIns {
            XCTAssertTrue(s.isBuiltIn)
            XCTAssertFalse(s.displayName.isEmpty)
        }
    }

    // MARK: - palette.json codable

    func testPaletteDecodesFromJSONManifest() throws {
        let json = """
        {
          "primary":      "#7B68EE",
          "primaryDark":  "#5547B0",
          "primaryLight": "#A89AF0",
          "belly":        "#F4F0FF",
          "cheek":        "#FFB3C8",
          "cheekDeep":    "#D8849E",
          "eye":          "#180E08",
          "highlight":    "#FFFFFF",
          "iris":         "#5FCC58",
          "accent":       "#F8C124"
        }
        """
        let p = try JSONDecoder().decode(CatPalette.self, from: Data(json.utf8))
        XCTAssertEqual(p.primary.toHex(), "#7B68EE")
        XCTAssertEqual(p.iris.toHex(),    "#5FCC58")
    }

    func testPaletteDecodeFailsOnBadColor() {
        let json = """
        {
          "primary":      "not a color",
          "primaryDark":  "#000000",
          "primaryLight": "#000000",
          "belly":        "#000000",
          "cheek":        "#000000",
          "cheekDeep":    "#000000",
          "eye":          "#000000",
          "highlight":    "#000000",
          "iris":         "#000000",
          "accent":       "#000000"
        }
        """
        XCTAssertThrowsError(
            try JSONDecoder().decode(CatPalette.self, from: Data(json.utf8))
        )
    }

    // MARK: - SkinManager

    func testSkinManagerActivateUnknownIdFallsBackToMochi() {
        let m = SkinManager.shared
        m.activate(id: "definitely-not-a-real-skin")
        XCTAssertEqual(m.active.id, "mochi")
    }

    func testSkinManagerActivateBuiltIn() {
        let m = SkinManager.shared
        m.activate(id: "shadow")
        XCTAssertEqual(m.active.id, "shadow")
        m.activate(id: "mochi") // restore default for other tests
    }

    func testSkinManagerExposesBuiltIns() {
        let ids = SkinManager.shared.skins.map { $0.id }
        XCTAssertTrue(ids.contains("mochi"))
        XCTAssertTrue(ids.contains("shadow"))
        XCTAssertTrue(ids.contains("snow"))
    }

    // MARK: - PetState backward-compat migration

    func testPetStateLoadMigratesOldSavesMissingSkinId() throws {
        // Simulate a pre-skin save: encode PetState and strip skinId from
        // the JSON, then run it through the migration in load().
        var s = PetState()
        s.name = "old-mochi"
        s.totalMsgs = 99
        let data = try JSONEncoder().encode(s)
        var dict = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        dict.removeValue(forKey: "skinId")
        let stripped = try JSONSerialization.data(withJSONObject: dict)

        // The decoder should reject the stripped payload directly,
        // forcing the migration path in load().
        XCTAssertThrowsError(try JSONDecoder().decode(PetState.self, from: stripped))

        // Persist the stripped data through UserDefaults (the same path
        // load() reads from), then verify migration kicks in.
        let testDefaults = UserDefaults.standard
        testDefaults.set(stripped, forKey: PetState.storageKey)
        defer { testDefaults.removeObject(forKey: PetState.storageKey) }

        let loaded = PetState.load()
        XCTAssertEqual(loaded.name, "old-mochi")
        XCTAssertEqual(loaded.totalMsgs, 99)
        XCTAssertEqual(loaded.skinId, "mochi") // default for missing field
    }
}
