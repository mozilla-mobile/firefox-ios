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

struct UX {
    static let iconFrameSize: CGFloat = 50
    static let firefoxIconSize: CGFloat = 44
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
                let settings = expandedContentSettings()
                expandedContent(liveDownload: liveDownload, settings: settings)
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
(liveDownload: ActivityViewContext<DownloadLiveActivityAttributes>, settings: expandedContentSettings) ->
DynamicIslandExpandedContent<some View> {
        DynamicIslandExpandedRegion(.leading) {
            ZStack {
                RoundedRectangle(cornerRadius: settings.iconEdgeRounding)
                    .fill(settings.widgetColours)
                    .frame(width: settings.iconFrameSize,
                           height: settings.iconFrameSize)
                Image(settings.firefoxIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: settings.firefoxIconSize,
                           height: settings.firefoxIconSize)
            }.padding(EdgeInsets(top: settings.iconTopPadding,
                                 leading: settings.iconLeftPadding,
                                 bottom: settings.iconBottomPadding,
                                 trailing: settings.iconRightPadding))
        }
        DynamicIslandExpandedRegion(.trailing) {
            ZStack {
                Circle()
                    .stroke(settings.widgetColours.opacity(settings.inProgessOpacity),
                            lineWidth: settings.progressWidth)
                    .frame(width: settings.iconFrameSize,
                           height: settings.iconFrameSize)
                Circle()
                    .trim(from: 0.0,
                          to: min(liveDownload.state.totalProgress, 1.0))
                    .stroke(style: StrokeStyle(lineWidth: settings.progressWidth))
                    .rotationEffect(.degrees(270.0))
                    .animation(.linear, value: 0.5)
                if liveDownload.state.totalProgress == 1.0 {
                    Image(settings.checkmarkIcon)
                    .renderingMode(.template)
                    .frame(width: settings.stateIconSize,
                           height: settings.stateIconSize)
                    .foregroundStyle(settings.widgetColours)
                } else {
                    Image(settings.mediaStopIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: settings.stateIconSize,
                               height: settings.stateIconSize)
                }
            }.frame(width: settings.iconFrameSize,
                    height: settings.iconFrameSize)
                .padding(EdgeInsets(top: settings.iconTopPadding,
                                    leading: settings.iconLeftPadding,
                                    bottom: settings.iconBottomPadding,
                                    trailing: settings.iconRightPadding))
        }
        DynamicIslandExpandedRegion(.center) {
            Text(String(format: .LiveActivity.Downloads.FileNameText, liveDownload.state.downloads[0].fileName))
                .font(.system(size: settings.downloadingFontSize,
                              weight: .bold))
                .frame(maxWidth: .infinity,
                       alignment: .leading)
                .padding(EdgeInsets(top: settings.wordsTopPadding,
                                    leading: settings.wordsLeftPadding,
                                    bottom: settings.wordsBottomPadding,
                                    trailing: settings.wordsRightPadding))
            let bytesDownloaded = ByteCountFormatter.string(
                fromByteCount: liveDownload.state.totalBytesDownloaded,
                countStyle: .file
                )
            let bytesExpected = ByteCountFormatter.string(
                fromByteCount: liveDownload.state.totalBytesExpected,
                countStyle: .file
                )
            Text("\(bytesDownloaded) of \(bytesExpected)")
                .font(.system(size: settings.progressFontSize))
                .foregroundColor(settings.widgetColours)
                .frame(maxWidth: .infinity,
                       alignment: .leading)
                .padding(EdgeInsets(top: settings.wordsTopPadding,
                                    leading: settings.wordsLeftPadding,
                                    bottom: settings.wordsBottomPadding,
                                    trailing: settings.wordsRightPadding))
        }
}
