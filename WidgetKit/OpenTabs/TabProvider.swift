/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import WidgetKit
import UIKit
import Combine

//struct SimpleTabs: Hashable {
//    var title: String?
//    var url: URL?
//    let lastUsedTime: Timestamp // From Session Data
//    var faviconURL: String?
//    var savedTab: SavedTab
//
//    static func convertedTabs(_ tabs: [SavedTab]) -> [SimpleTabs] {
//        var simpleTabs = [SimpleTabs]()
//        for tab in tabs {
//            var url:URL?
//            // Check if we have any url
//            if tab.url != nil {
//                url = tab.url
//              // Check if session data urls have something
//            } else if tab.sessionData?.urls != nil {
//                url = tab.sessionData?.urls.last
//            }
//
//            if url != nil, url!.absoluteString.starts(with: "internal://local/about/") {
//                continue
//            }
//
//            var title = tab.title ?? ""
//            // There is no title then use the base
//            if title.isEmpty {
//                title = url?.shortDisplayString ?? ""
//            }
//
//            let value = SimpleTabs(title: title, url: url, lastUsedTime: tab.sessionData?.lastUsedTime ?? 0, faviconURL: tab.faviconURL, savedTab: tab)
//            simpleTabs.append(value)
//        }
//
//        return simpleTabs
//    }
//}


let userDefaultsKey = "myTabKey1"
let userDefaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)!
var tabsDict: [String: SimpleTab] = [:]
func saveSimpleTab(tabs:[String: SimpleTab]) {
//    userDefaults.setValue(tabs, forKey: userDefaultsKey)
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(tabs) {
        userDefaults.set(encoded, forKey: userDefaultsKey)
    }
//    userDefaults.set(tabs, forKey: userDefaultsKey)
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
        
        let tabsList = convertedTabs(openTabs)
        
        saveSimpleTab(tabs: tabsDict)
        // Debug ----
//        let dictionary = ["name": "Adam"]
//
//        // Save to User Defaults
//        userDefaults.set(dictionary, forKey: "ayy")
//
//        // Read from User Defaults
//        let saved = userDefaults.value(forKey: "ayy") as? [String: String]
//
//        userDefaults.setValue("Hello", forKey: "Hello")
//
//        let ta1 = SimpleTab(title: "temp", url: nil, lastUsedTime: nil, faviconURL: nil, uuid: "0")
//
////        UserDefaults.standard.set(try? ta1().encode(value), forKey: key)
////        userDefaults.set(ta3, forKey: "ayy7")
//
//        let encoder = JSONEncoder()
//        if let encoded = try? encoder.encode(ta1) {
//            userDefaults.set(encoded, forKey: "ayy8")
//        }
//
//        if let tbs = userDefaults.object(forKey: "ayy8") as? Data {
//            let decoder = JSONDecoder()
//            if let tbs = try? decoder.decode(SimpleTab.self, from: tbs) as SimpleTab {
//                print(tbs.title)
//            }
//        }
//
////        userDefaults.set(ta3, forKey: "ayy5")
////        let ta2 = SimpleTab(title: "temp1", url: nil, lastUsedTime: nil, faviconURL: nil, uuid: "1")
////        let ta3 = SimpleTab(title: "temp2", url: nil, lastUsedTime: nil, faviconURL: nil, uuid: "2")
////        let ta4 = SimpleTab(title: "temp3", url: nil, lastUsedTime: nil, faviconURL: nil, uuid: "3")
////
//        var tabsd: [String: SimpleTab] = [:]
//        tabsd["1"] = ta1
////        tabsd["2"] = ta2
////        tabsd["3"] = ta3
////        tabsd["4"] = ta4
//
//        // Save to User Defaults
////        userDefaults.set(tabsd, forKey: "ayy1")
//
//
////        let saved2 = userDefaults.value(forKey: "ayy1") as? [String: SimpleTab]
//
//        // Debug ^^^^
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

    func convertedTabs(_ tabs: [SavedTab]) -> [SimpleTab] {
//        var simpleTabs = [SimpleTab]()
//        let uuid = UUID().uuidString
        var simpleTabs: [String: SimpleTab] = [:]
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
            let uuid = UUID().uuidString
            let value = SimpleTab(title: title, url: url, lastUsedTime: tab.sessionData?.lastUsedTime ?? 0, faviconURL: tab.faviconURL, uuid: uuid)
            simpleTabs[uuid] = value

//            simpleTabs.append(value)
        }
        tabsDict = simpleTabs
//        saveSimpleTab(tabs: simpleTabs)
        // save tabs
        let arrayFromDic = Array(simpleTabs.values.map{ $0 })
        return arrayFromDic
    }
}


struct OpenTabsEntry: TimelineEntry {
    let date: Date
    let favicons: [String : Image]
    let tabs: [SimpleTab]
}
