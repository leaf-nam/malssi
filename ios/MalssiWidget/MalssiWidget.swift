import SwiftUI
import WidgetKit

// 홈 위젯: 오늘의 명언 + 저자 (#139).
// 데이터는 App Group UserDefaults로 Flutter와 공유한다.

private let appGroupId = "group.com.leaf.malssi"
private let quoteKey = "quote_text"
private let authorKey = "quote_author"
private let placeholderText = "씨앗을 심으면 오늘의 명언이 보여요"
private let placeholderAuthor = "malssi"
private let clickUrl = "malssi://widget?target=seed"

struct QuoteEntry: TimelineEntry {
    let date: Date
    let text: String
    let author: String
}

struct QuoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), text: placeholderText, author: placeholderAuthor)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        completion(loadQuote())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        // Flutter가 바뀔 때마다 갱신을 요청하므로, 타임라인은 6시간 뒤 1회만 예약한다.
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date()
        completion(Timeline(entries: [loadQuote()], policy: .after(next)))
    }

    private func loadQuote() -> QuoteEntry {
        let store = UserDefaults(suiteName: appGroupId)
        return QuoteEntry(
            date: Date(),
            text: store?.string(forKey: quoteKey) ?? placeholderText,
            author: store?.string(forKey: authorKey) ?? placeholderAuthor
        )
    }
}

struct MalssiWidgetEntryView: View {
    var entry: QuoteProvider.Entry

    var body: some View {
        // 말씨 다크 톤 (#59). 탭하면 말씨 탭으로 이동한다.
        if let url = URL(string: clickUrl) {
            Link(destination: url) {
                quoteBody
            }
        } else {
            quoteBody
        }
    }

    private var quoteBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(4)
            Text("— \(entry.author)")
                .font(.system(size: 12))
                .foregroundStyle(.gray)
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.16, green: 0.14, blue: 0.22))
    }
}

struct MalssiWidget: Widget {
    let kind = "MalssiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            MalssiWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("오늘의 말씨")
        .description("오늘의 명언을 보여줍니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
