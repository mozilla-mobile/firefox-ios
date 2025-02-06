// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WidgetKit
import ActivityKit
import SwiftUI

struct LiveDownloadWidgetAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let placeholder: String
    }
    let test: Int
}

@available(iOS 16.1, *)
struct LiveDownloadWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveDownloadWidgetAttributes.self) { _ in
            ZStack {
                Color.black
            }
            .frame(height: 100)
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
