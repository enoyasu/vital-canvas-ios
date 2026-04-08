import Foundation

final class ArtworkTitleGenerator {

    struct TitleResult {
        let title: String
        let subtitle: String
        let summary: String
    }

    func generate(params: BaselineCalculator.NormalizedParams, language: Language = .english) -> TitleResult {
        let title = makeTitle(params: params, language: language)
        let subtitle = makeSubtitle(params: params, language: language)
        let summary = makeSummary(params: params, language: language)
        return TitleResult(title: title, subtitle: subtitle, summary: summary)
    }

    // MARK: - Title

    private func makeTitle(params: BaselineCalculator.NormalizedParams, language: Language) -> String {
        let seed = combinedSeed(params)

        if params.sleep > 0.5 && params.hrv > 0.5 {
            let en = ["Quietly Restored", "Still and Replenished", "A Rested Morning", "Deeply Settled"]
            let ja = ["静かに満たされた", "満ち足りた夜明け", "深く休んだ朝", "心の底まで落ち着いた"]
            return pick(language == .japanese ? ja : en, seed: seed)
        }
        if params.mindfulness > 0.5 && params.activity < 0 {
            let en = ["Still Water, Moving Air", "A Moment of Presence", "Soft Silence", "Held Breath"]
            let ja = ["静水、流れる空気", "存在した瞬間", "柔らかな静寂", "止まった呼吸"]
            return pick(language == .japanese ? ja : en, seed: seed)
        }
        if params.activity > 0.5 {
            let en = ["In Full Motion", "A Spirited Day", "Living with Intention", "Ground Covered"]
            let ja = ["全力で動いた日", "生き生きとした一日", "意志ある一日", "歩んだ大地"]
            return pick(language == .japanese ? ja : en, seed: seed)
        }
        if params.sleep < -0.5 && params.hrv >= 0 {
            let en = ["A Softer Pulse", "Gently Worn", "Tender Fatigue", "Quiet Resilience"]
            let ja = ["穏やかな鼓動", "静かに疲れた", "柔らかな疲労感", "静かな回復力"]
            return pick(language == .japanese ? ja : en, seed: seed)
        }
        if params.restingHR > 0.5 {
            let en = ["Open and Steady", "A Calm Interior", "Unhurried", "Breathing Room"]
            let ja = ["開かれた、揺るぎない", "静かな内側", "急がない", "呼吸の余白"]
            return pick(language == .japanese ? ja : en, seed: seed)
        }

        let en = [
            "A Day with Gentle Motion",
            "The Rhythm of the Ordinary",
            "Between Two Silences",
            "An Even Measure",
            "Soft Ground"
        ]
        let ja = [
            "柔らかな動きの一日",
            "日常のリズム",
            "二つの静寂の間",
            "均等な歩み",
            "柔らかな大地"
        ]
        return pick(language == .japanese ? ja : en, seed: seed)
    }

    // MARK: - Subtitle

    private func makeSubtitle(params: BaselineCalculator.NormalizedParams, language: Language) -> String {
        if params.sleep > 0.5 {
            return language == .japanese ? "今夜は深く眠れました" : "Sleep held you well tonight"
        }
        if params.hrv > 0.5 {
            return language == .japanese ? "あなたのリズムは整っています" : "Your rhythm feels balanced"
        }
        if params.mindfulness > 0.5 {
            return language == .japanese ? "静けさの瞬間が刻まれました" : "A moment of stillness left its mark"
        }
        if params.activity > 0.5 {
            return language == .japanese ? "動きが一日を形作りました" : "Movement shaped the day"
        }
        if params.sleep < -0.5 {
            return language == .japanese ? "短い休息でも、続けられました" : "Rest was brief, but you carried on"
        }
        if params.hrv < -0.5 {
            return language == .japanese ? "今日は何かを抱えていました" : "The body carried something today"
        }
        return language == .japanese ? "毎日は、それぞれの印象を残します" : "Each day leaves its own impression"
    }

    // MARK: - Summary

    private func makeSummary(params: BaselineCalculator.NormalizedParams, language: Language) -> String {
        if language == .japanese {
            var parts: [String] = []
            if params.sleep > 0.3 { parts.append("十分な睡眠") }
            else if params.sleep < -0.3 { parts.append("軽めの睡眠") }
            else { parts.append("安定した睡眠") }
            if params.activity > 0.3 { parts.append("活発な動き") }
            else if params.activity < -0.3 { parts.append("穏やかな体") }
            if params.mindfulness > 0.3 { parts.append("マインドフルな時間") }
            if params.hrv > 0.3 { parts.append("良好な回復") }
            guard !parts.isEmpty else { return "あなた自身のリズムが形作った、静かな一日。" }
            return parts.joined(separator: "、") + "によって形作られました。"
        } else {
            var parts: [String] = []
            let sleepDesc = params.sleep > 0.3 ? "restful sleep" : params.sleep < -0.3 ? "lighter sleep" : "steady sleep"
            parts.append(sleepDesc)
            if params.activity > 0.3 { parts.append("active movement") }
            else if params.activity < -0.3 { parts.append("a quieter body") }
            if params.mindfulness > 0.3 { parts.append("mindful presence") }
            if params.hrv > 0.3 { parts.append("good recovery") }
            return "Shaped by " + parts.joined(separator: ", ") + "."
        }
    }

    // MARK: - Helpers

    private func pick(_ items: [String], seed: Int) -> String {
        guard !items.isEmpty else { return "" }
        var rng = SeededRandom(seed: seed)
        return items[Int(rng.next()) % items.count]
    }

    private func combinedSeed(_ params: BaselineCalculator.NormalizedParams) -> Int {
        let raw = params.sleep * 100 + params.hrv * 73 + params.activity * 53 + params.mindfulness * 41
        return abs(Int(raw * 1000))
    }
}
