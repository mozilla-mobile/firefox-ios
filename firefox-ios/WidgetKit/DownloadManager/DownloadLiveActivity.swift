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
        ActivityConfiguration(for: DownloadLiveActivityAttributes.self) { _ in
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

@available(iOS 16.2, *)
@DynamicIslandExpandedContentBuilder
private func expandedContent
(context: ActivityViewContext<DownloadLiveActivityAttributes>) -> DynamicIslandExpandedContent<some View> {
        DynamicIslandExpandedRegion(.leading) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                Image("faviconFox")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            }.padding()
        }
        DynamicIslandExpandedRegion(.trailing) {
            ZStack {
                // Progress Circle
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 6)
                    .frame(width: 44, height: 44)
                // Progress Indicator
                Circle()
                    .trim(from: 0.0, to: min(context.state.totalProgress, 1.0))
                    .stroke(style: StrokeStyle(lineWidth: 6))
                    .rotationEffect(.degrees(270.0))
                    .animation(.linear, value: 0.5)
                // Stop Button
                Image("mediaStop")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }.frame(width: 44, height: 44)
                .padding()
        }
        DynamicIslandExpandedRegion(.center) {
            Text("Downloading \(context.state.downloads[0].fileName)")
                .font(.system(size: 17,
                              weight: .bold))
            Text("\(String(format: "%.1f", Double(context.state.totalBytesDownloaded) / 1000000)) MB of \(String(format: "%.1f", Double(context.state.totalBytesExpected) / 1000000)) MB")
                                        .font(.system(size: 15))
                                        .opacity(0.8)
                                        .foregroundColor(Color("widgetLabelColors"))
        }
}

func startDownloadLiveActivity() {
    guard #available(iOS 16.2, *) else { return }

    let attributes = DownloadLiveActivityAttributes()
    let state = DownloadLiveActivityAttributes.ContentState(downloads: [DownloadLiveActivityAttributes.ContentState.Download(
        id: UUID(),
        fileName: "yayyy",
        hasContentEncoding: false,
        totalBytesExpected: 2000000000,
        bytesDownloaded: 50000000,
        isComplete: false
    )])

    do {
        _ = try Activity<DownloadLiveActivityAttributes>.request(
            attributes: attributes,
            content: .init(state: state, staleDate: nil),
            pushType: nil
        )
    } catch {
        print("Failed to start Live Activity: \(error.localizedDescription)")
    }
}
