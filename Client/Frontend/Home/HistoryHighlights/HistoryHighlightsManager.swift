// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage
import MozillaAppServices

protocol HighlightItem {}

extension Site: HighlightItem {}
extension ASGroup: HighlightItem {}

class HistoryHighlightsManager {

    // MARK: - Variables

    // These variables are defined by PM and Design and will be tweaked based on
    // their requirements or input.
    private static let defaultViewTimeWeight = 10.0
    private static let defaultFrequencyWeight = 4.0

    // MARK: - Public interface
    
    // Get highlights
    // Group highlights
    // Group Tabs
    // Remove top tab group from highlight groups if they are the same
    // filter out existing tabs from highlights???? ask daniela
    // Collate highlights & highlights groups
    // return that

    public static func getHighlightsData(
        with profile: Profile,
        completion: @escaping ([HighlightItem]?) -> Void
    ) {

    }


    // MARK: - Data fetching functions

    private static func fetchHighlights(
        with profile: Profile,
        andLimit limit: Int32 = 1000,
        completion: @escaping ([MozillaAppServices.HistoryHighlight]?) -> Void
    ) {

        profile.places.getHighlights(
            weights: HistoryHighlightWeights(viewTime: self.defaultViewTimeWeight,
                                             frequency: self.defaultFrequencyWeight),
            limit: limit
        ).uponQueue(.main) { result in
            guard let ASHighlights = result.successValue,
                  !ASHighlights.isEmpty
            else { return completion(nil) }

            completion(ASHighlights)
        }
    }

//    private static func commonFlow(
//        using profile: Profile,
//        completion: @escaping ([ASGroup<Site>]?, [Site]?) -> Void
//    ) {
//        fetchData(with: profile, andLimit: 1000) { (historyHighlights, historyData) in
//            guard let highlights = historyHighlights,
//                  !highlights.isEmpty,
//                  let history = historyData,
//                  !history.isEmpty
//            else {
//                completion(nil, nil)
//                return
//            }
//
//            buildSearchGroups(with: profile, and: highlightedSites) { groups, filteredSites in
//                completion(groups, filteredSites)
//            }
//
//            completion(nil, nil)
//        }
//
//    }

    private static func recentlyVisitedFlow(
        with groups: [ASGroup<Site>]?,
        and sites: [Site],
        completion: @escaping ([HighlightItem]) -> Void
    ) {

    }

    // MARK: - Helper functions


    private static func buildSearchGroups(
        with profile: Profile,
        and sites: [Site],
        completion: @escaping ([ASGroup<Site>]?, [Site]) -> Void
    ) {

        SearchTermGroupsManager.getURLGroups(
            with: profile,
            from: sites,
            using: .orderedAscending
        ) { groups, filteredItems in
            completion(groups, filteredItems)
        }
    }

    private static func collateForRecentlySaved(
        from groups: [ASGroup<Site>]?,
        and sites: [Site]
    ) -> [HighlightItem] {

        guard let groups = groups, !groups.isEmpty else { return sites }

        return []
    }
}
