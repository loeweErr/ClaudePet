import XCTest
@testable import ClaudePet

final class MoodSystemTests: XCTestCase {

    // MARK: - tick() decay

    func testTickIdleHourDecay() {
        var m = Mood(hunger: 80, happiness: 80, energy: 80, bond: 0)
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        m.lastTickAt = t0
        m.tick(now: t0.addingTimeInterval(3600), isSleeping: false, isWorking: false)

        XCTAssertEqual(m.hunger,    74, accuracy: 0.001) // -6/h
        XCTAssertEqual(m.happiness, 77, accuracy: 0.001) // -3/h
        XCTAssertEqual(m.energy,    78, accuracy: 0.001) // -2/h idle
        XCTAssertEqual(m.bond,    0.8, accuracy: 0.001)  // +0.8/h
    }

    func testTickWorkingDrainsEnergyFaster() {
        var m = Mood(hunger: 80, happiness: 80, energy: 80, bond: 0)
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        m.lastTickAt = t0
        m.tick(now: t0.addingTimeInterval(3600), isSleeping: false, isWorking: true)
        XCTAssertEqual(m.energy, 68, accuracy: 0.001) // -12/h working
    }

    func testTickSleepingRegeneratesEnergy() {
        var m = Mood(hunger: 80, happiness: 80, energy: 40, bond: 0)
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        m.lastTickAt = t0
        m.tick(now: t0.addingTimeInterval(3600), isSleeping: true, isWorking: false)
        XCTAssertEqual(m.energy, 70, accuracy: 0.001) // +30/h sleeping
    }

    func testTickAppliesNeglectPenaltyWhenHungry() {
        // hunger < 20 should add an extra -5/h to happiness on top of the base -3/h
        var m = Mood(hunger: 10, happiness: 80, energy: 80, bond: 0)
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        m.lastTickAt = t0
        m.tick(now: t0.addingTimeInterval(3600), isSleeping: false, isWorking: false)
        XCTAssertEqual(m.happiness, 80 - 3 - 5, accuracy: 0.001)
    }

    func testTickAppliesNeglectPenaltyWhenLowEnergy() {
        var m = Mood(hunger: 80, happiness: 80, energy: 10, bond: 0)
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        m.lastTickAt = t0
        m.tick(now: t0.addingTimeInterval(3600), isSleeping: false, isWorking: false)
        XCTAssertEqual(m.happiness, 80 - 3 - 5, accuracy: 0.001)
    }

    func testTickIsNoOpWhenElapsedNotPositive() {
        var m = Mood(hunger: 80, happiness: 80, energy: 80, bond: 5)
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        m.lastTickAt = t0
        m.tick(now: t0, isSleeping: false, isWorking: false) // elapsed = 0
        XCTAssertEqual(m.hunger, 80)
        XCTAssertEqual(m.happiness, 80)
        XCTAssertEqual(m.energy, 80)
        XCTAssertEqual(m.bond, 5)
    }

    func testTickClampsValuesWithinZeroHundred() {
        var m = Mood(hunger: 1, happiness: 1, energy: 99, bond: 99.5)
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        m.lastTickAt = t0
        // Many hours: should clamp at the bounds, never overflow
        m.tick(now: t0.addingTimeInterval(3600 * 100), isSleeping: true, isWorking: false)
        XCTAssertGreaterThanOrEqual(m.hunger, 0)
        XCTAssertLessThanOrEqual(m.hunger, 100)
        XCTAssertGreaterThanOrEqual(m.happiness, 0)
        XCTAssertLessThanOrEqual(m.energy, 100)
        XCTAssertLessThanOrEqual(m.bond, 100)
    }

    // MARK: - feed / pet / play cooldowns

    func testFeedAfterCooldownGivesBigBonus() {
        var m = Mood(hunger: 40, happiness: 40, energy: 80, bond: 0)
        m.lastFedAt = Date().addingTimeInterval(-1801) // > 30 min
        m.feed()
        XCTAssertEqual(m.hunger, 66, accuracy: 0.001)      // +26
        XCTAssertEqual(m.happiness, 46, accuracy: 0.001)   // +6
        XCTAssertEqual(m.bond, 1.2, accuracy: 0.001)
        XCTAssertEqual(m.totalTreats, 1)
    }

    func testFeedDuringCooldownGivesSmallBonus() {
        var m = Mood(hunger: 40, happiness: 40, energy: 80, bond: 0)
        m.lastFedAt = Date().addingTimeInterval(-100) // <= 30 min
        m.feed()
        XCTAssertEqual(m.hunger, 48, accuracy: 0.001) // +8 (overfeeding penalty)
    }

    func testPetAfterCooldownGivesBigBonus() {
        var m = Mood(hunger: 80, happiness: 40, energy: 80, bond: 0)
        m.lastPettedAt = Date().addingTimeInterval(-31) // > 30 sec
        m.pet()
        XCTAssertEqual(m.happiness, 49, accuracy: 0.001) // +9
        XCTAssertEqual(m.bond, 0.6, accuracy: 0.001)
        XCTAssertEqual(m.totalPets, 1)
    }

    func testPetDuringCooldownGivesSmallBonus() {
        var m = Mood(hunger: 80, happiness: 40, energy: 80, bond: 0)
        m.lastPettedAt = Date().addingTimeInterval(-5) // <= 30 sec
        m.pet()
        XCTAssertEqual(m.happiness, 42, accuracy: 0.001) // +2
    }

    func testPlay() {
        var m = Mood(hunger: 80, happiness: 40, energy: 80, bond: 0)
        m.play()
        XCTAssertEqual(m.happiness, 54, accuracy: 0.001) // +14
        XCTAssertEqual(m.energy, 70, accuracy: 0.001)    // -10
        XCTAssertEqual(m.bond, 1.8, accuracy: 0.001)
        XCTAssertEqual(m.totalPlays, 1)
    }

    // MARK: - dominantNeed thresholds

    func testDominantNeedHungry() {
        let m = Mood(hunger: 21, happiness: 50, energy: 80, bond: 5)
        XCTAssertEqual(m.dominantNeed, .hungry)
    }

    func testDominantNeedTired() {
        let m = Mood(hunger: 50, happiness: 50, energy: 17, bond: 5)
        XCTAssertEqual(m.dominantNeed, .tired)
    }

    func testDominantNeedLonely() {
        let m = Mood(hunger: 50, happiness: 29, energy: 80, bond: 5)
        XCTAssertEqual(m.dominantNeed, .lonely)
    }

    func testDominantNeedJoyful() {
        let m = Mood(hunger: 80, happiness: 90, energy: 80, bond: 30)
        XCTAssertEqual(m.dominantNeed, .joyful)
    }

    func testDominantNeedJoyfulRequiresBondAboveTwentyFive() {
        // Happy but low bond: not joyful
        let m = Mood(hunger: 80, happiness: 90, energy: 80, bond: 25)
        XCTAssertEqual(m.dominantNeed, .content)
    }

    func testDominantNeedContent() {
        let m = Mood(hunger: 50, happiness: 50, energy: 80, bond: 5)
        XCTAssertEqual(m.dominantNeed, .content)
    }

    // MARK: - bondLevel boundaries

    func testBondLevelStranger() {
        let m = Mood(bond: 7.99)
        XCTAssertEqual(m.bondLevel, .stranger)
    }

    func testBondLevelFamiliar() {
        let m = Mood(bond: 8)
        XCTAssertEqual(m.bondLevel, .familiar)
    }

    func testBondLevelFriend() {
        let m = Mood(bond: 22)
        XCTAssertEqual(m.bondLevel, .friend)
    }

    func testBondLevelCompanion() {
        let m = Mood(bond: 45)
        XCTAssertEqual(m.bondLevel, .companion)
    }

    func testBondLevelFamily() {
        let m = Mood(bond: 75)
        XCTAssertEqual(m.bondLevel, .family)
    }

    // MARK: - Milestone

    func testMilestoneThresholdsList() {
        XCTAssertEqual(Milestone.thresholds, [1, 3, 7, 14, 30, 60, 100, 200, 365])
    }

    func testMilestoneMessageForKnownDays() {
        for d in Milestone.thresholds {
            XCTAssertNotNil(Milestone.message(for: d, name: "mochi"),
                            "expected milestone message for day \(d)")
        }
    }

    func testMilestoneMessageForUnknownDay() {
        XCTAssertNil(Milestone.message(for: 2, name: "mochi"))
        XCTAssertNil(Milestone.message(for: 365 * 2, name: "mochi"))
    }

    func testMilestoneMessageInterpolatesName() {
        let msg = Milestone.message(for: 1, name: "mochi") ?? ""
        XCTAssertTrue(msg.contains("mochi"))
    }
}
