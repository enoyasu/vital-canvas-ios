import Foundation

enum Language: String, CaseIterable {
    case english = "en"
    case japanese = "ja"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .japanese: return "日本語"
        }
    }

    var nativeName: String {
        switch self {
        case .english: return "English"
        case .japanese: return "日本語"
        }
    }
}

@Observable
final class LanguageManager {
    private(set) var current: Language
    private(set) var hasSelectedLanguage: Bool

    init() {
        let saved = UserDefaults.standard.string(forKey: "vc_language")
        if let saved, let lang = Language(rawValue: saved) {
            self.current = lang
            self.hasSelectedLanguage = true
        } else {
            self.current = .english
            self.hasSelectedLanguage = false
        }
    }

    func select(_ language: Language) {
        current = language
        hasSelectedLanguage = true
        UserDefaults.standard.set(language.rawValue, forKey: "vc_language")
    }

    var s: Strings { Strings(lang: current) }
}

// MARK: - Localised Strings

struct Strings {
    let lang: Language

    private func l(_ en: String, _ ja: String) -> String {
        lang == .japanese ? ja : en
    }

    // MARK: Language Selection
    var langSelectTitle: String     { l("Choose your language", "言語を選択") }
    var langSelectSubtitle: String  { l("You can change this later in Settings.", "あとで設定から変更できます。") }
    var langContinue: String        { l("Continue", "続ける") }

    // MARK: Onboarding
    var ob1Title: String    { l("Your days, as art", "毎日の記録を、アートに") }
    var ob1Body: String     { l(
        "Vital Canvas transforms your daily health rhythms into a unique piece of abstract art — one canvas per day, shaped entirely by you.",
        "Vital Canvasは、あなたの日々の健康リズムをユニークなアート作品に変えます。一日一枚、あなただけのキャンバス。"
    ) }
    var ob2Title: String    { l("Private by design", "プライバシー最優先") }
    var ob2Body: String     { l(
        "Your health data never leaves your device. Vital Canvas reads only what it needs to shape your canvas — nothing more.",
        "健康データはデバイスの外に出ることはありません。キャンバスを生成するためだけに、必要最小限のデータを読み取ります。"
    ) }
    var ob3Title: String    { l("Begin your gallery", "ギャラリーを始めよう") }
    var ob3Body: String     { l(
        "Connect Apple Health and generate your first canvas. Your personal gallery starts today.",
        "Apple Healthと連携して、最初のキャンバスを生成しましょう。あなたのギャラリーが今日始まります。"
    ) }
    var obContinue: String          { l("Continue", "続ける") }
    var obConnect: String           { l("Connect Apple Health", "Apple Healthと連携") }
    var obSkip: String              { l("Skip for now", "後で設定する") }

    // MARK: Home
    var homeTitle: String           { l("Your Canvas", "あなたのキャンバス") }
    var homeRecentTitle: String     { l("Recent canvases", "最近のキャンバス") }
    func homeRecentCount(_ n: Int) -> String {
        l("\(n) days", "\(n)日間")
    }
    var homeNoCanvas: String        { l("No canvas yet", "まだキャンバスがありません") }
    var homeGenerating: String      { l("Shaping your canvas…", "キャンバスを生成中…") }
    var homeGathering: String       { l("Gathering today's rhythm", "今日のリズムを収集しています") }

    // MARK: Gallery
    var galleryTitle: String        { l("Gallery", "ギャラリー") }
    var galleryEmptyTitle: String   { l("Your gallery is growing", "ギャラリーが育っています") }
    var galleryEmptyBody: String    { l(
        "Come back each day to see your collection.",
        "毎日訪れることで、あなたのコレクションが増えていきます。"
    ) }

    // MARK: Detail
    var detailHealthSnapshot: String { l("Health snapshot", "ヘルス概要") }
    var detailSaveShare: String     { l("Save / Share", "保存・共有") }

    // MARK: Health Chips
    var chipSleep: String       { l("Sleep", "睡眠") }
    var chipRecovery: String    { l("Recovery", "回復") }
    var chipActivity: String    { l("Activity", "活動") }
    var chipCalm: String        { l("Calm", "穏やかさ") }

    var sleepGood: String       { l("Well rested", "よく眠れた") }
    var sleepBad: String        { l("Light sleep", "浅い眠り") }
    var sleepNeutral: String    { l("Steady", "ふつう") }

    var recoveryGood: String    { l("Balanced", "バランス良好") }
    var recoveryBad: String     { l("Recovering", "回復中") }
    var recoveryNeutral: String { l("Moderate", "ふつう") }

    var activityGood: String    { l("Active day", "活発な日") }
    var activityBad: String     { l("Quiet day", "静かな日") }
    var activityNeutral: String { l("Light", "軽め") }

    var calmGood: String        { l("Present", "穏やか") }
    var calmBad: String         { l("Rushed", "忙しい") }
    var calmNeutral: String     { l("Grounded", "落ち着き") }

    // MARK: Premium
    var premiumTitle: String            { l("Vital Canvas Premium", "Vital Canvas プレミアム") }
    var premiumTagline: String          { l("Deepen your practice.\nExpand your gallery.", "体験を深める。\nギャラリーを広げる。") }
    var premiumCTA: String              { l("Start Free Trial", "無料トライアルを開始") }
    var premiumRestore: String          { l("Restore purchases", "購入を復元") }
    var premiumFooter: String           { l("Cancel anytime. Prices shown in USD.", "いつでもキャンセル可能。価格はUSD表示。") }
    var premiumMonthly: String          { l("Monthly", "月額") }
    var premiumYearly: String           { l("Yearly", "年額") }
    var premiumYearlyPeriod: String     { l("per year  ·  save 37%", "年間  ·  37%お得") }
    var premiumMonthlyPeriod: String    { l("per month", "月額") }
    var premiumBestValue: String        { l("Best value", "お得") }

    var premiumFeat1Title: String   { l("Monthly master canvas", "マスターキャンバス") }
    var premiumFeat1Desc: String    { l("A unique high-resolution artwork generated for each month", "毎月生成される特別な高解像度アートワーク") }
    var premiumFeat2Title: String   { l("More art styles", "アートスタイル追加") }
    var premiumFeat2Desc: String    { l("New visual styles added seasonally", "季節ごとに追加される新しいビジュアルスタイル") }
    var premiumFeat3Title: String   { l("High-resolution export", "高解像度書き出し") }
    var premiumFeat3Desc: String    { l("Export your canvases at full 2048×2048 resolution", "2048×2048の最大解像度でキャンバスを書き出し") }
    var premiumFeat4Title: String   { l("Comparison views", "比較ビュー") }
    var premiumFeat4Desc: String    { l("See how your health rhythm evolves over time", "健康リズムの変化を時間軸で振り返る") }
    var premiumFeat5Title: String   { l("Widgets", "ウィジェット") }
    var premiumFeat5Desc: String    { l("Bring your daily canvas to your home screen", "今日のキャンバスをホーム画面に表示") }
    var premiumFeat6Title: String   { l("Time-lapse gallery", "タイムラプスギャラリー") }
    var premiumFeat6Desc: String    { l("Watch your year of health unfold as living art", "1年間の健康をアートとして振り返る") }

    // MARK: Settings
    var settingsTitle: String           { l("Settings", "設定") }
    var settingsHealthSection: String   { l("Health Data", "ヘルスデータ") }
    var settingsHealthStatus: String    { l("Apple Health", "Apple Health") }
    var settingsHealthConnected: String { l("Connected", "連携済み") }
    var settingsHealthUnavail: String   { l("Not available on this device", "このデバイスでは利用できません") }
    var settingsHealthActive: String    { l("Active", "有効") }
    var settingsHealthInactive: String  { l("Inactive", "無効") }
    var settingsNotifSection: String    { l("Notifications", "通知") }
    var settingsMorning: String         { l("Morning reminder", "朝のリマインダー") }
    var settingsMorningDesc: String     { l("Your new canvas is ready", "新しいキャンバスが準備できました") }
    var settingsWeekly: String          { l("Weekly summary", "週のサマリー") }
    var settingsWeeklyDesc: String      { l("Your week's gallery is complete", "今週のギャラリーが完成しました") }
    var settingsPremiumSection: String  { l("Premium", "プレミアム") }
    var settingsPremiumDesc: String     { l("More styles, high-res export & more", "スタイル追加・高解像度書き出しなど") }
    var settingsPrivacySection: String  { l("Privacy & Legal", "プライバシーと法的情報") }
    var settingsPrivacyPolicy: String   { l("Privacy Policy", "プライバシーポリシー") }
    var settingsLanguage: String        { l("Language", "言語") }
    var settingsVersion: String         { "Vital Canvas · v1.0" }
}
