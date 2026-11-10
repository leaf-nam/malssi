import ActivityKit
import SwiftUI
import WidgetKit

// 성장 Live Activity 화면 (#248, #266~#268).
// 데이터는 `live_activities` 플러그인이 App Group UserDefaults에
// "<activity-uuid>_<key>" 형태로 저장한다. Dart 측은
// `LiveActivityService`가 quote_text/stage/status/theme_label/fruit_emoji/
// planted_at/complete_at을 보낸다.
//
// 긴 명언 대신 이번 씨앗 종류와 확인 안내를 보여주고 (#266),
// 단계는 planted_at 기준 경과 시간으로 네이티브에서 계산해 앱이 꺼져 있어도
// 2시간마다 갱신된다 (#267). 완성 후에는 열매를 보여준다 (#268).

// 플러그인과 동일한 Attributes 정의 (확장 타깃에 재정의 필요).
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState

    public struct ContentState: Codable, Hashable { }

    var id = UUID()
}

extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String {
        return "\(id)_\(key)"
    }
}

private let liveAppGroupId = "group.com.leaf.malssi"

private struct LiveSnapshot {
    let status: String
    let stage: Int
    let themeLabel: String
    let fruitEmoji: String
    let plantedAt: Date?
    let completeAt: Date?

    static func load(attributes: LiveActivitiesAppAttributes) -> LiveSnapshot {
        let store = UserDefaults(suiteName: liveAppGroupId)
        let status = store?.string(forKey: attributes.prefixedKey("status")) ?? "growing"
        let stage = store?.integer(forKey: attributes.prefixedKey("stage")) ?? 0
        let theme = store?.string(forKey: attributes.prefixedKey("theme_label")) ?? ""
        let emoji = store?.string(forKey: attributes.prefixedKey("fruit_emoji")) ?? "🌱"
        let plantedMillis = store?.double(forKey: attributes.prefixedKey("planted_at")) ?? 0
        let completeMillis = store?.double(forKey: attributes.prefixedKey("complete_at")) ?? 0
        return LiveSnapshot(
            status: status,
            stage: stage,
            themeLabel: theme.isEmpty ? "오늘의 씨앗" : theme,
            fruitEmoji: emoji,
            plantedAt: plantedMillis > 0
                ? Date(timeIntervalSince1970: plantedMillis / 1000) : nil,
            completeAt: completeMillis > 0
                ? Date(timeIntervalSince1970: completeMillis / 1000) : nil
        )
    }

    /// 심은 시각 기준 현재 단계 (0~5). 완성 시각이 지났으면 5.
    func currentStage(at date: Date) -> Int {
        if status == "complete" { return 5 }
        if let end = completeAt, date >= end { return 5 }
        guard let planted = plantedAt else { return stage }
        let elapsed = max(0, date.timeIntervalSince(planted))
        return min(5, Int(elapsed / (2 * 60 * 60)))
    }

    func isComplete(at date: Date) -> Bool {
        status == "complete" || currentStage(at: date) >= 5
    }

    /// 씨앗/열매 이름. 예: `딸기 씨앗`, `딸기 열매`.
    func title(at date: Date) -> String {
        isComplete(at: date)
            ? "\(fruitEmoji) \(themeLabel) 열매"
            : "🌱 \(themeLabel) 씨앗"
    }

    /// 확인 안내 문구.
    func hint(at date: Date) -> String {
        isComplete(at: date)
            ? "말씨에서 열매를 확인하세요"
            : "말씨에서 씨앗을 확인하세요"
    }
}

private let goldColor = Color(red: 0.85, green: 0.66, blue: 0.31)
private let liveBackground = Color(red: 0.16, green: 0.14, blue: 0.22)

/// 잠금화면 배너: 씨앗 종류 + 단계 + 남은 시간/완료 문구.
private struct LiveBanner: View {
    let snapshot: LiveSnapshot

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let complete = snapshot.isComplete(at: context.date)
            let stage = snapshot.currentStage(at: context.date)
            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.title(at: context.date))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 6) {
                    Text(complete ? "열매가 완성됐어요" : "\(stage)단계")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(goldColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if !complete, let end = snapshot.completeAt, end > context.date {
                        Text(timerInterval: context.date...end, countsDown: true)
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                            .monospacedDigit()
                    }
                }
                Text(snapshot.hint(at: context.date))
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(liveBackground)
        }
    }
}

/// 다이나믹 아일랜드 좌측: 이번 씨앗 종류 또는 완성 열매.
private struct IslandTitle: View {
    let snapshot: LiveSnapshot

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            Text(snapshot.title(at: context.date))
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

/// 다이나믹 아일랜드 우측: 단계 또는 남은 시간.
private struct IslandCountdown: View {
    let snapshot: LiveSnapshot

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            if snapshot.isComplete(at: context.date) {
                Text("완료")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(goldColor)
            } else if let end = snapshot.completeAt, end > context.date {
                Text(timerInterval: context.date...end, countsDown: true)
                    .font(.system(size: 13))
                    .monospacedDigit()
            } else {
                Text("곧")
                    .font(.system(size: 13))
            }
        }
    }
}

/// 컴팩트 좌측: 성장 중 단계, 완성 후 열매 이모지.
private struct CompactLeading: View {
    let snapshot: LiveSnapshot

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            Text(snapshot.isComplete(at: context.date)
                ? snapshot.fruitEmoji
                : "🌱\(snapshot.currentStage(at: context.date))")
                .font(.system(size: 12, weight: .semibold))
        }
    }
}

/// 컴팩트 우측: 남은 시간 또는 완료 표시.
private struct CompactTrailing: View {
    let snapshot: LiveSnapshot

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            if snapshot.isComplete(at: context.date) {
                Text("완료")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(goldColor)
            } else if let end = snapshot.completeAt, end > context.date {
                Text(timerInterval: context.date...end, countsDown: true)
                    .font(.system(size: 12))
                    .monospacedDigit()
                    .frame(width: 44)
            } else {
                Text("곧")
                    .font(.system(size: 12))
                    .frame(width: 44)
            }
        }
    }
}

@available(iOS 16.1, *)
struct MalssiGrowthActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            let snapshot = LiveSnapshot.load(attributes: context.attributes)
            LiveBanner(snapshot: snapshot)
                .widgetURL(URL(string: "malssi://widget?target=seed"))
        } dynamicIsland: { context in
            let snapshot = LiveSnapshot.load(attributes: context.attributes)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    IslandTitle(snapshot: snapshot)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    IslandCountdown(snapshot: snapshot)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    TimelineView(.periodic(from: .now, by: 60)) { timeline in
                        Text(snapshot.hint(at: timeline.date))
                            .font(.system(size: 13))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            } compactLeading: {
                CompactLeading(snapshot: snapshot)
            } compactTrailing: {
                CompactTrailing(snapshot: snapshot)
            } minimal: {
                TimelineView(.periodic(from: .now, by: 60)) { timeline in
                    Text(snapshot.isComplete(at: timeline.date)
                        ? snapshot.fruitEmoji
                        : "🌱")
                }
            }
        }
    }
}
