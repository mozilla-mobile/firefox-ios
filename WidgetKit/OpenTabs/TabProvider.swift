/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import WidgetKit
import UIKit
import Combine

struct SimpleTabs: Hashable {
    var title: String?
    var url: URL?
    let lastUsedTime: Timestamp? // From Session Data
    var faviconURL: String?
    
    static func convertedTabs(_ tabs: [SavedTab]) -> [SimpleTabs] {
        var simpleTabs = [SimpleTabs]()
        for tab in tabs {
            var url:URL?
            // Check if we have any url
            if tab.url != nil {
                url = tab.url
              // Check if session data urls have something
            } else if tab.sessionData?.urls != nil {
                url = tab.sessionData?.urls.last
            }
            
            if url != nil, url!.absoluteString.starts(with: "internal://local/about/") {
                continue
            }
            
            var title = tab.title ?? ""
            // There is no title then use the base
            if title.isEmpty {
                title = url?.shortDisplayString ?? ""
            }
            
            let value = SimpleTabs(title: title, url: url, lastUsedTime: tab.sessionData?.lastUsedTime, faviconURL: tab.faviconURL)
            simpleTabs.append(value)
        }
        
        return simpleTabs
    }
}

struct TabProvider: TimelineProvider {
    public typealias Entry = OpenTabsEntry

    func placeholder(in context: Context) -> OpenTabsEntry {
        OpenTabsEntry(date: Date(), favicons: [String: Image](), tabs: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (OpenTabsEntry) -> Void) {
        let allOpenTabs = SiteArchiver.tabsToRestore(tabsStateArchivePath: tabsStateArchivePath())
//        let openTabs = allOpenTabs.filter {
//            !$0.isPrivate
////            !$0.isPrivate &&
////            $0.sessionData != nil &&
////            $0.url?.absoluteString.starts(with: "internal://") == false &&
////            $0.title != nil
//        }
        
        let openTabs = allOpenTabs.filter {
            !$0.isPrivate
        }
        let tabsList = SimpleTabs.convertedTabs(openTabs)
        
        let faviconFetchGroup = DispatchGroup()
        
        var tabFaviconDictionary = [String : Image]()
        for tab in tabsList {
            faviconFetchGroup.enter()
            if let faviconURL = tab.faviconURL {
                getImageForUrl(URL(string: faviconURL)!, completion: { image in
                    if image != nil {
                        tabFaviconDictionary[tab.title!] = image
                    }
                    
                    faviconFetchGroup.leave()
                })
            } else {
                faviconFetchGroup.leave()
            }
        }
        
        faviconFetchGroup.notify(queue: .main) {
            let openTabsEntry = OpenTabsEntry(date: Date(), favicons: tabFaviconDictionary, tabs: tabsList)
            completion(openTabsEntry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<OpenTabsEntry>) -> Void) {
        getSnapshot(in: context, completion: { openTabsEntry in
            let timeline = Timeline(entries: [openTabsEntry], policy: .atEnd)
            completion(timeline)
        })
    }
    
    fileprivate func tabsStateArchivePath() -> String? {
        let profilePath: String?
        profilePath = FileManager.default.containerURL( forSecurityApplicationGroupIdentifier: AppInfo.sharedContainerIdentifier)?.appendingPathComponent("profile.profile").path
        guard let path = profilePath else { return nil }
        return URL(fileURLWithPath: path).appendingPathComponent("tabsState.archive").path
    }
}

struct OpenTabsEntry: TimelineEntry {
    let date: Date
    let favicons: [String : Image]
    let tabs: [SimpleTabs]
}
