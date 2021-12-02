// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

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
        
        var tabFaviconDictionary = [String : Image]()
        let simpleTabs = SimpleTab.getSimpleTabs()
        for (_ , tab) in simpleTabs {
            guard !tab.imageKey.isEmpty else { continue }
            let fetchedImage = FaviconFetcher.getFaviconFromDiskCache(imageKey: tab.imageKey)
            let bundledFavicon = getBundledFavicon(siteUrl: tab.url)
            let letterFavicon = FaviconFetcher.letter(forUrl: tab.url ?? URL(string: "about:blank")!)
            let image = bundledFavicon ?? fetchedImage ?? letterFavicon
            tabFaviconDictionary[tab.imageKey] = Image(uiImage: image)
        }
        
        let openTabsEntry = OpenTabsEntry(date: Date(), favicons: tabFaviconDictionary, tabs: openTabs)
        completion(openTabsEntry)
    }
    
    func getBundledFavicon(siteUrl: URL?) -> UIImage? {
        guard let url = siteUrl else { return nil }
        // Get the bundled favicon if available
        guard let bundled = FaviconFetcher.getBundledIcon(forUrl: url), let image = UIImage(contentsOfFile: bundled.filePath) else { return nil }
        return image
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
