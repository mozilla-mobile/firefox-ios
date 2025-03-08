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
        } dynamicIsland: { LiveDownload in
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
                Image(systemName: "arrow.down.to.line")
                    .foregroundStyle(.orange)
                    .font(.system(size: 16, weight: .light))
            } compactTrailing: {
//                Text(
//                    String(
//                        format: "%.0f",
//                        (Double(LiveDownload.state.totalBytesDownloaded) / Double(LiveDownload.state.totalBytesExpected)) * 100
//                    )
//                )//
                ZStack {
                    Circle()
                        .stroke(lineWidth: 4)
                        .foregroundColor(.gray)
                        .opacity(0.3)
                        .frame(width: 19, height: 19)
                        .padding(.leading, 2)
                    Circle()
                    // 0.57 is a dummy value for how far along the download progress is
                        .trim(from: 0.0, to: min(0.57, 1.0))
                        .stroke(style: StrokeStyle(lineWidth: 4))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear, value: 0.57)
                        .foregroundStyle(.orange)
                        .frame(width: 19, height: 19)
                        .padding(.leading, 2)
                }
            } minimal: {
                EmptyView()
            }.widgetURL(URL(string: URL.mozInternalScheme + "://deep-link?url=/homepanel/downloads"))
        }
    }
}

func startDownloadLiveActivity() {
    guard #available(iOS 16.2, *) else { return }

    let attributes = DownloadLiveActivityAttributes()
    let state = DownloadLiveActivityAttributes.ContentState(downloads: [DownloadLiveActivityAttributes.ContentState.Download(
        id: UUID(),
        fileName: "hello.py",
        hasContentEncoding: true,
        totalBytesExpected: 100000,
        bytesDownloaded: 57000,
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
