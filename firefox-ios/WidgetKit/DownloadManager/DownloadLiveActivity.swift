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
        ActivityConfiguration(for: DownloadLiveActivityAttributes.self) { LiveDownload in
            // Using Rectangle instead of EmptyView because the hitbox
            // of the empty view is too small (likely non existent),
            // meaning we'd never be redirected to the downloads panel
            ZStack {
                Rectangle()
                    .widgetURL(URL(string: URL.mozInternalScheme + "://deep-link?url=/homepanel/downloads"))
                    .foregroundStyle(LinearGradient(
                            gradient: Gradient(colors: [Color("searchButtonColorTwo"), Color("searchButtonColorOne")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                HStack(spacing: 16) {
                    ZStack {
                        Image("faviconFox")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Downloading \(LiveDownload.state.downloads[0].fileName)")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(Color("widgetLabelColors"))
                        Text("\(String(format: "%.1f", Double(LiveDownload.state.totalBytesDownloaded) / 1000000)) MB of \(String(format: "%.1f", Double(LiveDownload.state.totalBytesExpected) / 1000000)) MB")
                            .font(.system(size: 15))
                            .opacity(0.8)
                            .foregroundColor(Color("widgetLabelColors"))
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 4)
                            .foregroundColor(Color("widgetLabelColors"))
                            .opacity(0.3)
                        Circle()
                            .trim(from: 0.0, to: min(
                                    Double(LiveDownload.state.totalBytesDownloaded) /
                                    Double(LiveDownload.state.totalBytesExpected),
                                    1.0
                                   )
                                )
                            .stroke(style: StrokeStyle(lineWidth: 4))
                            .rotationEffect(.degrees(270.0))
                            .animation(.linear, value: 0.5)
                            .foregroundColor(Color("widgetLabelColors"))
                        RoundedRectangle(cornerSize: CGSize(width: 2, height: 2))
                            .frame(width: 12, height: 12)
                            .foregroundColor(Color("widgetLabelColors"))
                    }
                    .frame(width: 44, height: 44)
                }
                .padding()
            }
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
            }.widgetURL(URL(string: URL.mozInternalScheme + "://deep-link?url=/homepanel/downloads"))
        }
    }
}
