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
        } dynamicIsland: { liveDownload in
            DynamicIsland {
                expandedContent(liveDownload: liveDownload)
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
(liveDownload: ActivityViewContext<DownloadLiveActivityAttributes>) -> DynamicIslandExpandedContent<some View> {
        DynamicIslandExpandedRegion(.leading) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                Image("faviconFox")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            }.padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
        }
        DynamicIslandExpandedRegion(.trailing) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 5)
                    .frame(width: 50, height: 50)
                Circle()
                    .trim(from: 0.0, to: min(liveDownload.state.totalProgress, 1.0))
                    .stroke(style: StrokeStyle(lineWidth: 5))
                    .rotationEffect(.degrees(270.0))
                    .animation(.linear, value: 0.5)
                if liveDownload.state.totalProgress == 1.0 {
                    Image("checkmarkLarge")
                    .renderingMode(.template)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Color("widgetLabelColors"))
                } else {
                    Image("mediaStop")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }.frame(width: 50, height: 50)
                .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
        }
        DynamicIslandExpandedRegion(.center) {
            Text("Downloading \(liveDownload.state.downloads[0].fileName)")
                .font(.system(size: 17,
                              weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
            let bytesDownloaded = ByteCountFormatter.string(
                fromByteCount: liveDownload.state.totalBytesDownloaded,
                countStyle: .file
                )
            let bytesExpected = ByteCountFormatter.string(
                fromByteCount: liveDownload.state.totalBytesExpected,
                countStyle: .file
                )
            Text("\(bytesDownloaded) of \(bytesExpected)")
                                        .font(.system(size: 15))
                                        .opacity(0.8)
                                        .foregroundColor(Color.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
        }
}
