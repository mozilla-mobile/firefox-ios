// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import WidgetKit
import ActivityKit
import SwiftUI
import Foundation
import Common
import Shared

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
    struct UX {
        static let downloadColor: UIColor = .orange
        static let circleWidth: CGFloat = 17.5
        static let lineWidth: CGFloat = 3.5
        static let downloadIconSize: CGFloat = 19
        static let downloadPaddingLeading: CGFloat = 2
        static let downloadPaddingTrailing: CGFloat = 1
    }
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
                Image(StandardImageIdentifiers.Large.download)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: UX.downloadIconSize, height: UX.downloadIconSize)
                    .foregroundStyle(.orange)
                    .padding([.leading, .trailing], 2)
            } compactTrailing: {
                ZStack {
                    Circle()
                        .stroke(lineWidth: UX.lineWidth)
                        .foregroundColor(.gray)
                        .opacity(0.3)
                        .frame(width: UX.circleWidth, height: UX.circleWidth)
                        .padding(.leading, 2)
                        .padding(.trailing, 1)
                    Circle()
                        .trim(from: 0.0, to: min(LiveDownload.state.totalProgress, 1.0))
                        .stroke(style: StrokeStyle(lineWidth: UX.lineWidth))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear, value: min(LiveDownload.state.totalProgress, 1.0))
                        .foregroundStyle(.orange)
                        .frame(width: UX.circleWidth, height: UX.circleWidth)
                }
                .padding(.leading, UX.downloadPaddingLeading)
                .padding(.trailing, UX.downloadPaddingTrailing)
            } minimal: {
                EmptyView()
            }.widgetURL(URL(string: URL.mozInternalScheme + "://deep-link?url=/homepanel/downloads"))
        }
    }
}


