import AppIntents
import SwiftUI
import WidgetKit

private struct VachanamrutQuote: Decodable {
  let reference: String
  let title: String
  let quote: String
  let meaning: String
}

private struct MukhpathItem: Decodable {
  let id: String
  let question: String
  let answer: String
}

private struct WidgetContent {
  let kicker: String
  let body: String
  let footer: String
  let canToggleMeaning: Bool
}

private struct VachanamrutEntry: TimelineEntry {
  let date: Date
  let content: WidgetContent
}

private struct VachanamrutProvider: TimelineProvider {
  func placeholder(in context: Context) -> VachanamrutEntry {
    VachanamrutEntry(
      date: Date(),
      content: WidgetState.previewContent
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (VachanamrutEntry) -> Void) {
    let state = WidgetState.load()
    completion(
      VachanamrutEntry(
        date: Date(),
        content: state.content(for: Date())
      )
    )
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<VachanamrutEntry>) -> Void) {
    let now = Date()
    let state = WidgetState.load()
    let entry = VachanamrutEntry(
      date: now,
      content: state.content(for: now)
    )

    completion(Timeline(entries: [entry], policy: .after(state.nextRefreshDate(after: now))))
  }
}

private struct VachanamrutWidgetView: View {
  let entry: VachanamrutEntry

  var body: some View {
    if #available(iOSApplicationExtension 17.0, *), entry.content.canToggleMeaning {
      Button(intent: ToggleMeaningIntent()) {
        widgetContent
      }
      .buttonStyle(.plain)
      .accessibilityLabel(
        WidgetState.showMeaning
          ? "Show Gujarati quote"
          : "Show English meaning"
      )
    } else {
      widgetContent
    }
  }

  private var widgetContent: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(entry.content.kicker)
        .font(.caption.weight(.bold))
        .foregroundColor(Color(red: 0.54, green: 0.29, blue: 0.07))
        .lineLimit(1)

      Text(entry.content.body)
        .font(.headline.weight(.bold))
        .foregroundColor(Color(red: 0.18, green: 0.14, blue: 0.11))
        .lineLimit(6)
        .minimumScaleFactor(0.72)

      Spacer(minLength: 0)

      Text(entry.content.footer)
        .font(.caption.weight(.semibold))
        .foregroundColor(Color(red: 0.49, green: 0.44, blue: 0.40))
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .contentShape(Rectangle())
    .padding()
    .widgetCardBackground()
  }
}

@available(iOSApplicationExtension 17.0, *)
struct ToggleMeaningIntent: AppIntent {
  static var title: LocalizedStringResource = "Flip Vachanamrut Widget"
  static var isDiscoverable = false
  static var openAppWhenRun = false

  func perform() async throws -> some IntentResult {
    WidgetState.toggleMeaning()
    WidgetCenter.shared.reloadTimelines(ofKind: "VachanamrutDailyWidget")
    return .result()
  }
}

private struct WidgetState {
  private static let appGroupIdentifier = "group.com.example.vachanamrutApp"
  private static let showMeaningKey = "showMeaning"

  let appMode: String
  let widgetContentMode: String
  let language: String
  let quoteIntervalMinutes: Int
  let mukhpathIntervalMinutes: Int
  let completedMukhpathIds: Set<String>
  let quotes: [VachanamrutQuote]
  let mukhpathItems: [MukhpathItem]

  static let previewContent = WidgetContent(
    kicker: "Quote 1",
    body: "This body has been received for devotion to God.",
    footer: "Tap to see meaning",
    canToggleMeaning: true
  )

  static var showMeaning: Bool {
    get {
      defaults.bool(forKey: showMeaningKey)
    }
    set {
      defaults.set(newValue, forKey: showMeaningKey)
    }
  }

  static func toggleMeaning() {
    showMeaning.toggle()
  }

  static func load() -> WidgetState {
    WidgetState(
      appMode: defaults.string(forKey: "appMode") ?? "vachanamrut",
      widgetContentMode: defaults.string(forKey: "widgetContentMode") ?? "vachanamrut",
      language: defaults.string(forKey: "language") ?? "gujarati",
      quoteIntervalMinutes: max(defaults.integer(forKey: "quoteIntervalMinutes"), 1),
      mukhpathIntervalMinutes: max(defaults.integer(forKey: "mukhpathIntervalMinutes"), 1),
      completedMukhpathIds: Set(defaults.stringArray(forKey: "completedMukhpathIds") ?? []),
      quotes: loadQuotes(),
      mukhpathItems: loadMukhpathItems()
    )
  }

  func content(for date: Date) -> WidgetContent {
    if widgetContentMode == "mukhpath" {
      return mukhpathContent(for: date)
    }
    return quoteContent(for: date)
  }

  func nextRefreshDate(after date: Date) -> Date {
    let intervalMinutes = widgetContentMode == "mukhpath"
      ? mukhpathIntervalMinutes
      : quoteIntervalMinutes
    let intervalSeconds = TimeInterval(max(intervalMinutes, 1) * 60)
    let nextBoundary = (floor(date.timeIntervalSince1970 / intervalSeconds) + 1) * intervalSeconds
    return Date(timeIntervalSince1970: nextBoundary)
  }

  private func quoteContent(for date: Date) -> WidgetContent {
    let quote = quotes.item(for: date, intervalMinutes: quoteIntervalMinutes) ?? Self.fallbackQuote

    switch language {
    case "english":
      return WidgetContent(
        kicker: "English Meaning",
        body: quote.meaning,
        footer: "English preview",
        canToggleMeaning: false
      )
    case "gujaratiWithEnglish":
      return WidgetContent(
        kicker: quote.reference,
        body: "\(quote.quote)\n\n\(quote.meaning)",
        footer: "Gujarati + English",
        canToggleMeaning: false
      )
    default:
      return WidgetContent(
        kicker: showMeaning ? "English Meaning" : quote.reference,
        body: showMeaning ? quote.meaning : quote.quote,
        footer: showMeaning ? "Tap to return to Gujarati" : "Tap to see meaning",
        canToggleMeaning: true
      )
    }
  }

  private func mukhpathContent(for date: Date) -> WidgetContent {
    let visibleItems = mukhpathItems.filter { !completedMukhpathIds.contains($0.id) }
    let item = visibleItems.item(for: date, intervalMinutes: mukhpathIntervalMinutes)
    return WidgetContent(
      kicker: "Mukhpath",
      body: item?.question ?? "No Mukhpath items available.",
      footer: item?.answer ?? "",
      canToggleMeaning: false
    )
  }

  private static var defaults: UserDefaults {
    UserDefaults(suiteName: appGroupIdentifier) ?? .standard
  }

  private static let fallbackQuote = VachanamrutQuote(
    reference: "Quote 1",
    title: "Devotion to God",
    quote: "This body has been received for devotion to God.",
    meaning: "This body has been received for devotion to God."
  )

  private static func loadQuotes() -> [VachanamrutQuote] {
    if let quotesJson = defaults.string(forKey: "quotesJson"),
       let data = quotesJson.data(using: .utf8),
       let quotes = try? JSONDecoder().decode([VachanamrutQuote].self, from: data),
       !quotes.isEmpty {
      return quotes
    }

    guard let url = Bundle.main.url(
      forResource: "vachanamrut_quotes",
      withExtension: "json"
    ) else {
      return [fallbackQuote]
    }

    do {
      let data = try Data(contentsOf: url)
      return try JSONDecoder().decode([VachanamrutQuote].self, from: data)
    } catch {
      return [fallbackQuote]
    }
  }

  private static func loadMukhpathItems() -> [MukhpathItem] {
    guard let mukhpathJson = defaults.string(forKey: "mukhpathJson"),
          let data = mukhpathJson.data(using: .utf8),
          let items = try? JSONDecoder().decode([MukhpathItem].self, from: data) else {
      return []
    }
    return items
  }
}

@main
struct VachanamrutDailyWidget: Widget {
  let kind = "VachanamrutDailyWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: VachanamrutProvider()) { entry in
      VachanamrutWidgetView(entry: entry)
    }
    .configurationDisplayName("Vachanamrut Daily")
    .description("Hourly Vachanamrut quotes for your home screen.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

private extension Array where Element == VachanamrutQuote {
  func item(for date: Date, intervalMinutes: Int) -> VachanamrutQuote? {
    guard !isEmpty else {
      return nil
    }

    let intervalSeconds = TimeInterval(max(intervalMinutes, 1) * 60)
    let index = Int(date.timeIntervalSince1970 / intervalSeconds) % count
    return self[index]
  }
}

private extension Array where Element == MukhpathItem {
  func item(for date: Date, intervalMinutes: Int) -> MukhpathItem? {
    guard !isEmpty else {
      return nil
    }

    let intervalSeconds = TimeInterval(max(intervalMinutes, 1) * 60)
    let index = Int(date.timeIntervalSince1970 / intervalSeconds) % count
    return self[index]
  }
}

private extension View {
  @ViewBuilder
  func widgetCardBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) {
        Color(red: 1.0, green: 0.96, blue: 0.92)
      }
    } else {
      background(Color(red: 1.0, green: 0.96, blue: 0.92))
    }
  }
}
