import SwiftUI
import WidgetKit

@main
struct MalssiWidgetBundle: WidgetBundle {
    var body: some Widget {
        MalssiWidget()
        if #available(iOS 16.1, *) {
            MalssiGrowthActivity()
        }
    }
}
