import SwiftUI
import WidgetKit

// 홈 위젯: 오늘의 명언 + 저자 + 성장 상태 (#139, #242).
// 데이터는 App Group UserDefaults로 Flutter와 공유한다.
// 잠금화면 위젯(accessoryRectangular)도 지원한다 (#242).

private let appGroupId = "group.com.leaf.malssi"
private let quoteKey = "quote_text"
private let authorKey = "quote_author"
private let statusKey = "seed_status"
private let stageKey = "growth_stage"
private let dateKey = "seed_date"
private let nextStageAtKey = "next_stage_at"
private let completeAtKey = "complete_at"
private let placeholderText = "씨앗을 심으면 오늘의 명언이 보여요"
private let placeholderAuthor = "malssi"
private let clickUrl = "malssi://widget?target=seed"

private let isoFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

/// 남은 초를 한글 문구로 바꾼다 ("약 1시간 20분" / "약 5분" / "곧").
private func remainingText(until iso: String, prefix: String) -> String? {
    guard !iso.isEmpty, let target = isoFormatter.date(from: iso) else { return nil }
    let seconds = Int(target.timeIntervalSinceNow)
    guard seconds > 0 else { return nil }
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let amount: String
    if hours > 0, minutes > 0 {
        amount = "약 \(hours)시간 \(minutes)분"
    } else if hours > 0 {
        amount = "약 \(hours)시간"
    } else if minutes > 0 {
        amount = "약 \(minutes)분"
    } else {
        amount = "곧"
    }
    return "\(prefix)까지 \(amount)"
}

struct QuoteEntry: TimelineEntry {
    let date: Date
    let text: String
    let author: String
    let status: String
    let stage: Int
    let countdown: String?
}

struct QuoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), text: placeholderText, author: placeholderAuthor,
                   status: "locked", stage: 0, countdown: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        completion(loadQuote())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let entry = loadQuote()
        // 다음 단계 시각과 30분 중 빠른 쪽에 갱신해 남은시간을 تازه 유지한다.
        // Flutter도 단계·상태가 바뀔 때마다 갱신을 요청한다.
        var next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        // 지난 시각은 제외한다 (오래된 데이터로 갱신 루프 방지).
        if let iso = UserDefaults(suiteName: appGroupId)?.string(forKey: nextStageAtKey),
           !iso.isEmpty, let stageDate = isoFormatter.date(from: iso),
           stageDate > Date(), stageDate < next {
            next = stageDate
        }
        // 자정에도 갱신해 날짜가 바뀌면 오래된 표시를 걷어낸다 (#242 후속).
        // 앱이 안 열려 새 데이터가 없어도 플레이스홀더로 돌아간다.
        if let midnight = Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 0, minute: 0),
                                                    matchingPolicy: .nextTime),
           midnight < next {
            next = midnight
        }
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadQuote() -> QuoteEntry {
        let store = UserDefaults(suiteName: appGroupId)
        // 날짜가 바뀌고 앱이 아직 안 열렸으면 오래된 데이터로 보고
        // 플레이스홀더를 보여준다 (#242 후속: 전날 명언·완료 고착 방지).
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let seedDate = store?.string(forKey: dateKey) ?? ""
        if seedDate.isEmpty || seedDate != today {
            return QuoteEntry(date: Date(), text: placeholderText, author: placeholderAuthor,
                              status: "locked", stage: 0, countdown: nil)
        }
        let status = store?.string(forKey: statusKey) ?? "locked"
        let stage = store?.integer(forKey: stageKey) ?? 0
        var parts: [String] = []
        if status == "growing" {
            if let line = remainingText(until: store?.string(forKey: nextStageAtKey) ?? "",
                                        prefix: "다음 단계") {
                parts.append(line)
            }
            if let line = remainingText(until: store?.string(forKey: completeAtKey) ?? "",
                                        prefix: "완성") {
                parts.append(line)
            }
        }
        return QuoteEntry(
            date: Date(),
            text: store?.string(forKey: quoteKey) ?? placeholderText,
            author: store?.string(forKey: authorKey) ?? placeholderAuthor,
            status: status,
            stage: stage,
            countdown: parts.isEmpty ? nil : parts.joined(separator: " · ")
        )
    }
}

struct MalssiWidgetEntryView: View {
    var entry: QuoteProvider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        // 말씨 다크 톤 (#59). 탭하면 말씨 탭으로 이동한다.
        if let url = URL(string: clickUrl) {
            Link(destination: url) {
                bodyContent
            }
        } else {
            bodyContent
        }
    }

    @ViewBuilder
    private var bodyContent: some View {
        // 잠금화면 위젯은 한눈 문구만 보여준다 (#242).
        if family == .accessoryRectangular {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.text)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(accessoryLine)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        } else {
            quoteBody
        }
    }

    private var accessoryLine: String {
        switch entry.status {
        case "complete":
            return "🎉 수확 완료"
        case "growing":
            if let countdown = entry.countdown {
                return "🌱 \(entry.stage)단계 · \(countdown)"
            }
            return "🌱 자라는 중 · \(entry.stage)단계"
        default:
            return "씨앗을 심어보세요"
        }
    }

    private var quoteBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(3)
            Text("— \(entry.author)")
                .font(.system(size: 12))
                .foregroundStyle(.gray)
                .lineLimit(1)
            if entry.status == "complete" {
                Text("🎉 수확 완료")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(red: 0.85, green: 0.66, blue: 0.31))
                    .lineLimit(1)
            } else if entry.status == "growing" {
                Text("🌱 자라는 중 · \(entry.stage)단계")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(red: 0.85, green: 0.66, blue: 0.31))
                    .lineLimit(1)
                if let countdown = entry.countdown {
                    Text(countdown)
                        .font(.system(size: 11))
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                }
            }
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
        .description("오늘의 명언과 씨앗 성장 상태를 보여줍니다.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
