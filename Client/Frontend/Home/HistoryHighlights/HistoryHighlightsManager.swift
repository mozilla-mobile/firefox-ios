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

enum HighlightDataDestination {
    case recentlyVisited
    case historyPanel
}

class HistoryHighlightsManager {

    // MARK: - Variables

    // These variables are defined by PM and Design and will be tweaked based on
    // their requirements or input.
    private static let defaultViewTimeWeight = 10.0
    private static let defaultFrequencyWeight = 4.0

    // MARK: - Public interface

    public static func getHighlightsData(
        for destination: HighlightDataDestination,
        with profile: Profile,
        completion: @escaping ([HighlightItem]?) -> Void
    ) {

        commonFlow(using: profile) { groups, filteredSites in
            guard let groups = groups,
                  let filteredSites = filteredSites
            else {
                completion(nil)
                return
            }

            switch destination {
            case .recentlyVisited:
                recentlyVisitedFlow(with: groups, and: filteredSites) { highlightItems in
                    completion(Array(highlightItems.prefix(9)))
                }

            case .historyPanel:
                print("Yoohoo")
            }
        }
    }


    // MARK: - Data fetching functions

    private static func fetchData(
        with profile: Profile,
        andLimit limit: Int32,
        completion: @escaping ([MozillaAppServices.HistoryHighlight]?, [Site]?) -> Void
    ) {

        fetchHighlights(with: profile, andLimit: 1000) { highlights in
            guard let highlights = highlights,
                  !highlights.isEmpty
            else { return completion(nil, nil) }

            fetchSites(with: profile, andLimit: highlights.count).uponQueue(.main) { result in
                guard let historyData = result.successValue else { return completion(nil, nil) }

                var sites = [Site]()

                for site in historyData {
                    if let site = site {
                        sites.append(site)
                    }
                }

                completion(highlights, sites)
            }

        }
    }

    private static func fetchHighlights(
        with profile: Profile,
        andLimit limit: Int32,
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

    private static func fetchSites(
        with profile: Profile,
        andLimit limit: Int
    ) -> Deferred<Maybe<Cursor<Site>>> {

        return profile.history.getSitesByLastVisit(limit: limit, offset: 0) >>== { result in
            return deferMaybe(result)
        }
    }

    // MARK: - Flows

    private static func commonFlow(
        using profile: Profile,
        completion: @escaping ([ASGroup<Site>]?, [Site]?) -> Void
    ) {
        fetchData(with: profile, andLimit: 1000) { (historyHighlights, historyData) in
            guard let highlights = historyHighlights,
                  !highlights.isEmpty,
                  let history = historyData,
                  !history.isEmpty
            else {
                completion(nil, nil)
                return
            }

            let highlightedSites = map(highlights: highlights, to: history)
            buildSearchGroups(with: profile, and: highlightedSites) { groups, filteredSites in
                completion(groups, filteredSites)
            }

            completion(nil, nil)
        }

    }

    private static func recentlyVisitedFlow(
        with groups: [ASGroup<Site>]?,
        and sites: [Site],
        completion: @escaping ([HighlightItem]) -> Void
    ) {

    }

    private static func historyPanelFlow(
        completion: @escaping ([HighlightItem]) -> Void
    ) {

    }

    // MARK: - Helper functions

    private static func map(
        highlights: [MozillaAppServices.HistoryHighlight],
        to sites: [Site]
    ) -> [Site] {

        sites.forEach { site in
            for highlight in highlights {
                if site.url == highlight.url {
                    site.highlightScore = highlight.score
                    break
                }
            }
        }

        return sites
    }

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

    // not needed as search groups removes dupes
//    private static func removeDuplicateHighlights() {
//
//    }

    private static func collateForRecentlySaved(
        from groups: [ASGroup<Site>]?,
        and sites: [Site]
    ) -> [HighlightItem] {

        guard let groups = groups, !groups.isEmpty else { return sites }

        if


        return []
    }

    private static func dropBottomFourtyPercentOf(highlights: [Site]) {

    }

    private static func historyPanelMerge() {

    }

    private static func orderByDate() {

    }
}
