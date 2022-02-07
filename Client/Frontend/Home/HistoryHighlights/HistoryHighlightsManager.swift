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
    
    public static func getHighlightsData(with profile: Profile,
                                         and tabs: [Tab],
                                         shouldGroupHighlights: Bool = false,
                                         completion: @escaping ([HighlightItem]?) -> Void) {
        // Get highlights
        HistoryHighlightsManager.shouldGroupHighlights = shouldGroupHighlights
        fetchHighlights(with: profile) { highlights in
            guard let highlights = highlights, !highlights.isEmpty else {
                completion(nil)
                return
            }

            // Filter from highlights
            let filterHighlights = highlights.filter { highlights in
                // can't filter on host because we want the unique url
                !tabs.contains { highlights.urlFromString == $0.url }
            }

            // Build groups
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


    /// Collate a history highlight group and individual highlight, the result array alternates them starting with individual highlights. In case one of the items is done we append the content of remaining source
    /// - Parameters:
    ///   - groups: Search Groups of history highlights
    ///   - sites: Individual highlights sites
    /// - Returns: A  highlight items arrray alternating highlight sites and search groups
    private static func collateForRecentlySaved(from groups: [ASGroup<HistoryHighlight>]?,
                                                and highlights: [HistoryHighlight]) -> [HighlightItem] {
        guard let groups = groups, !groups.isEmpty else { return highlights }

        var highlightItems: [HighlightItem] = highlights

        for (index, group) in groups.enumerated() {
            // add documentation
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
