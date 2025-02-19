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
            var mimeType: String
            var hasContentEncoding: Bool?
            var downloadPath: URL

            var totalBytesExpected: Int64?
            var bytesDownloaded: UInt64
            var isComplete: Bool
        }
        var downloads: [Download]
        
        func getCompletedDownloads() -> Int {
            return downloads.filter { $0.isComplete }.count
        }
        
        func getTotalDownloads() -> Int {
            return downloads.count
        }
        
        func getTotalProgress() -> Double {
            var totalBytesExpected: UInt64 = 0
            var totalBytesDownloaded: UInt64 = 0
            
            for download in downloads {
                // downloads with content encoding cannot
                // be estimated accurately and should be
                // skipped entirely in the calculation of progress
                if download.hasContentEncoding == true || download.totalBytesExpected == nil{
                    continue
                }
                totalBytesExpected += UInt64(download.totalBytesExpected!)
                totalBytesDownloaded += download.bytesDownloaded
            }
            
            if totalBytesExpected == 0 {
                return 0
            }
            
            return Double(totalBytesDownloaded) / Double(totalBytesExpected)
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
