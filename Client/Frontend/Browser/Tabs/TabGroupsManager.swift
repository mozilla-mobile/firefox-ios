/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import MozillaAppServices

struct ASGroup<T> {
    let searchTerm: String
    let groupedItems: [T]
    let timestamp: Timestamp
}

class TabGroupsManager {

    // Create URL groups from metadata
    /// - Parameters:
    ///   - profile: User Profile info
    ///   - urlList: List of urls we want to make the groups from
    ///   - completion: completion handler that contains [Search Term: [URL]]  dictionary and filterd URLs list that has URLs  that are not part of a group
    static func getURLGroups(profile: Profile, urlList: [URL], completion: @escaping ([String: [URL]]?, _ filteredUrls: [URL]) -> Void) {
        
        let lastTwoWeek = Int64(Date().lastTwoWeek.timeIntervalSince1970)
        profile.places.getHistoryMetadataSince(since: lastTwoWeek).uponQueue(.main) { result in
            guard let val = result.successValue else { return completion(nil, [URL]()) }
            
            let searchTerms = Set(val.map({ return $0.key.searchTerm }))
            var searchTermMetaDataGroup : [String: [HistoryMetadata]] = [:]
            
            // 1. Build serch term metadata group
            for term in searchTerms {
                if let term = term {
                    let elements = val.filter({ $0.key.searchTerm == term })
                    searchTermMetaDataGroup[term] = elements
                }
            }
            
            var urlGroupData: [String: [URL]] = [:]
            var urlInGroups: [URL] = [URL]()
            
            // 2. Build url groups that corresponds to search term
            outerUrlLoop: for url in urlList {
                innerMetadataLoop: for (searchTerm, historyMetaList) in searchTermMetaDataGroup {
                    if historyMetaList.contains(where: { metadata in
                        let absoluteUrl = url.absoluteString
                        return metadata.key.url == absoluteUrl || metadata.key.referrerUrl == absoluteUrl
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
        
        let lastTwoWeek = Int64(Date().lastTwoWeek.timeIntervalSince1970)
        profile.places.getHistoryMetadataSince(since: lastTwoWeek).uponQueue(.main) { result in
            guard let historyMetadata = result.successValue else { return completion(nil, [Tab]()) }
            
            let searchTermMetaDataGroup = buildMetadataGroups(from: historyMetadata)
            let (tabGroupData, tabInGroups) = buildTabGroups(from: tabs, and: searchTermMetaDataGroup)
            let (filteredGroups, filteredTabs) = filter(tabs: tabInGroups, from: tabGroupData, and: tabs)

            completion(filteredGroups, filteredTabs)
        }
    }

    /// Builds metadata groups using the provided metadata from ApplicationServices
    /// - Parameter ASMetadata: An array of `HistoryMetadata` used for splitting groups
    /// - Returns: A dictionary whose keys are search terms used for grouping
    private static func buildMetadataGroups(from ASMetadata: [HistoryMetadata]) -> [String: [HistoryMetadata]] {

        let searchTerms = Set(ASMetadata.map({ return $0.key.searchTerm }))
        var searchTermMetaDataGroup : [String: [HistoryMetadata]] = [:]

        for term in searchTerms {
            if let term = term {
                let elements = ASMetadata.filter({ $0.key.searchTerm == term })
                searchTermMetaDataGroup[term] = elements
            }
        }

        return searchTermMetaDataGroup
    }

    private static func buildTabGroups(from tabs: [Tab], and searchTermMetadata: [String: [HistoryMetadata]]) -> (tabGroupData: [String: [Tab]], tabsInGroups: [Tab]) {
        var tabGroupData: [String: [Tab]] = [:]
        var tabInGroups: [Tab] = [Tab]()

        outerTabLoop: for tab in tabs {
            innerMetadataLoop: for (searchTerm, historyMetaList) in searchTermMetadata {
                if historyMetaList.contains(where: { metadata in
                    let tabUrl = tab.lastKnownUrl?.absoluteString
                    return metadata.key.url == tabUrl || metadata.key.referrerUrl == tabUrl
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

        return (tabGroupData, tabInGroups)
    }

    private static func filter(tabs tabsInGroups: [Tab], from tabGroups: [String: [Tab]], and originalTabs: [Tab]) -> (filteredGroups: [String: [Tab]], filteredTabs: [Tab]) {
        let (filteredGroups, tabInGroups) = filterSingleTabGroups(from: tabGroups, and: tabsInGroups)
        let ungroupedTabs = filterDuplicate(tabsInGroups: tabsInGroups, from: originalTabs)

        return (filteredGroups, ungroupedTabs)
    }

    private static func filterSingleTabGroups(from tabGroups: [String: [Tab]], and tabsInGroups: [Tab]) -> (tabGroupData: [String: [Tab]], tabsInGroups: [Tab]) {
        var tabsInGroups = tabsInGroups

        // 3. Tab groups should have at least 2 tabs per search term so we remove smaller groups
        let filteredGroupData = tabGroups.filter { tabGroup in
            let t = tabGroup.value
            if t.count > 1 {
                return true
            } else {
                if let onlyTab = t.first, let index = tabsInGroups.firstIndex(of: onlyTab) {
                    tabsInGroups.remove(at: index)
                }
                return false
            }
        }

        return (filteredGroupData, tabsInGroups)
    }

    private static func filterDuplicate(tabsInGroups: [Tab], from tabs: [Tab]) -> [Tab] {
        // 4. Filter the tabs so it doesn't include same tabs as tab groups
        return tabs.filter { tab in !tabsInGroups.contains(tab) }

    }

    private static func stepFive() {

    }
}


class StopWatchTimer {
    private var timer: Timer?
    var isPaused = true
    // Recored in seconds
    var elapsedTime: Int32 = 0
    
    func startOrResume() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(incrementValue), userInfo: nil, repeats: true)
    }
    
    @objc func incrementValue() {
        elapsedTime += 1
    }
    
    func pauseOrStop() {
        timer?.invalidate()
    }
    
    func resetTimer() {
        elapsedTime = 0
        timer = nil
    }
}
