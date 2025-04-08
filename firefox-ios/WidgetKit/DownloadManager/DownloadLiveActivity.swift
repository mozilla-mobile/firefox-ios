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
        static let circleWidthMinimal: CGFloat = 19.5
        static let lineWidthMinimal: CGFloat = 3
        static let downloadIconSizeMinimal: CGFloat = 12
        static let downloadPaddingLeadingMinimal: CGFloat = 2
        static let downloadPaddingTrailingMinimal: CGFloat = 1
        static let downloadOpacityMinimal = 0.30
        static let downloadRotationMinimal: Double = -90.0
        static let checkmarkIcon = StandardImageIdentifiers.Large.checkmark
        static let mediaStopIcon = "mediaStop"
        static let firefoxIcon = "faviconFox"
        struct LockScreen {
            static let horizontalSpacing: CGFloat = 16
            static let verticalSpacing: CGFloat = 4
            static let iconSize: CGFloat = 40
            static let titleFont: CGFloat = 17
            static let subtitleFont: CGFloat = 15
            static let circleRadius: CGFloat = 44
            static let circleWidth: CGFloat = 4
            static let circleAnimation: CGFloat = 0.5
            static let progressIconSize: CGFloat = 20
            static let gradient1 =  Color("searchButtonColorTwo")
            static let gradient2 = Color("searchButtonColorOne")
            static let labelColor = Color("widgetLabelColors")
        }
        struct DynamicIsland {
            static let rotation: CGFloat = -90
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
            static let widgetColours = Color.white
            static let circleStrokeColor = widgetColours.opacity(inProgessOpacity)
        }
    }
    private func minimalViewBuilder(liveDownload: ActivityViewContext<DownloadLiveActivityAttributes>) -> some View {
        return ZStack {
            Image(StandardImageIdentifiers.Large.download)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: UX.downloadIconSizeMinimal, height: UX.downloadIconSizeMinimal)
                .foregroundStyle(.orange)
                .padding([.leading, .trailing], UX.downloadPaddingLeadingMinimal)
            Circle()
                .stroke(lineWidth: UX.lineWidthMinimal)
                .foregroundColor(.gray)
                .opacity(UX.downloadOpacityMinimal)
                .frame(width: UX.circleWidthMinimal, height: UX.circleWidthMinimal)
                .padding(.leading, UX.downloadPaddingLeadingMinimal)
                .padding(.trailing, UX.downloadPaddingTrailingMinimal)
            Circle()
                .trim(from: 0.0, to: min(liveDownload.state.totalProgress, 1.0))
                .stroke(style: StrokeStyle(lineWidth: UX.lineWidthMinimal))
                .rotationEffect(.degrees(UX.downloadRotationMinimal))
                .animation(.linear, value: min(liveDownload.state.totalProgress, 1.0))
                .foregroundStyle(.orange)
                .frame(width: UX.circleWidthMinimal, height: UX.circleWidthMinimal)
        }
    }
    private func lockScreenView (liveDownload: ActivityViewContext<DownloadLiveActivityAttributes>) -> some View {
        let bytesCompleted = liveDownload.state.totalBytesDownloaded
        let bytesExpected = liveDownload.state.totalBytesExpected
        let mbCompleted = ByteCountFormatter.string(fromByteCount: bytesCompleted, countStyle: .file)
        let mbExpected = ByteCountFormatter.string(fromByteCount: bytesExpected, countStyle: .file)
        let subtitle = String(format: .LiveActivity.Downloads.FileProgressText, mbCompleted, mbExpected)
        let totalCompletion = liveDownload.state.completedDownloads == liveDownload.state.downloads.count
        return ZStack {
            Rectangle()
                .widgetURL(URL(string: URL.mozInternalScheme + "://deep-link?url=/homepanel/downloads"))
                .foregroundStyle(LinearGradient(
                    gradient: Gradient(colors: [UX.LockScreen.gradient1, UX.LockScreen.gradient2]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing))
            HStack(spacing: UX.LockScreen.horizontalSpacing) {
                ZStack {
                    Image(UX.firefoxIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: UX.LockScreen.iconSize, height: UX.LockScreen.iconSize)
                }
                VStack(alignment: .leading, spacing: UX.LockScreen.verticalSpacing) {
                    Text(liveDownload.state.downloads.count == 1 ?
                         String(format: .LiveActivity.Downloads.FileNameText, liveDownload.state.downloads[0].fileName) :
                            String(format: .LiveActivity.Downloads.FileCountText,
                                   String(liveDownload.state.downloads.count)))
                        .font(.system(size: UX.LockScreen.titleFont, weight: .bold))
                        .foregroundColor(UX.LockScreen.labelColor)
                    Text(subtitle).font(.system(size: UX.LockScreen.subtitleFont))
                        .opacity(0.8)
                        .foregroundColor(UX.LockScreen.labelColor)
                        .contentTransition(.identity)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(lineWidth: UX.LockScreen.circleWidth)
                        .foregroundColor(UX.LockScreen.labelColor)
                        .opacity(0.3)
                    Circle()
                        .trim(from: 0.0, to: min(liveDownload.state.totalProgress, 1.0))
                        .stroke(style: StrokeStyle(lineWidth: UX.LockScreen.circleWidth))
                        .rotationEffect(.degrees(270))
                        .animation(.linear, value: UX.LockScreen.circleAnimation)
                        .foregroundColor(UX.LockScreen.labelColor)
                    Image(totalCompletion ? UX.checkmarkIcon : UX.mediaStopIcon)
                        .renderingMode(.template)
                        .frame(width: UX.LockScreen.progressIconSize, height: UX.LockScreen.progressIconSize)
                        .foregroundStyle(UX.LockScreen.labelColor)
                }
                .frame(width: UX.LockScreen.circleRadius, height: UX.LockScreen.circleRadius)
            }
            .padding()
        }
    }
    private func leadingExpandedRegion
    (liveDownload: ActivityViewContext<DownloadLiveActivityAttributes>)
    -> DynamicIslandExpandedRegion<some View> {
      DynamicIslandExpandedRegion(.leading) {
        ZStack {
            RoundedRectangle(cornerRadius: DownloadLiveActivity.UX.DynamicIsland.iconEdgeRounding)
            .fill(DownloadLiveActivity.UX.DynamicIsland.widgetColours)
            .frame(width: DownloadLiveActivity.UX.DynamicIsland.iconFrameSize,
                   height: DownloadLiveActivity.UX.DynamicIsland.iconFrameSize)
          Image(DownloadLiveActivity.UX.firefoxIcon)
            .resizable()
            .scaledToFit()
            .frame(width: DownloadLiveActivity.UX.DynamicIsland.firefoxIconSize,
                   height: DownloadLiveActivity.UX.DynamicIsland.firefoxIconSize)
        }.padding(EdgeInsets(top: DownloadLiveActivity.UX.DynamicIsland.iconTopPadding,
                             leading: DownloadLiveActivity.UX.DynamicIsland.iconLeftPadding,
                             bottom: DownloadLiveActivity.UX.DynamicIsland.iconBottomPadding,
                             trailing: DownloadLiveActivity.UX.DynamicIsland.iconRightPadding))
      }
    }
    private func centerExpandedRegion
    (liveDownload: ActivityViewContext<DownloadLiveActivityAttributes>)
    -> DynamicIslandExpandedRegion<some View> {
      DynamicIslandExpandedRegion(.center) {
          Text(liveDownload.state.downloads.count == 1 ?
               String(format: .LiveActivity.Downloads.FileNameText, liveDownload.state.downloads[0].fileName) :
                  String(format: .LiveActivity.Downloads.FileCountText, String(liveDownload.state.downloads.count)))
          .font(.headline)
          .frame(maxWidth: .infinity,
                 alignment: .leading)
          .padding(EdgeInsets(top: DownloadLiveActivity.UX.DynamicIsland.wordsTopPadding,
                              leading: DownloadLiveActivity.UX.DynamicIsland.wordsLeftPadding,
                              bottom: DownloadLiveActivity.UX.DynamicIsland.wordsBottomPadding,
                              trailing: DownloadLiveActivity.UX.DynamicIsland.wordsRightPadding))
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
          .foregroundColor(DownloadLiveActivity.UX.DynamicIsland.widgetColours)
          .frame(maxWidth: .infinity,
                 alignment: .leading)
          .padding(EdgeInsets(top: DownloadLiveActivity.UX.DynamicIsland.wordsTopPadding,
                              leading: DownloadLiveActivity.UX.DynamicIsland.wordsLeftPadding,
                              bottom: DownloadLiveActivity.UX.DynamicIsland.wordsBottomPadding,
                              trailing: DownloadLiveActivity.UX.DynamicIsland.wordsRightPadding))
          .contentTransition(.identity)
      }
    }
    private func trailingExpandedRegion
    (liveDownload: ActivityViewContext<DownloadLiveActivityAttributes>)
    -> DynamicIslandExpandedRegion<some View> {
      DynamicIslandExpandedRegion(.trailing) {
        ZStack {
          Circle()
            .stroke(UX.DynamicIsland.circleStrokeColor, lineWidth: DownloadLiveActivity.UX.DynamicIsland.progressWidth)
            .frame(width: DownloadLiveActivity.UX.DynamicIsland.iconFrameSize,
                   height: DownloadLiveActivity.UX.DynamicIsland.iconFrameSize)
          Circle()
            .trim(from: 0.0, to: min(liveDownload.state.totalProgress, 1.0))
            .stroke(style: StrokeStyle(lineWidth: DownloadLiveActivity.UX.DynamicIsland.progressWidth))
            .rotationEffect(.degrees(DownloadLiveActivity.UX.DynamicIsland.rotation))
            .animation(.linear, value: 0.5)
          Image(
            liveDownload.state.completedDownloads == liveDownload.state.downloads.count
            ? DownloadLiveActivity.UX.checkmarkIcon
            : DownloadLiveActivity.UX.mediaStopIcon
          )
          .renderingMode(.template)
          .resizable()
          .scaledToFit()
          .foregroundStyle(DownloadLiveActivity.UX.DynamicIsland.widgetColours)
          .frame(width: DownloadLiveActivity.UX.DynamicIsland.stateIconSize,
                 height: DownloadLiveActivity.UX.DynamicIsland.stateIconSize)
        }.frame(width: DownloadLiveActivity.UX.DynamicIsland.iconFrameSize,
                height: DownloadLiveActivity.UX.DynamicIsland.iconFrameSize)
          .padding(EdgeInsets(top: DownloadLiveActivity.UX.DynamicIsland.iconTopPadding,
                              leading: DownloadLiveActivity.UX.DynamicIsland.iconLeftPadding,
                              bottom: DownloadLiveActivity.UX.DynamicIsland.iconBottomPadding,
                              trailing: DownloadLiveActivity.UX.DynamicIsland.iconRightPadding))
      }
    }
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DownloadLiveActivityAttributes.self) { liveDownload in
            lockScreenView(liveDownload: liveDownload)
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
                    .frame(width: UX.DynamicIsland.downloadIconSize, height: UX.DynamicIsland.downloadIconSize)
                    .foregroundStyle(.orange)
                    .padding([.leading, .trailing], 2)
            } compactTrailing: {
                ZStack {
                    Circle()
                        .stroke(lineWidth: UX.DynamicIsland.lineWidth)
                        .foregroundColor(.gray)
                        .opacity(0.3)
                        .frame(width: UX.DynamicIsland.circleWidth, height: UX.DynamicIsland.circleWidth)
                        .padding(.leading, 2)
                        .padding(.trailing, 1)
                    Circle()
                        .trim(from: 0.0, to: min(liveDownload.state.totalProgress, 1.0))
                        .stroke(style: StrokeStyle(lineWidth: UX.DynamicIsland.lineWidth))
                        .rotationEffect(.degrees(UX.DynamicIsland.rotation))
                        .animation(.linear, value: min(liveDownload.state.totalProgress, 1.0))
                        .foregroundStyle(.orange)
                        .frame(width: UX.DynamicIsland.circleWidth, height: UX.DynamicIsland.circleWidth)
                }
                .padding(.leading, UX.DynamicIsland.downloadPaddingLeading)
                .padding(.trailing, UX.DynamicIsland.downloadPaddingTrailing)
            } minimal: {
                minimalViewBuilder(liveDownload: liveDownload)
            }.widgetURL(URL(string: URL.mozInternalScheme + "://deep-link?url=/homepanel/downloads"))
        }
    }
}
