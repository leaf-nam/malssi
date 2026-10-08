import ActivityKit
import SwiftUI
import WidgetKit

// 성장 Live Activity 화면 (#248).
// 데이터는 `live_activities` 플러그인이 App Group UserDefaults에
// "<activity-uuid>_<key>" 형태로 저장한다. Dart 측은
// `LiveActivityService`가 quote_text/stage/complete_at을 보낸다.

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
    let quote: String
    let stage: Int
    let completeAt: Date?

    static func load(attributes: LiveActivitiesAppAttributes) -> LiveSnapshot {
        let store = UserDefaults(suiteName: liveAppGroupId)
        let quote = store?.string(forKey: attributes.prefixedKey("quote_text")) ?? ""
        let stage = store?.integer(forKey: attributes.prefixedKey("stage")) ?? 0
        let millis = store?.double(forKey: attributes.prefixedKey("complete_at")) ?? 0
        return LiveSnapshot(
            quote: quote,
            stage: stage,
            completeAt: millis > 0 ? Date(timeIntervalSince1970: millis / 1000) : nil
        )
    }
}

@available(iOS 16.1, *)
struct MalssiGrowthActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            let snapshot = LiveSnapshot.load(attributes: context.attributes)
            // 잠금화면 배너: 명언 + 단계 + 실시간 카운트다운.
            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.quote)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("🌱 \(snapshot.stage)단계")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(red: 0.85, green: 0.66, blue: 0.31))
                    if let end = snapshot.completeAt, end > Date() {
                        Text(timerInterval: Date()...end, countsDown: true)
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                            .monospacedDigit()
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.16, green: 0.14, blue: 0.22))
            .widgetURL(URL(string: "malssi://widget?target=seed"))
        } dynamicIsland: { context in
            let snapshot = LiveSnapshot.load(attributes: context.attributes)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("🌱 \(snapshot.stage)단계")
                        .font(.system(size: 13, weight: .semibold))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let end = snapshot.completeAt, end > Date() {
                        Text(timerInterval: Date()...end, countsDown: true)
                            .font(.system(size: 13))
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(snapshot.quote)
                        .font(.system(size: 13))
                        .lineLimit(1)
                }
            } compactLeading: {
                Text("🌱\(snapshot.stage)")
                    .font(.system(size: 12, weight: .semibold))
            } compactTrailing: {
                if let end = snapshot.completeAt, end > Date() {
                    Text(timerInterval: Date()...end, countsDown: true)
                        .font(.system(size: 12))
                        .monospacedDigit()
                        .frame(width: 44)
                }
            } minimal: {
                Text("🌱")
            }
        }
    }
}
