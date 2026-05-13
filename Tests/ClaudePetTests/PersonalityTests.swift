import XCTest
@testable import ClaudePet

final class PersonalityTests: XCTestCase {

    // MARK: - Bundled presets

    func testFiveBuiltInPresetsShipped() {
        XCTAssertEqual(Personality.presets.count, 5)
        XCTAssertEqual(Personality.presets.map { $0.id },
                       ["default", "tsundere", "clingy", "elder", "anime"])
    }

    func testEveryPresetHasNonEmptyPromptAndName() {
        for p in Personality.presets {
            XCTAssertFalse(p.displayName.isEmpty, "preset \(p.id) missing display name")
            XCTAssertFalse(p.systemPrompt.isEmpty, "preset \(p.id) missing prompt")
            XCTAssertGreaterThan(p.systemPrompt.count, 60,
                                 "preset \(p.id) prompt is suspiciously short — \(p.systemPrompt.count) chars")
        }
    }

    func testLookupByIdReturnsNilForUnknown() {
        XCTAssertNil(Personality.preset(id: "definitely-not-a-preset"))
        XCTAssertNotNil(Personality.preset(id: "default"))
    }

    func testCustomIdIsDistinct() {
        XCTAssertEqual(Personality.customId, "custom")
        XCTAssertNil(Personality.preset(id: Personality.customId),
                     "the custom id must not collide with a built-in preset")
    }

    // MARK: - PersonalityFile codable

    func testPersonalityFileCodableRoundTrip() throws {
        let original = PersonalityFile(
            presetId: "tsundere",
            systemPrompt: "你是 mochi。哼…才不是因为想你才出现的呢。",
            replyCharLimit: 25,
            ttsEnabled: false
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PersonalityFile.self, from: data)
        XCTAssertEqual(decoded.presetId, "tsundere")
        XCTAssertEqual(decoded.systemPrompt, original.systemPrompt)
        XCTAssertEqual(decoded.replyCharLimit, 25)
        XCTAssertFalse(decoded.ttsEnabled)
    }

    // MARK: - PetState defaults

    func testPersonalityFieldDefaults() {
        let s = PetState()
        XCTAssertEqual(s.personalityId, "default")
        XCTAssertEqual(s.customSystemPrompt, "")
        XCTAssertEqual(s.replyCharLimit, 40)
        XCTAssertTrue(s.ttsEnabled)
    }
}
