import WidgetKit
import SwiftUI

@main
struct TotsWidgetBundle: WidgetBundle {
    var body: some Widget {
        TotsSummaryWidget()
        TotsLiveActivity()
    }
}