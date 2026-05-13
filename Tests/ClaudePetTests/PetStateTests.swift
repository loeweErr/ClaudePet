import XCTest
@testable import ClaudePet

final class PetStateTests: XCTestCase {

    // MARK: - defaults

    func testDefaultStateValues() {
        let s = PetState()
        XCTAssertEqual(s.name, "mochi")
        XCTAssertFalse(s.hasPlaced)
        XCTAssertEqual(s.modelRaw, ClaudeModel.sonnet.rawValue)
        XCTAssertEqual(s.totalMsgs, 0)
        XCTAssertEqual(s.shownMilestones, [])
        XCTAssertEqual(s.skinId, "mochi")
        XCTAssertTrue(s.hotkeysEnabled)
    }

    func testDefaultMoodIsHealthy() {
        let s = PetState()
        XCTAssertEqual(s.mood.hunger, 72)
        XCTAssertEqual(s.mood.happiness, 65)
        XCTAssertEqual(s.mood.energy, 80)
        XCTAssertEqual(s.mood.bond, 0)
    }

    // MARK: - Codable round-trip

    func testStateCodableRoundTrip() throws {
        var original = PetState()
        original.name = "shadow"
        original.posX = 123.4
        original.posY = 567.8
        original.hasPlaced = true
        original.totalMsgs = 42
        original.shownMilestones = [1, 3, 7]
        original.mood.hunger = 33.3
        original.mood.bond = 55.5

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PetState.self, from: data)

        XCTAssertEqual(decoded.name, "shadow")
        XCTAssertEqual(decoded.posX, 123.4, accuracy: 0.001)
        XCTAssertEqual(decoded.posY, 567.8, accuracy: 0.001)
        XCTAssertTrue(decoded.hasPlaced)
        XCTAssertEqual(decoded.totalMsgs, 42)
        XCTAssertEqual(decoded.shownMilestones, [1, 3, 7])
        XCTAssertEqual(decoded.mood.hunger, 33.3, accuracy: 0.001)
        XCTAssertEqual(decoded.mood.bond, 55.5, accuracy: 0.001)
    }

    func testMoodCodableRoundTripPreservesTimestamps() throws {
        var m = Mood()
        let t = Date(timeIntervalSince1970: 1_700_000_000)
        m.lastFedAt = t
        m.lastPettedAt = t.addingTimeInterval(60)
        m.lastPlayAt = t.addingTimeInterval(120)
        m.totalTreats = 7
        m.totalPets = 11
        m.totalPlays = 3

        let data = try JSONEncoder().encode(m)
        let decoded = try JSONDecoder().decode(Mood.self, from: data)

        XCTAssertEqual(decoded.lastFedAt.timeIntervalSince1970,
                       t.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(decoded.totalTreats, 7)
        XCTAssertEqual(decoded.totalPets, 11)
        XCTAssertEqual(decoded.totalPlays, 3)
    }

    // MARK: - daysWithPet

    func testDaysWithPetIsOneOnFirstLaunchDay() {
        var s = PetState()
        s.firstLaunch = Date() // today
        XCTAssertEqual(s.daysWithPet, 1)
    }

    func testDaysWithPetGrowsWithTime() {
        var s = PetState()
        s.firstLaunch = Calendar.current.date(byAdding: .day, value: -6, to: Date())!
        XCTAssertEqual(s.daysWithPet, 7)
    }

    // MARK: - ClaudeModel

    func testClaudeModelWindowLimits() {
        XCTAssertEqual(ClaudeModel.opus.windowLimit, 20)
        XCTAssertEqual(ClaudeModel.sonnet.windowLimit, 45)
        XCTAssertEqual(ClaudeModel.haiku.windowLimit, 80)
    }

    func testClaudeModelThinkSeconds() {
        XCTAssertEqual(ClaudeModel.opus.thinkSeconds, 3.0, accuracy: 0.001)
        XCTAssertEqual(ClaudeModel.sonnet.thinkSeconds, 2.0, accuracy: 0.001)
        XCTAssertEqual(ClaudeModel.haiku.thinkSeconds, 1.0, accuracy: 0.001)
    }

    func testClaudeModelLabelMatchesCanonicalName() {
        XCTAssertTrue(ClaudeModel.opus.label.contains("Opus"))
        XCTAssertTrue(ClaudeModel.sonnet.label.contains("Sonnet"))
        XCTAssertTrue(ClaudeModel.haiku.label.contains("Haiku"))
    }

    func testClaudeModelRawValueRoundTrip() {
        for m in ClaudeModel.allCases {
            XCTAssertEqual(ClaudeModel(rawValue: m.rawValue), m)
        }
    }

    func testPetStateModelGetterFallsBackToSonnetForUnknownRaw() {
        var s = PetState()
        s.modelRaw = "gpt-5"
        XCTAssertEqual(s.model, .sonnet)
    }

    func testPetStateModelSetterUpdatesRaw() {
        var s = PetState()
        s.model = .haiku
        XCTAssertEqual(s.modelRaw, "haiku")
    }

    // MARK: - constants

    func testWindowAndWeekConstants() {
        XCTAssertEqual(PetState.windowDuration, 5 * 3600, accuracy: 0.001)
        XCTAssertEqual(PetState.weekDuration, 7 * 86400, accuracy: 0.001)
        XCTAssertEqual(PetState.opusWeeklyBudget, 480, accuracy: 0.001)
    }

    func testStorageKeyIsStableAcrossLaunches() {
        // The on-disk key must not silently move; tests guard against
        // accidentally bumping it (which would orphan every user's saved state).
        XCTAssertEqual(PetState.storageKey, "com.claude.pet.state.v2")
    }

    func testWeekStartIsAMonday() {
        let cal = Calendar(identifier: .gregorian)
        let weekStart = PetState.weekStartTs()
        XCTAssertEqual(cal.component(.weekday, from: weekStart), 2) // Monday
    }
}
