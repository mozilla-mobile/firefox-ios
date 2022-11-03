// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage
import MozillaAppServices

private let defaultRecentlyVisitedCount = 9
private let searchLimit = 1000

extension HistoryHighlight {
    var urlFromString: URL? {
        return URL(string: url)
    }
}

protocol RecentlyVisitedManagerProtocol {
    func searchData(
        searchQuery: String,
        profile: Profile,
        tabs: [Tab],
        resultCount: Int,
        completion: @escaping ([RecentlyVisitedItem]?) -> Void)

    func getData(
        with profile: Profile,
        and tabs: [Tab],
        shouldGroup: Bool,
        resultCount: Int,
        completion: @escaping ([RecentlyVisitedItem]?) -> Void)
}

extension RecentlyVisitedManagerProtocol {
    func getData(
        with profile: Profile,
        and tabs: [Tab],
        shouldGroup: Bool = false,
        resultCount: Int = defaultRecentlyVisitedCount,
        completion: @escaping ([RecentlyVisitedItem]?) -> Void) {

        self.getData(
            with: profile,
            and: tabs,
            shouldGroup: shouldGroup,
            resultCount: resultCount,
            completion: completion)
    }
}

class RecentlyVisitedManager: RecentlyVisitedManagerProtocol {

    // MARK: - Variables

    // These variables are defined by PM and Design and will be tweaked based on
    // their requirements or input.
    private let defaultViewTimeWeight = 10.0
    private let defaultFrequencyWeight = 4.0

    func searchData(
        searchQuery: String,
        profile: Profile,
        tabs: [Tab],
        resultCount: Int,
        completion: @escaping ([RecentlyVisitedItem]?) -> Void) {

        getData(with: profile,
                          and: tabs,
                          resultCount: searchLimit) { results in

            var searchResults = [RecentlyVisitedItem]()

            guard let results = results else {
                completion(searchResults)
                return
            }
            for site in results {
                let urlString = site.siteUrl?.absoluteString ?? ""
                if site.displayTitle.lowercased().contains(searchQuery) ||
                    urlString.lowercased().contains(searchQuery) {
                    searchResults.append(site)
                }
            }
            completion(Array(searchResults.prefix(resultCount)))
        }
    }

    // MARK: - Public interface

    /// Fetches HistoryHighlight from A~S, and then filters currently open
    /// tabs against history highlights in order to avoid duplicated items. Then,
    /// if `shouldGroup` is set to true, applies group logic and finally,
    /// collates individual HistoryHighlight with `ASGroup<HistoryHighlight>`
    /// to return the top nine results alternating between them.
    ///
    /// - Parameters:
    ///   - profile: The user's `Profile` info
    ///   - tabs: List of `Tab` to filter open tabs from the recently visited item list
    ///   - shouldGroup: Toggle to support recently visited groups in the future for now is set to false
    ///   - resultCount: The number of results to return
    ///   - completion: completion handler than contains either a list of `HistoryHighlights` if `shouldGroup` is set to false
    ///   or a combine list of `HistoryHighlights` and `ASGroup<HistoryHighlights>`if is true
    func getData(
        with profile: Profile,
        and tabs: [Tab],
        shouldGroup: Bool = false,
        resultCount: Int = defaultRecentlyVisitedCount,
        completion: @escaping ([RecentlyVisitedItem]?) -> Void) {

        fetchHighlights(with: profile) { highlights in
            guard let highlights = highlights, !highlights.isEmpty else {
                completion(nil)
                return
            }

            var filterHighlights = highlights.filter { highlights in
                !tabs.contains { highlights.urlFromString == $0.lastKnownUrl }
            }

            filterHighlights = SponsoredContentFilterUtility().filterSponsoredHighlights(from: filterHighlights)

            if shouldGroup {
                self.buildSearchGroups(with: profile, and: filterHighlights) { groups, filterHighlights in
                    let collatedHighlights = self.collateForRecentlySaved(from: groups, and: filterHighlights)
                    completion(Array(collatedHighlights.prefix(resultCount)))
                }
            } else {
                completion(Array(filterHighlights.prefix(resultCount)))
            }
        }
    }

    // MARK: - Data fetching functions

    private func fetchHighlights(
        with profile: Profile,
        andLimit limit: Int32 = Int32(searchLimit),
        completion: @escaping ([HistoryHighlight]?) -> Void) {

        profile.places.getHighlights(weights: HistoryHighlightWeights(viewTime: defaultViewTimeWeight,
                                                                      frequency: defaultFrequencyWeight),
                                     limit: limit).uponQueue(.main) { result in

            guard let ASHighlights = result.successValue, !ASHighlights.isEmpty else { return completion(nil) }

            completion(ASHighlights)
        }
    }

    // MARK: - Helper functions

    private func buildSearchGroups(
        with profile: Profile,
        and highlights: [HistoryHighlight],
        completion: @escaping ([ASGroup<HistoryHighlight>]?, [HistoryHighlight]) -> Void) {

        SearchTermGroupsUtility.getHighlightGroups(with: profile,
                                                   from: highlights,
                                                   using: .orderedAscending) { groups, filteredItems in
            completion(groups, filteredItems)
        }
    }

    /// Collate `HistoryHighlight` groups and individual `HistoryHighlight` items, such that
    /// the resulting array alternates between them, starting with individual recently visited.
    /// Because groups could be nil, the `RecentlyVisitedItem` array gets initialized with the
    /// `HistoryHighlight` array and, if not `nil`, groups are then inserted in the odd index
    /// of the array. In case the individual items are done, the rest of the group array gets 
    /// appended to the result array.
    ///
    /// - Parameters:
    ///   - groups: Search Groups of `ASGroup<HistoryHighlight>`
    ///   - highlights: Individual `HistoryHighlight`
    /// - Returns: A  `RecentlyVisitedItem` array alternating `HistoryHighlight` and search `ASGroup<HistoryHighlight>`
    private func collateForRecentlySaved(
        from groups: [ASGroup<HistoryHighlight>]?,
        and highlights: [HistoryHighlight]) -> [RecentlyVisitedItem] {
        guard let groups = groups, !groups.isEmpty else { return highlights }

        var highlightItems: [RecentlyVisitedItem] = highlights

        for (index, group) in groups.enumerated() {
            let insertIndex = (index * 2) + 1
            if insertIndex <= highlightItems.count {
                highlightItems.insert(group, at: insertIndex)
            } else {
                // insert remaining items
                let restOfGroups = Array(groups[index..<groups.count])
                highlightItems.append(contentsOf: restOfGroups)
                break
            }
        }

        return highlightItems
    }
}
