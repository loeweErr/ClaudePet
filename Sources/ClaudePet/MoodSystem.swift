import Foundation

/// Pet's emotional state. Decays over time; interactions raise it.
struct Mood: Codable {
    var hunger: Double = 72     // 0 = starving, 100 = full
    var happiness: Double = 65  // 0 = sad,      100 = joyful
    var energy: Double = 80     // 0 = exhausted,100 = energetic
    var bond: Double = 0        // 0 = stranger, 100 = family

    var lastTickAt: Date = Date()
    var lastFedAt:    Date = Date().addingTimeInterval(-7200)
    var lastPettedAt: Date = Date().addingTimeInterval(-7200)
    var lastPlayAt:   Date = Date().addingTimeInterval(-7200)

    var totalPets: Int = 0
    var totalTreats: Int = 0
    var totalPlays: Int = 0

    /// Apply decay/regen based on elapsed time and current activity.
    mutating func tick(now: Date, isSleeping: Bool, isWorking: Bool) {
        let elapsedH = now.timeIntervalSince(lastTickAt) / 3600
        guard elapsedH > 0 else { return }
        lastTickAt = now

        hunger    = Mood.clamp(hunger    - 6.0 * elapsedH)
        happiness = Mood.clamp(happiness - 3.0 * elapsedH)
        bond      = Mood.clamp(bond      + 0.8 * elapsedH)

        if isSleeping {
            energy = Mood.clamp(energy + 30 * elapsedH)
        } else if isWorking {
            energy = Mood.clamp(energy - 12 * elapsedH)
        } else {
            energy = Mood.clamp(energy - 2 * elapsedH)
        }

        // Sad if neglected
        if hunger < 20 || energy < 15 {
            happiness = Mood.clamp(happiness - 5 * elapsedH)
        }
    }

    mutating func feed() {
        let sinceLast = Date().timeIntervalSince(lastFedAt)
        // Overfeeding penalty: less effect if fed recently
        let bonus: Double = sinceLast > 1800 ? 26 : 8
        hunger    = Mood.clamp(hunger + bonus)
        happiness = Mood.clamp(happiness + 6)
        bond      = Mood.clamp(bond + 1.2)
        lastFedAt = Date()
        totalTreats += 1
    }

    mutating func pet() {
        let sinceLast = Date().timeIntervalSince(lastPettedAt)
        let bonus: Double = sinceLast > 30 ? 9 : 2
        happiness = Mood.clamp(happiness + bonus)
        bond      = Mood.clamp(bond + 0.6)
        lastPettedAt = Date()
        totalPets += 1
    }

    mutating func play() {
        happiness = Mood.clamp(happiness + 14)
        energy    = Mood.clamp(energy - 10)
        bond      = Mood.clamp(bond + 1.8)
        lastPlayAt = Date()
        totalPlays += 1
    }

    var dominantNeed: MoodNeed {
        if hunger < 22 { return .hungry }
        if energy < 18 { return .tired }
        if happiness < 30 { return .lonely }
        if happiness > 82 && bond > 25 { return .joyful }
        return .content
    }

    var bondLevel: BondLevel {
        switch bond {
        case ..<8:  return .stranger
        case ..<22: return .familiar
        case ..<45: return .friend
        case ..<75: return .companion
        default:    return .family
        }
    }

    private static func clamp(_ v: Double) -> Double {
        max(0, min(100, v))
    }
}

enum MoodNeed {
    case hungry, tired, lonely, content, joyful

    var idleBubble: String {
        switch self {
        case .hungry: return ["小肚子饿了…", "想吃小鱼干 🐟", "*蹭碗*", "看看零食？"].randomElement()!
        case .tired:  return ["好困… zzz", "想小睡一下", "（打哈欠）", "眼皮重重的"].randomElement()!
        case .lonely: return ["…", "孤单 (｡•́︿•̀｡)", "陪我一会儿", "想要抱抱"].randomElement()!
        case .content:return ["purr~", "今天也很好", "(=^･ω･^=)", "*尾巴轻摆*"].randomElement()!
        case .joyful: return ["♡♡♡", "最爱你了!", "今天最棒", "*开心打转*"].randomElement()!
        }
    }
}

enum BondLevel: String {
    case stranger  = "初识"
    case familiar  = "熟悉"
    case friend    = "朋友"
    case companion = "伙伴"
    case family    = "家人"

    var emoji: String {
        switch self {
        case .stranger:  return "·"
        case .familiar:  return "♢"
        case .friend:    return "♡"
        case .companion: return "♥"
        case .family:    return "✦"
        }
    }
}

/// Time-of-day awareness.
enum DayPhase {
    case earlyMorning, morning, afternoon, evening, night, lateNight

    static func current() -> DayPhase {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<8:   return .earlyMorning
        case 8..<12:  return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        case 21..<24: return .night
        default:      return .lateNight   // 0..5
        }
    }

    func greeting(name: String, days: Int) -> String {
        let d = days
        switch self {
        case .earlyMorning: return "おはよう~ 又是一天 ☀ (day \(d))"
        case .morning:      return "早上好！今天也加油 (day \(d))"
        case .afternoon:    return "下午好~ 在忙呢？(day \(d))"
        case .evening:      return "辛苦啦 🌆 (day \(d))"
        case .night:        return "晚上好 ✦ (day \(d))"
        case .lateNight:    return "你还醒着？(day \(d))"
        }
    }

    /// Spontaneous comment about the time, if pet feels like saying something.
    var ambientComment: String? {
        switch self {
        case .lateNight: return ["太晚了…一起睡吧", "你眼睛会累的", "*担心地看着你*"].randomElement()
        case .earlyMorning: return ["阳光暖暖的", "新的一天 ♡"].randomElement()
        default: return nil
        }
    }
}

/// Milestones celebrated as days-together hit thresholds.
enum Milestone {
    static let thresholds = [1, 3, 7, 14, 30, 60, 100, 200, 365]

    static func message(for day: Int, name: String) -> String? {
        switch day {
        case 1:   return "和 \(name) 的第一天 ♡"
        case 3:   return "三天啦 ✦"
        case 7:   return "一周了！\(name) 越来越熟"
        case 14:  return "两周了 (=^･ω･^=)"
        case 30:  return "一个月了！这是纪念日 🎉"
        case 60:  return "两个月，\(name) 已经是伙伴了"
        case 100: return "百日纪念 ✨"
        case 200: return "200 天，\(name) 是家人了"
        case 365: return "一年了 ♡ 谢谢你"
        default:  return nil
        }
    }
}
