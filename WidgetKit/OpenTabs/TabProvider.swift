/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import WidgetKit
import UIKit
import Combine

struct TabProvider: TimelineProvider {
    public typealias Entry = OpenTabsEntry
    var tabsDict: [String: SimpleTab] = [:]
    
    func placeholder(in context: Context) -> OpenTabsEntry {
        OpenTabsEntry(date: Date(), favicons: [String: Image](), tabs: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (OpenTabsEntry) -> Void) {
        let allOpenTabs = SiteArchiver.tabsToRestore(tabsStateArchivePath: tabsStateArchivePath()).1

        let openTabs = allOpenTabs.values.filter {
            !$0.isPrivate
        }

        let faviconFetchGroup = DispatchGroup()
        
        var tabFaviconDictionary = [String : Image]()
        for tab in openTabs {
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
            let openTabsEntry = OpenTabsEntry(date: Date(), favicons: tabFaviconDictionary, tabs: openTabs)
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
    let tabs: [SimpleTab]
}
