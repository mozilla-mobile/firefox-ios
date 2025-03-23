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
    private struct lockScreenUX {
        static let hSpacing: CGFloat = 16
        static let vSpacing: CGFloat = 4
        static let iconSize: CGFloat = 40
        static let titleFont: CGFloat = 17
        static let subtitleFont: CGFloat = 15
        static let circleRadius: CGFloat = 44
        static let circleWidth: CGFloat = 4
        static let progressIconSize: CGFloat = 20
        static let appIcon = "faviconFox"
        static let stopIcon = "mediaStop"
        static let checkmarkIcon = StandardImageIdentifiers.Large.checkmark
        static let gradient1 =  Color("searchButtonColorTwo")
        static let gradient2 = Color("searchButtonColorOne")
        static let labelColor = Color("widgetLabelColors")
    }
    struct dynamicIslandUX {
        static let downloadColor: UIColor = .orange
        static let circleWidth: CGFloat = 17.5
        static let lineWidth: CGFloat = 3.5
        static let downloadIconSize: CGFloat = 19
        static let downloadPaddingLeading: CGFloat = 2
        static let downloadPaddingTrailing: CGFloat = 1
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
                        gradient: Gradient(colors: [lockScreenUX.gradient1, lockScreenUX.gradient2]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                HStack(spacing: lockScreenUX.hSpacing) {
                    ZStack {
                        Image(lockScreenUX.appIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: lockScreenUX.iconSize, height: lockScreenUX.iconSize)
                    }
                    VStack(alignment: .leading, spacing: lockScreenUX.vSpacing) {
                        Text(liveDownload.state.downloads.count == 1 ?
                             String(format: .LiveActivity.Downloads.FileNameText, liveDownload.state.downloads[0].fileName) :
                                String(format: .LiveActivity.Downloads.FileNameText, liveDownload.state.downloads.count))
                            .font(.system(size: lockScreenUX.titleFont, weight: .bold))
                            .foregroundColor(lockScreenUX.labelColor)
                        Text(subtitle)
                            .font(.system(size: lockScreenUX.subtitleFont))
                            .opacity(0.8)
                            .foregroundColor(lockScreenUX.labelColor)
                    }
                    Spacer()
                    ZStack {
                        Circle().stroke(lineWidth: lockScreenUX.circleWidth)
                            .foregroundColor(lockScreenUX.labelColor)
                            .opacity(0.3)
                        Circle().trim(from: 0.0, to: min(liveDownload.state.totalProgress, 1.0))
                            .stroke(style: StrokeStyle(lineWidth: lockScreenUX.circleWidth))
                            .rotationEffect(.degrees(270))
                            .animation(.linear, value: 0.5)
                            .foregroundColor(lockScreenUX.labelColor)
                        Image(totalCompletion ? lockScreenUX.checkmarkIcon : lockScreenUX.stopIcon)
                            .renderingMode(.template)
                            .frame(width: lockScreenUX.progressIconSize, height: lockScreenUX.progressIconSize)
                            .foregroundStyle(lockScreenUX.labelColor)
                    }
                    .frame(width: lockScreenUX.circleRadius, height: lockScreenUX.circleRadius)
                }
                .padding()
            }
        } dynamicIsland: { liveDownload in
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
                    .frame(width: dynamicIslandUX.downloadIconSize, height: dynamicIslandUX.downloadIconSize)
                    .foregroundStyle(.orange)
                    .padding([.leading, .trailing], 2)
            } compactTrailing: {
                ZStack {
                    Circle()
                        .stroke(lineWidth: dynamicIslandUX.lineWidth)
                        .foregroundColor(.gray)
                        .opacity(0.3)
                        .frame(width: dynamicIslandUX.circleWidth, height: dynamicIslandUX.circleWidth)
                        .padding(.leading, 2)
                        .padding(.trailing, 1)
                    Circle()
                        .trim(from: 0.0, to: min(liveDownload.state.totalProgress, 1.0))
                        .stroke(style: StrokeStyle(lineWidth: dynamicIslandUX.lineWidth))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear, value: min(liveDownload.state.totalProgress, 1.0))
                        .foregroundStyle(.orange)
                        .frame(width: dynamicIslandUX.circleWidth, height: dynamicIslandUX.circleWidth)
                }
                .padding(.leading, dynamicIslandUX.downloadPaddingLeading)
                .padding(.trailing, dynamicIslandUX.downloadPaddingTrailing)
            } minimal: {
                EmptyView()
            }.widgetURL(URL(string: URL.mozInternalScheme + "://deep-link?url=/homepanel/downloads"))
        }
    }
}
