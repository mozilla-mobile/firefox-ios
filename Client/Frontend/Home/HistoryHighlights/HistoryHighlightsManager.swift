// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage
import Places

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
    
    // Get highlights
    // Filter from highlights
    // Have a toggle to include groups
    // Group highlights
    // Collate single items & groups
    // return top 9

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
                !tabs.contains { highlights.urlFromString?.host == $0.url?.host }
            }

            // Build groups
            buildSearchGroups(with: profile, and: filterHighlights) { groups, filterHighlights in

                let collatedHighlights = collateForRecentlySaved(from: groups, and: filterHighlights)
                if collatedHighlights.count > defaultHighlightCount {
                    completion(Array(collatedHighlights[0...8]))
                } else {
                    completion(collatedHighlights)
                }
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

        guard shouldGroupHighlights else {
            completion(nil, highlights)
            return
        }

        SearchTermGroupsManager.getHighlightGroups(with: profile,
                                                   from: highlights,
                                                   using: .orderedAscending) { groups, filteredItems in
            completion(groups, filteredItems)
        }
    }

    private static func collateForRecentlySaved(from groups: [ASGroup<HistoryHighlight>]?,
                                                and sites: [HistoryHighlight]) -> [HighlightItem] {
        guard let groups = groups, !groups.isEmpty else { return sites }

        var highlightItems: [HighlightItem] = sites

        for (index, group) in groups.enumerated() {
            let insertIndex = (index * 2) + 1
//            if insertIndex < 
            highlightItems.insert(group, at: insertIndex)
        }

        return highlightItems
    }
}
