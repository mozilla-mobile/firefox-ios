// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WidgetKit
import ActivityKit
import SwiftUI
import Foundation

struct DownloadLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        struct Download: Codable, Hashable {
            var id: UUID
            var fileName: String
            var hasContentEncoding: Bool?

            var totalBytesExpected: Int64?
            var bytesDownloaded: Int64
            var isComplete: Bool
        }
        var downloads: [Download]

        var completedDownloads: Int {
            downloads.filter { $0.isComplete }.count
        }

        var totalDownloads: Int {
            downloads.count
        }

        var totalBytesDownloaded: Int64 {
            // we ignore bytes downloaded for downloads without bytes expected to ensure we don't report invalid progress
            // to the user (i.e. 50MB of 20MB downloaded).
            downloads
                .filter { $0.hasContentEncoding == false && $0.totalBytesExpected != nil }
                .compactMap { $0.bytesDownloaded }
                .reduce(0, +)
        }

        var totalBytesExpected: Int64 {
            downloads
                .filter { $0.hasContentEncoding == false }
                .compactMap { $0.totalBytesExpected }
                .reduce(0, +)
        }

        var totalProgress: Double {
            totalBytesExpected == 0 ? 0 : Double(totalBytesDownloaded) / Double(totalBytesExpected)
        }
    }
}

@available(iOS 16.2, *)
struct DownloadLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DownloadLiveActivityAttributes.self) { context in
            let context: ActivityViewContext<DownloadLiveActivityAttributes>
            // Using Rectangle instead of EmptyView because the hitbox
            // of the empty view is too small (likely non existent),
            // meaning we'd never be redirected to the downloads panel
            Rectangle()
                .widgetURL(URL(string: URL.mozInternalScheme + "://deep-link?url=/homepanel/downloads"))
        } dynamicIsland: { context in
            DynamicIsland {
                expandedContent(context: context)
            } compactLeading: {
                EmptyView()
            } compactTrailing: {
                EmptyView()
            } minimal: {
                EmptyView()
            }.widgetURL(URL(string: URL.mozInternalScheme + "://deep-link?url=/homepanel/downloads"))
        }
    }
}



@available(iOSApplicationExtension 16.1, *)
@DynamicIslandExpandedContentBuilder
private func expandedContent(context: ActivityViewContext<DownloadLiveActivityAttributes>) -> DynamicIslandExpandedContent<some View> {
        DynamicIslandExpandedRegion(.leading) {
            Image("./Assets/faviconFox")
                        .resizable()
                        .frame(width: 44, height: 44)
        }
        
        DynamicIslandExpandedRegion(.trailing) {
            ZStack {
                // Progress Circle
                Circle()
                    .stroke(Color.textOnDark.opacity(0.5), lineWidth: 6)
                    .frame(width: 44, height: 44)
                        
                // Progress Indicator
                Circle()
                    .trim(from: CGFloat(context.state.totalBytesDownloaded), to: CGFloat(context.state.totalBytesExpected))
                    .stroke(Color.textOnDark, lineWidth: 6)
                    .frame(width: 44, height: 44)
                    .rotationEffect(Angle(degrees: 270))
                
                // Stop Button
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Rectangle()
                            .fill(Color.textOnDark)
                            .frame(width: 12, height: 12)
                    )
            }
        }
        
        DynamicIslandExpandedRegion(.bottom) {
            Text("Downloading ...").font(.system(size: 17, weight: .bold))
            Text("\(context.state.totalBytesDownloaded) of \(context.state.totalBytesExpected)").font(.system(size: 15))
        }
    
}
