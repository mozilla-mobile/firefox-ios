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
        
        static let iconFrameSize: CGFloat = 50
        static let firefoxIconSize: CGFloat = 44
        static let iconEdgeRounding: CGFloat = 15
        static let iconTopPadding: CGFloat = 10
        static let iconLeftPadding: CGFloat = 0
        static let iconRightPadding: CGFloat = 0
        static let iconBottomPadding: CGFloat = 0
        static let inProgessOpacity: CGFloat = 0.5
        static let progressWidth: CGFloat = 4
        static let stateIconSize: CGFloat = 24
        static let downloadingFontSize: CGFloat = 17
        static let progressFontSize: CGFloat = 15
        static let wordsTopPadding: CGFloat = 0
        static let wordsLeftPadding: CGFloat = 5
        static let wordsRightPadding: CGFloat = 5
        static let wordsBottomPadding: CGFloat = 0
        static let checkmarkIcon = "checkmarkLarge"
        static let mediaStopIcon = "mediaStop"
        static let firefoxIcon = "faviconFox"
        static let widgetColours = Color.white
    }
    private func leadingExpandedRegion
    (liveDownload: ActivityViewContext<DownloadLiveActivityAttributes>)
    -> DynamicIslandExpandedRegion<some View> {
      DynamicIslandExpandedRegion(.leading) {
        ZStack {
          RoundedRectangle(cornerRadius: DownloadLiveActivity.UX.iconEdgeRounding)
            .fill(DownloadLiveActivity.UX.widgetColours)
            .frame(width: DownloadLiveActivity.UX.iconFrameSize,
                height: DownloadLiveActivity.UX.iconFrameSize)
          Image(DownloadLiveActivity.UX.firefoxIcon)
            .resizable()
            .scaledToFit()
            .frame(width: DownloadLiveActivity.UX.firefoxIconSize,
                height: DownloadLiveActivity.UX.firefoxIconSize)
        }.padding(EdgeInsets(top: DownloadLiveActivity.UX.iconTopPadding,
                   leading: DownloadLiveActivity.UX.iconLeftPadding,
                   bottom: DownloadLiveActivity.UX.iconBottomPadding,
                   trailing: DownloadLiveActivity.UX.iconRightPadding))
      }
    }
    private func centerExpandedRegion
    (liveDownload: ActivityViewContext<DownloadLiveActivityAttributes>)
    -> DynamicIslandExpandedRegion<some View> {
      DynamicIslandExpandedRegion(.center) {
        Text(String(format: .LiveActivity.Downloads.FileNameText, liveDownload.state.downloads[0].fileName))
          .font(.headline)
          .frame(maxWidth: .infinity,
              alignment: .leading)
          .padding(EdgeInsets(top: DownloadLiveActivity.UX.wordsTopPadding,
                    leading: DownloadLiveActivity.UX.wordsLeftPadding,
                    bottom: DownloadLiveActivity.UX.wordsBottomPadding,
                    trailing: DownloadLiveActivity.UX.wordsRightPadding))
        let bytesDownloaded = ByteCountFormatter.string(
          fromByteCount: liveDownload.state.totalBytesDownloaded,
          countStyle: .file
          )
        let bytesExpected = ByteCountFormatter.string(
          fromByteCount: liveDownload.state.totalBytesExpected,
          countStyle: .file
          )
        Text(String(format: .LiveActivity.Downloads.FileProgressText, bytesDownloaded, bytesExpected))
          .font(.subheadline)
          .foregroundColor(DownloadLiveActivity.UX.widgetColours)
          .frame(maxWidth: .infinity,
              alignment: .leading)
          .padding(EdgeInsets(top: DownloadLiveActivity.UX.wordsTopPadding,
                    leading: DownloadLiveActivity.UX.wordsLeftPadding,
                    bottom: DownloadLiveActivity.UX.wordsBottomPadding,
                    trailing: DownloadLiveActivity.UX.wordsRightPadding))
      }
    }
    private func trailingExpandedRegion
    (liveDownload: ActivityViewContext<DownloadLiveActivityAttributes>)
    -> DynamicIslandExpandedRegion<some View> {
      DynamicIslandExpandedRegion(.trailing) {
        ZStack {
          Circle()
            .stroke(DownloadLiveActivity.UX.widgetColours.opacity(DownloadLiveActivity.UX.inProgessOpacity),
                lineWidth: DownloadLiveActivity.UX.progressWidth)
            .frame(width: DownloadLiveActivity.UX.iconFrameSize,
                height: DownloadLiveActivity.UX.iconFrameSize)
          Circle()
            .trim(from: 0.0,
               to: min(liveDownload.state.totalProgress, 1.0))
            .stroke(style: StrokeStyle(lineWidth: DownloadLiveActivity.UX.progressWidth))
            .rotationEffect(.degrees(270.0))
            .animation(.linear, value: 0.5)
          Image(
            liveDownload.state.totalProgress == 1.0
            ? DownloadLiveActivity.UX.checkmarkIcon
            : DownloadLiveActivity.UX.mediaStopIcon
          )
          .renderingMode(.template)
          .resizable()
          .scaledToFit()
          .foregroundStyle(DownloadLiveActivity.UX.widgetColours)
          .frame(width: DownloadLiveActivity.UX.stateIconSize, height: DownloadLiveActivity.UX.stateIconSize)
        }.frame(width: DownloadLiveActivity.UX.iconFrameSize,
            height: DownloadLiveActivity.UX.iconFrameSize)
          .padding(EdgeInsets(top: DownloadLiveActivity.UX.iconTopPadding,
                    leading: DownloadLiveActivity.UX.iconLeftPadding,
                    bottom: DownloadLiveActivity.UX.iconBottomPadding,
                    trailing: DownloadLiveActivity.UX.iconRightPadding))
      }
    }
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DownloadLiveActivityAttributes.self) { _ in
            // Using Rectangle instead of EmptyView because the hitbox
            // of the empty view is too small (likely non existent),
            // meaning we'd never be redirected to the downloads panel
            Rectangle()
                .widgetURL(URL(string: URL.mozInternalScheme + "://deep-link?url=/homepanel/downloads"))
        } dynamicIsland: { liveDownload in
            DynamicIsland {
                leadingExpandedRegion(liveDownload: liveDownload)
                centerExpandedRegion(liveDownload: liveDownload)
                trailingExpandedRegion(liveDownload: liveDownload)
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
                        .trim(from: 0.0, to: min(liveDownload.state.totalProgress, 1.0))
                        .stroke(style: StrokeStyle(lineWidth: UX.lineWidth))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear, value: min(liveDownload.state.totalProgress, 1.0))
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
