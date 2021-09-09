/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import MozillaAppServices

struct TabGroup {
    var searchTermName: String
    var tabs: [Tab]
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

class TabGroupsManager {
    static func getTabGroups(profile: Profile, tabs: [Tab], completion: @escaping ([String: [Tab]]?, _ filteredTabs: [Tab]) -> Void) {
        profile.places.getSearchTermMetaData().uponQueue(.main) { result in
            guard let val = result.successValue else { return completion(nil, [Tab]()) }
            
            let searchTerms = Set(val!.map({ return $0.key.searchTerm }))
            var searchTermMetaDataGroup : [String: [HistoryMetadata]] = [:]
            
            for term in searchTerms {
                let elements = val!.filter({ $0.key.searchTerm == term })
                searchTermMetaDataGroup[term!] = elements
            }
            
            // check if urls in tab matches search term groups
            var searchTermTabGroup: [String: [Tab]] = [:]
            var tabCopy: [Tab] = [Tab]()
            tabCopy.append(contentsOf: tabs)
            for tab in tabCopy {
                for (key,val) in searchTermMetaDataGroup {
                    for metadatas in val {
                        if tab.lastKnownUrl?.absoluteString == metadatas.key.url {
                            if let _ = searchTermTabGroup[key] {
                                searchTermTabGroup[key]?.append(tab)
                                break
                            } else {
                                searchTermTabGroup[key] = [Tab]()
                                searchTermTabGroup[key]?.append(tab)
                                break
                            }
                        }
                    }
                }
            }

            let filteredTabs = tabCopy.filter { tab in
                return !searchTermTabGroup.values.contains { value -> Bool in
                    (value as [Tab]).contains(tab) 
                }
            }
            
            completion(searchTermTabGroup, filteredTabs)
        }
    }
}
