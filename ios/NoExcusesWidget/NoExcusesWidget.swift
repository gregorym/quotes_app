import SwiftUI
import WidgetKit

private struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: String
}

private struct QuoteProvider: TimelineProvider {
    private static let fallback = "You don't need more time. You need more discipline."
    private static let quotes: [String] = {
        guard
            let url = Bundle.main.url(forResource: "db", withExtension: "txt"),
            let data = try? Data(contentsOf: url),
            let source = String(data: data, encoding: .utf8)
        else { return [] }

        return source.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }()

    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: Self.fallback)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        completion(entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.autoupdatingCurrent
        let start = calendar.startOfDay(for: now)
        let futureEntries = (1...31).compactMap { offset -> QuoteEntry? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else {
                return nil
            }
            return entry(for: date, calendar: calendar)
        }

        let entries = [entry(for: now, calendar: calendar)] + futureEntries
#if DEBUG
        assert(entries.count == 32 && entries[0].quote != entries[1].quote)
#endif
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(for date: Date, calendar: Calendar = .autoupdatingCurrent) -> QuoteEntry {
        guard !Self.quotes.isEmpty else {
            return QuoteEntry(date: date, quote: Self.fallback)
        }

        let start = calendar.startOfDay(for: date)
        let reference = calendar.date(from: DateComponents(year: 2001, month: 1, day: 1)) ?? start
        let day = calendar.dateComponents([.day], from: reference, to: start).day ?? 0
        let index = (day % Self.quotes.count + Self.quotes.count) % Self.quotes.count
        return QuoteEntry(date: date, quote: Self.quotes[index])
    }
}

private struct QuoteWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: QuoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NO EXCUSES")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .kerning(1.4)
                .foregroundColor(.white.opacity(0.65))

            Spacer(minLength: 0)

            Text(entry.quote)
                .font(.system(
                    size: family == .systemSmall ? 17 : 22,
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundColor(.white)
                .lineLimit(family == .systemSmall ? 6 : 4)
                .minimumScaleFactor(0.72)

            Spacer(minLength: 0)

            Text("TODAY")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(family == .systemSmall ? 15 : 20)
        .widgetBackground {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.06, blue: 0.04), Color(red: 0.33, green: 0.22, blue: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("No Excuses daily quote: \(entry.quote)")
    }
}

private extension View {
    @ViewBuilder
    func widgetBackground<Background: View>(
        @ViewBuilder _ background: () -> Background
    ) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget, content: background)
        } else {
            self.background(background())
        }
    }
}

@main
struct NoExcusesWidget: Widget {
    let kind = "NoExcusesDailyQuote"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuoteWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily No Excuses")
        .description("A direct quote that changes every day.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
