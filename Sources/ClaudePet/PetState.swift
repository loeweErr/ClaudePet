import Foundation
import AppKit

enum ClaudeModel: String, Codable, CaseIterable {
    case opus, sonnet, haiku

    var label: String {
        switch self {
        case .opus:   return "Opus 4.7"
        case .sonnet: return "Sonnet 4.6"
        case .haiku:  return "Haiku 4.5"
        }
    }

    var windowLimit: Int {
        switch self {
        case .opus:   return 20
        case .sonnet: return 45
        case .haiku:  return 80
        }
    }

    /// approximate "think time" before drafting, in seconds
    var thinkSeconds: Double {
        switch self {
        case .opus:   return 3.0
        case .sonnet: return 2.0
        case .haiku:  return 1.0
        }
    }
}

struct PetState: Codable {
    var name: String = "mochi"
    var posX: Double = 0
    var posY: Double = 0
    var hasPlaced: Bool = false

    var plan: String = "Pro"
    var modelRaw: String = ClaudeModel.sonnet.rawValue
    var windowStart: Date = Date()
    var windowCount: Int = 0
    var opusUsedMin: Double = 0
    var weekStart: Date = PetState.weekStartTs()
    var totalMsgs: Int = 0

    // v2: companion features
    var mood: Mood = Mood()
    var firstLaunch: Date = Date()
    var lastSeenDay: Int = 0                 // last computed "days together" value
    var lastGreetingDate: Date = Date.distantPast
    var shownMilestones: [Int] = []          // days at which milestones already celebrated

    // v3.1: appearance
    var skinId: String = "mochi"             // active skin id (built-in or community)

    var model: ClaudeModel {
        get { ClaudeModel(rawValue: modelRaw) ?? .sonnet }
        set { modelRaw = newValue.rawValue }
    }

    /// Whole-day count since first launch (day 1 on first run).
    var daysWithPet: Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: firstLaunch)
        let today = cal.startOfDay(for: Date())
        let comps = cal.dateComponents([.day], from: start, to: today)
        return (comps.day ?? 0) + 1
    }

    static let storageKey = "com.claude.pet.state.v2"
    static let windowDuration: TimeInterval = 5 * 3600
    static let weekDuration: TimeInterval = 7 * 86400
    /// budget for weekly Opus usage in weighted minutes (matches web mock)
    static let opusWeeklyBudget: Double = 480

    static func weekStartTs() -> Date {
        let cal = Calendar(identifier: .gregorian)
        var c = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        c.weekday = 2 // Monday
        return cal.date(from: c) ?? Date()
    }

    static func load() -> PetState {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return PetState()
        }
        if let s = try? JSONDecoder().decode(PetState.self, from: data) {
            return s
        }
        // Forward-compat migration: a new field was added since the user
        // last saved. Fill missing top-level keys from a fresh default,
        // then re-decode. Avoids losing mood / bond / days-together every
        // time a property is appended to PetState.
        if let saved = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
           let defaultData = try? JSONEncoder().encode(PetState()),
           var defaults = (try? JSONSerialization.jsonObject(with: defaultData)) as? [String: Any] {
            for (k, v) in saved { defaults[k] = v }
            if let merged = try? JSONSerialization.data(withJSONObject: defaults),
               let s = try? JSONDecoder().decode(PetState.self, from: merged) {
                return s
            }
        }
        return PetState()
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: PetState.storageKey)
        }
    }
}

enum StatusMode: String {
    case idle, thinking, running, review, done, sleeping, limit

    var label: String {
        switch self {
        case .idle:     return "idle"
        case .thinking: return "thinking"
        case .running:  return "working"
        case .review:   return "ready"
        case .done:     return "done"
        case .sleeping: return "paused"
        case .limit:    return "paused"
        }
    }

    var headline: String {
        switch self {
        case .idle:     return "ready to help"
        case .thinking: return "thinking…"
        case .running:  return "drafting response"
        case .review:   return "reply ready"
        case .done:     return "all set ✓"
        case .sleeping: return "pet is sleeping"
        case .limit:    return "rate limit reached"
        }
    }

    var detail: String {
        switch self {
        case .idle:     return "> ask me anything"
        case .thinking: return "> reading your context"
        case .running:  return "> writing tokens…"
        case .review:   return "> tap to review ↗"
        case .done:     return "> kitty waved at you"
        case .sleeping: return "> zzz…"
        case .limit:    return "> wait for window reset"
        }
    }

    var isBusy: Bool { self == .thinking || self == .running }
}
