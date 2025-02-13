// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WidgetKit
import ActivityKit
import SwiftUI

struct DownloadLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
    }
}

@available(iOS 16.2, *)
struct DownloadLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DownloadLiveActivityAttributes.self) { _ in
            EmptyView()
        } dynamicIsland: { _ in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.leading) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    EmptyView()
                }
            } compactLeading: {
                EmptyView()
            } compactTrailing: {
                EmptyView()
            } minimal: {
                EmptyView()
            }
        }
   }
}
