// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage
import MozillaAppServices

protocol HighlightItem {}

extension ASGroup: HighlightItem {}
extension HistoryHighlight: HighlightItem {}

extension HistoryHighlight {
    var urlFromString: URL? {
        return URL(string: url)
    }
}

class HistoryHighlightsManager {

    // MARK: - Variables

    // These variables are defined by PM and Design and will be tweaked based on
    // their requirements or input.
    private static let defaultViewTimeWeight = 10.0
    private static let defaultFrequencyWeight = 4.0
    private static let defaultHighlightCount = 9
    private static var shouldGroupHighlights = false

    // MARK: - Public interface

    /// Get HistoryHighlitght from A~S then filter open tabs from the history highlight result there should not be duplicated
    /// after apply group logic if `shouldGroupHighlights` is set to true and finally collate indidual HistoryHighlight with `ASGroup<HistoryHighlight>`
    /// to return the top nine results alternating betwen them.
    /// - Parameters:
    ///   - profile: The user's `Profile` info
    ///   - tabs: List of `Tab` to filter open tabs from the highlight item list
    ///   - shouldGroupHighlights: Toggle to support highlight groups in the future for now is set to false
    ///   - completion: completion handler than contains either a list of `HistoryHighlights` if `shouldGroupHighlights` is set to false
    ///   or a combine list of `HistoryHighlights` and `ASGroup<HistoryHighlights>`if is true
    public static func getHighlightsData(with profile: Profile,
                                         and tabs: [Tab],
                                         shouldGroupHighlights: Bool = false,
                                         completion: @escaping ([HighlightItem]?) -> Void) {
        HistoryHighlightsManager.shouldGroupHighlights = shouldGroupHighlights
        fetchHighlights(with: profile) { highlights in

            guard let highlights = highlights, !highlights.isEmpty else {
                completion(nil)
                return
            }

            let filterHighlights = highlights.filter { highlights in
                !tabs.contains { highlights.urlFromString == $0.url }
            }

            if shouldGroupHighlights {
                buildSearchGroups(with: profile, and: filterHighlights) { groups, filterHighlights in

                    let collatedHighlights = collateForRecentlySaved(from: groups, and: filterHighlights)
                    completion(Array(collatedHighlights.prefix(9)))
                }
            } else {
                completion(Array(filterHighlights.prefix(9)))
            }
        }
    }

    // MARK: - Data fetching functions

    private static func fetchHighlights(with profile: Profile,
                                        andLimit limit: Int32 = 1000,
                                        completion: @escaping ([HistoryHighlight]?) -> Void) {

        profile.places.getHighlights(weights: HistoryHighlightWeights(viewTime: self.defaultViewTimeWeight,
                                                                      frequency: self.defaultFrequencyWeight),
                                     limit: limit).uponQueue(.main) { result in

            guard let ASHighlights = result.successValue, !ASHighlights.isEmpty else { return completion(nil) }

            completion(ASHighlights)
        }
    }

    // MARK: - Helper functions

    private static func buildSearchGroups(with profile: Profile,
                                          and highlights: [HistoryHighlight],
                                          completion: @escaping ([ASGroup<HistoryHighlight>]?, [HistoryHighlight]) -> Void) {
        SearchTermGroupsManager.getHighlightGroups(with: profile,
                                                   from: highlights,
                                                   using: .orderedAscending) { groups, filteredItems in
            completion(groups, filteredItems)
        }
    }


    /// Collate a `HistoryHighlight` group and individual `HistoryHighlight`, the result array alternates them starting with individual highlights.
    ///  Because groups could be nil, the `HighlightItem` array get initialized with the `HistoryHighlight` array and if groups are not nil are inserted in the odd index of the array.
    ///  In case the individual items are done, the rest of the group array gets appended to the result array
    /// - Parameters:
    ///   - groups: Search Groups of `ASGroup<HistoryHighlight>`
    ///   - highlights: Individual `HistoryHighlight`
    /// - Returns: A  `HighlightItem` arrray alternating `HistoryHighlight` and search `ASGroup<HistoryHighlight>`
    private static func collateForRecentlySaved(from groups: [ASGroup<HistoryHighlight>]?,
                                                and highlights: [HistoryHighlight]) -> [HighlightItem] {
        guard let groups = groups, !groups.isEmpty else { return highlights }

        var highlightItems: [HighlightItem] = highlights

        for (index, group) in groups.enumerated() {
            let insertIndex = (index * 2) + 1
            if insertIndex < highlightItems.count {
                highlightItems.insert(group, at: insertIndex)
            } else {
                highlightItems.append(contentsOf: groups)
                break
            }
        }

        return highlightItems
    }
}
