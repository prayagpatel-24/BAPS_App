import AppIntents
import SwiftUI
import WidgetKit

private struct VachanamrutQuote: Decodable {
  let reference: String
  let title: String
  let quote: String
  let meaning: String
}

private struct QuoteEntry: TimelineEntry {
  let date: Date
  let quote: VachanamrutQuote
  let showMeaning: Bool
}

private struct QuoteProvider: TimelineProvider {
  func placeholder(in context: Context) -> QuoteEntry {
    QuoteEntry(
      date: Date(),
      quote: QuoteRepository.fallbackQuote,
      showMeaning: WidgetState.showMeaning
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
    completion(
      QuoteEntry(
        date: Date(),
        quote: QuoteRepository.quoteForNow(),
        showMeaning: WidgetState.showMeaning
      )
    )
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
    let now = Date()
    let entry = QuoteEntry(
      date: now,
      quote: QuoteRepository.quote(for: now),
      showMeaning: WidgetState.showMeaning
    )
    let nextHour = Calendar.current.nextDate(
      after: now,
      matching: DateComponents(minute: 0, second: 0),
      matchingPolicy: .nextTime
    ) ?? now.addingTimeInterval(60 * 60)

    completion(Timeline(entries: [entry], policy: .after(nextHour)))
  }
}

private struct VachanamrutWidgetView: View {
  let entry: QuoteEntry

  var body: some View {
    if #available(iOSApplicationExtension 17.0, *) {
      Button(intent: ToggleMeaningIntent()) {
        widgetContent
      }
      .buttonStyle(.plain)
      .accessibilityLabel(
        entry.showMeaning
          ? "Show Gujarati quote"
          : "Show English meaning"
      )
    } else {
      widgetContent
    }
  }

  private var widgetContent: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(entry.showMeaning ? "English Meaning" : entry.quote.reference)
        .font(.caption.weight(.bold))
        .foregroundColor(Color(red: 0.54, green: 0.29, blue: 0.07))
        .lineLimit(1)

      Text(entry.showMeaning ? entry.quote.meaning : entry.quote.quote)
        .font(.headline.weight(.bold))
        .foregroundColor(Color(red: 0.18, green: 0.14, blue: 0.11))
        .lineLimit(6)
        .minimumScaleFactor(0.72)

      Spacer(minLength: 0)

      Text(entry.showMeaning ? "Tap to return to Gujarati" : "Tap to see meaning")
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

private enum WidgetState {
  private static let showMeaningKey = "showMeaning"

  static var showMeaning: Bool {
    get {
      UserDefaults.standard.bool(forKey: showMeaningKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: showMeaningKey)
    }
  }

  static func toggleMeaning() {
    showMeaning.toggle()
  }
}

@main
struct VachanamrutDailyWidget: Widget {
  let kind = "VachanamrutDailyWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
      VachanamrutWidgetView(entry: entry)
    }
    .configurationDisplayName("Vachanamrut Daily")
    .description("Hourly Vachanamrut quotes for your home screen.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

private enum QuoteRepository {
  static let fallbackQuote = VachanamrutQuote(
    reference: "Quote 1",
    title: "Devotion to God",
    quote: "This body has been received for devotion to God.",
    meaning: "This body has been received for devotion to God."
  )

  static func quoteForNow() -> VachanamrutQuote {
    quote(for: Date())
  }

  static func quote(for date: Date) -> VachanamrutQuote {
    let quotes = loadQuotes()
    guard !quotes.isEmpty else {
      return fallbackQuote
    }

    let intervalIndex = Int(date.timeIntervalSince1970 / (60 * 60))
    return quotes[intervalIndex % quotes.count]
  }

  private static func loadQuotes() -> [VachanamrutQuote] {
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
