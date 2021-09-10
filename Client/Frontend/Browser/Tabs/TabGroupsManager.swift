/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import MozillaAppServices

class TabGroupsManager {

    // Create URL groups from metadata
    /// - Parameters:
    ///   - profile: User Profile info
    ///   - urlList: List of urls we want to make the groups from
    ///   - completion: completion handler that contains [Search Term: [URL]]  dictionary and filterd URLs list that has URLs  that are not part of a group
    static func getURLGroups(profile: Profile, urlList: [URL], completion: @escaping ([String: [URL]]?, _ filteredUrls: [URL]) -> Void) {
        profile.places.getSearchTermMetaData().uponQueue(.main) { result in
            guard let val = result.successValue else { return completion(nil, [URL]()) }
            
            let searchTerms = Set(val!.map({ return $0.key.searchTerm }))
            var searchTermMetaDataGroup : [String: [HistoryMetadata]] = [:]
            
            // 1. Build serch term metadata group
            for term in searchTerms {
                let elements = val!.filter({ $0.key.searchTerm == term })
                searchTermMetaDataGroup[term!] = elements
            }
            
            var urlGroupData: [String: [URL]] = [:]
            var urlInGroups: [URL] = [URL]()
            
            // 2. Build url groups that corresponds to search term
            outerUrlLoop: for url in urlList {
                innerMetadataLoop: for (searchTerm, historyMetaList) in searchTermMetaDataGroup {
                    if historyMetaList.contains(where: { metadata in
                        metadata.key.url == url.absoluteString
                    }) {
                        urlInGroups.append(url)
                        if urlGroupData[searchTerm] == nil {
                            urlGroupData[searchTerm] = [url]
                        } else {
                            urlGroupData[searchTerm]?.append(url)
                        }
                        break innerMetadataLoop
                    }
                }
            }
            
            // 3. Url groups should have at least 2 url per search term so we remove smaller groups
            let filteredGroupData = urlGroupData.filter { urlGroup in
                let t = urlGroup.value
                if t.count > 1 {
                    return true
                } else {
                    if let onlyUrl = t.first, let index = urlInGroups.firstIndex(of: onlyUrl) {
                        urlInGroups.remove(at: index)
                    }
                    return false
                }
            }
            
            // 4. Filter the url list so it doesn't include same url as url groups
            let filteredUrls = urlList.filter { url in
                !urlInGroups.contains(url)
            }
            
            // 5. filteredGroupData contains groups of only 2 or more urls and filtered have urls that are not part of a group
            completion(filteredGroupData, filteredUrls)
        }
    }
    
    // Create Tab groups from metadata
    /// - Parameters:
    ///   - profile: User Profile info
    ///   - urlList: List of tabs we want to make the groups from
    ///   - completion: completion handler that contains [Search Term: [Tab]]  dictionary and filterdTabs list that has Tab which are not part of a group
    static func getTabGroups(profile: Profile, tabs: [Tab], completion: @escaping ([String: [Tab]]?, _ filteredTabs: [Tab]) -> Void) {
        profile.places.getSearchTermMetaData().uponQueue(.main) { result in
            guard let val = result.successValue else { return completion(nil, [Tab]()) }
            
            let searchTerms = Set(val!.map({ return $0.key.searchTerm }))
            var searchTermMetaDataGroup : [String: [HistoryMetadata]] = [:]
            
            // 1. Build serch term metadata group
            for term in searchTerms {
                let elements = val!.filter({ $0.key.searchTerm == term })
                searchTermMetaDataGroup[term!] = elements
            }
            
            var tabGroupData: [String: [Tab]] = [:]
            var tabInGroups: [Tab] = [Tab]()
            
            // 2. Build tab groups that corresponds to search term
            outerTabLoop: for tab in tabs {
                innerMetadataLoop: for (searchTerm, historyMetaList) in searchTermMetaDataGroup {
                    if historyMetaList.contains(where: { metadata in
                        metadata.key.url == tab.lastKnownUrl?.absoluteString
                    }) {
                        tabInGroups.append(tab)
                        if tabGroupData[searchTerm] == nil {
                            tabGroupData[searchTerm] = [tab]
                        } else {
                            tabGroupData[searchTerm]?.append(tab)
                        }
                        break innerMetadataLoop
                    }
                }
            }
            
            // 3. Tab groups should have at least 2 tabs per search term so we remove smaller groups
            let filteredGroupData = tabGroupData.filter { tabGroup in
                let t = tabGroup.value
                if t.count > 1 {
                    return true
                } else {
                    if let onlyTab = t.first, let index = tabInGroups.firstIndex(of: onlyTab) {
                        tabInGroups.remove(at: index)
                    }
                    return false
                }
            }
            
            // 4. Filter the tabs so it doesn't include same tabs as tab groups
            let filteredTabs = tabs.filter { tab in
                !tabInGroups.contains(tab)
            }
            
            // 5. filteredGroupData contains groups of only 2 or more tabs and filtered have tabs that are not part of a group
            completion(filteredGroupData, filteredTabs)
        }
    }
/*
    static func getTabGroups1(profile: Profile, tabs: [Tab], completion: @escaping ([String: [Tab]]?, _ filteredTabs: [Tab]) -> Void) {
        profile.places.getSearchTermMetaData().uponQueue(.main) { result in
            guard let val = result.successValue else { return completion(nil, [Tab]()) }
            
            let searchTerms = Set(val!.map({ return $0.key.searchTerm }))
            var searchTermMetaDataGroup : [String: [HistoryMetadata]] = [:]
            
            for term in searchTerms {
                let elements = val!.filter({ $0.key.searchTerm == term })
                searchTermMetaDataGroup[term!] = elements
            }
            
            var tabGroupData = [TabGroupData]()
            var searchTermTabGroup2: [String: [Tab]] = [:]
            var tempTabCopy = [Tab]()
            tempTabCopy.append(contentsOf: tabs) //tabs.map { $0.copy() }
            for (k,v) in searchTermMetaDataGroup {
                for data in v {
                    let tab = tabs.filter { tab in
                        tab.lastKnownUrl?.absoluteString == data.key.url
                    }.first
                    if searchTermTabGroup2[k] == nil, let tab = tab {
                        searchTermTabGroup2[k] = [tab]
                        if let index = tempTabCopy.firstIndex(of: tab) {
                            tempTabCopy.remove(at: index)
                        }
                    } else if let tab = tab {
                        searchTermTabGroup2[k]?.append(tab)
                        if let index = tempTabCopy.firstIndex(of: tab) {
                            tempTabCopy.remove(at: index)
                        }
                    }
                }
            }
            
            searchTermTabGroup2 = searchTermTabGroup2.filter({ element in
                element.value.count > 1
            })
            
            var tabsListInSearchTermGroup2 = [Tab]()
            
            for (k,v) in searchTermTabGroup2 {
                for a in v {
                    tabsListInSearchTermGroup2.append(a)
                }
            }
            var tempTabs = [Tab]()
            for t in tabs  {
                for group2Tabs in tabsListInSearchTermGroup2 {
                    if group2Tabs.tabUUID == t.tabUUID {
                        continue
                    } else {
                        tempTabs.append(t)
                        break
                    }
                }
                
                
//                if tabsListInSearchTermGroup2.contains(t) {
//                    continue
//                } else {
//                    tempTabs.append(t)
//                }
            }
            
            var filteredTabs = tabs.filter { tab in
                return !tabsListInSearchTermGroup2.contains(tab)
//                let hasTab = !searchTermTabGroup2.values.contains { value -> Bool in
//                    (value as [Tab]).contains(tab)
//                }
//                return hasTab
            }
            
//            // check if urls in tab matches search term groups
//            var searchTermTabGroup: [String: [Tab]] = [:]
////            var tabCopy: [Tab] = [Tab]()
////            tabCopy.append(contentsOf: tabs)
//
//            for tab in tabs {
//                for (key,val) in searchTermMetaDataGroup {
//                    for metadata in val {
//                        if tab.lastKnownUrl?.absoluteString == metadata.key.url {
//                            if let _ = searchTermTabGroup[key] {
//                                searchTermTabGroup[key]?.append(tab)
//                                break
//                            } else {
//                                searchTermTabGroup[key] = [Tab]()
//                                searchTermTabGroup[key]?.append(tab)
//                                break
//                            }
//                        }
//                    }
//                }
//            }
//
//            searchTermTabGroup = searchTermTabGroup.filter({ element in
//                element.value.count > 1
//            })
//
//            let filteredTabs = tabs.filter { tab in
//                return !searchTermTabGroup.values.contains { value -> Bool in
//                    (value as [Tab]).contains(tab)
//                }
//            }
            
            completion(searchTermTabGroup2, filteredTabs)
        }
    }
     */
}


class StopWatchTimer {
    private var timer: Timer?
    var isPaused = true
    var elpasedTime: Int32 = 0
    
    func startOrResume() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(incrementValue), userInfo: nil, repeats: true)
    }
    
    @objc func incrementValue() {
        elpasedTime += 1
    }
    
    func pauseOrStop() {
        timer?.invalidate()
    }
    
    func resetTimer() {
        elpasedTime = 0
        timer = nil
    }
}
