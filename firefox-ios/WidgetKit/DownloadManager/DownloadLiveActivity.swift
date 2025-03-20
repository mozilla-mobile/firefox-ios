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

private struct UX {
    var iconFrameSize: CGFloat = 50
    var firefoxIconSize: CGFloat = 44
    var iconEdgeRounding: CGFloat = 15
    var iconTopPadding: CGFloat = 10
    var iconLeftPadding: CGFloat = 0
    var iconRightPadding: CGFloat = 0
    var iconBottomPadding: CGFloat = 0
    var inProgessOpacity: CGFloat = 0.5
    var progressWidth: CGFloat = 4
    var stateIconSize: CGFloat = 24
    var downloadingFontSize: CGFloat = 17
    var progressFontSize: CGFloat = 15
    var wordsTopPadding: CGFloat = 0
    var wordsLeftPadding: CGFloat = 5
    var wordsRightPadding: CGFloat = 5
    var wordsBottomPadding: CGFloat = 0
    var checkmarkIcon = "checkmarkLarge"
    var mediaStopIcon = "mediaStop"
    var firefoxIcon = "faviconFox"
    var widgetColours = Color.white
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
                let UX = UX()
                expandedContent(liveDownload: liveDownload, UX: UX)
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
private func expandedContent(liveDownload: ActivityViewContext<DownloadLiveActivityAttributes>, UX: UX) ->
DynamicIslandExpandedContent<some View> {
        DynamicIslandExpandedRegion(.leading) {
            ZStack {
                RoundedRectangle(cornerRadius: UX.iconEdgeRounding)
                    .fill(UX.widgetColours)
                    .frame(width: UX.iconFrameSize,
                           height: UX.iconFrameSize)
                Image(UX.firefoxIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: UX.firefoxIconSize,
                           height: UX.firefoxIconSize)
            }.padding(EdgeInsets(top: UX.iconTopPadding,
                                 leading: UX.iconLeftPadding,
                                 bottom: UX.iconBottomPadding,
                                 trailing: UX.iconRightPadding))
        }
        DynamicIslandExpandedRegion(.trailing) {
            ZStack {
                Circle()
                    .stroke(UX.widgetColours.opacity(UX.inProgessOpacity),
                            lineWidth: UX.progressWidth)
                    .frame(width: UX.iconFrameSize,
                           height: UX.iconFrameSize)
                Circle()
                    .trim(from: 0.0,
                          to: min(liveDownload.state.totalProgress, 1.0))
                    .stroke(style: StrokeStyle(lineWidth: UX.progressWidth))
                    .rotationEffect(.degrees(270.0))
                    .animation(.linear, value: 0.5)
                Image(
                    liveDownload.state.totalProgress == 1.0
                    ? UX.checkmarkIcon
                    : UX.mediaStopIcon
                )
                .resizable()
                .scaledToFit()
                .foregroundStyle(UX.widgetColours)
                .frame(width: UX.stateIconSize, height: UX.stateIconSize)
            }.frame(width: UX.iconFrameSize,
                    height: UX.iconFrameSize)
                .padding(EdgeInsets(top: UX.iconTopPadding,
                                    leading: UX.iconLeftPadding,
                                    bottom: UX.iconBottomPadding,
                                    trailing: UX.iconRightPadding))
        }
        DynamicIslandExpandedRegion(.center) {
            Text(String(format: .LiveActivity.Downloads.FileNameText, liveDownload.state.downloads[0].fileName))
                .font(.system(size: UX.downloadingFontSize,
                              weight: .bold))
                .frame(maxWidth: .infinity,
                       alignment: .leading)
                .padding(EdgeInsets(top: UX.wordsTopPadding,
                                    leading: UX.wordsLeftPadding,
                                    bottom: UX.wordsBottomPadding,
                                    trailing: UX.wordsRightPadding))
            let bytesDownloaded = ByteCountFormatter.string(
                fromByteCount: liveDownload.state.totalBytesDownloaded,
                countStyle: .file
                )
            let bytesExpected = ByteCountFormatter.string(
                fromByteCount: liveDownload.state.totalBytesExpected,
                countStyle: .file
                )
            Text(String(format: .LiveActivity.Downloads.FileProgressText, bytesDownloaded, bytesExpected))
                .font(.system(size: UX.progressFontSize))
                .foregroundColor(UX.widgetColours)
                .frame(maxWidth: .infinity,
                       alignment: .leading)
                .padding(EdgeInsets(top: UX.wordsTopPadding,
                                    leading: UX.wordsLeftPadding,
                                    bottom: UX.wordsBottomPadding,
                                    trailing: UX.wordsRightPadding))
        }
}
