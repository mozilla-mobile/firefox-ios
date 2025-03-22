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
    private struct UX {
        static let hSpacing: CGFloat = 16
        static let vSpacing: CGFloat = 4
        static let iconSize: CGFloat = 40
        static let titleFont: CGFloat = 17
        static let subtitleFont: CGFloat = 15
        static let subtitleOpacity: CGFloat = 0.8
        static let circleRadius: CGFloat = 44
        static let circleWidth: CGFloat = 4
        static let circleOpacity: CGFloat = 0.3
        static let circleRotation: CGFloat = 270
        static let circleAnimation: CGFloat = 0.5
        static let progressIconSize: CGFloat = 20
        static let appIcon = "faviconFox"
        static let stopIcon = "mediaStop"
        static let checkmarkIcon = StandardImageIdentifiers.Large.checkmark
        static let gradient1 =  Color("searchButtonColorTwo")
        static let gradient2 = Color("searchButtonColorOne")
        static let labelColor = Color("widgetLabelColors")
    }
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DownloadLiveActivityAttributes.self) { liveDownload in
            let bytesCompleted = liveDownload.state.totalBytesDownloaded
            let bytesExpected = liveDownload.state.totalBytesExpected
            let mbCompleted = ByteCountFormatter.string(fromByteCount: bytesCompleted, countStyle: .file)
            let mbExpected = ByteCountFormatter.string(fromByteCount: bytesExpected, countStyle: .file)
            let subtitle = String(format: .LiveActivity.Downloads.FileProgressText, mbCompleted, mbExpected)
            let totalCompletion = liveDownload.state.completedDownloads == liveDownload.state.downloads.count
            ZStack {
                Rectangle()
                    .widgetURL(URL(string: URL.mozInternalScheme + "://deep-link?url=/homepanel/downloads"))
                    .foregroundStyle(LinearGradient(
                        gradient: Gradient(colors: [UX.gradient1, UX.gradient2]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                HStack(spacing: UX.hSpacing) {
                    ZStack {
                        Image(UX.appIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: UX.iconSize, height: UX.iconSize)
                    }
                    VStack(alignment: .leading, spacing: UX.vSpacing) {
                        Text(liveDownload.state.downloads.count == 1 ?
                             String(format: .LiveActivity.Downloads.FileNameText, liveDownload.state.downloads[0].fileName) :
                                String(format: .LiveActivity.Downloads.FileNameText, liveDownload.state.downloads.count))
                            .font(.system(size: UX.titleFont, weight: .bold))
                            .foregroundColor(UX.labelColor)
                        Text(subtitle)
                            .font(.system(size: UX.subtitleFont))
                            .opacity(UX.subtitleOpacity)
                            .foregroundColor(UX.labelColor)
                    }
                    Spacer()
                    ZStack {
                        Circle().stroke(lineWidth: UX.circleWidth)
                            .foregroundColor(UX.labelColor)
                            .opacity(UX.circleOpacity)
                        Circle().trim(from: 0.0, to: min(liveDownload.state.totalProgress, 1.0))
                            .stroke(style: StrokeStyle(lineWidth: UX.circleWidth))
                            .rotationEffect(.degrees(UX.circleRotation))
                            .animation(.linear, value: UX.circleAnimation)
                            .foregroundColor(UX.labelColor)
                        Image(totalCompletion ? UX.checkmarkIcon : UX.stopIcon)
                            .renderingMode(.template)
                            .frame(width: UX.progressIconSize, height: UX.progressIconSize)
                            .foregroundStyle(UX.labelColor)
                    }
                    .frame(width: UX.circleRadius, height: UX.circleRadius)
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
