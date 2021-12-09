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

struct HistoryHighlight {
    let score: Double
    let placeID: Int32
    let url: String
    let title: String?
    let previewImageURL: String?
}

struct HistoryHighlightsData {
    var todaysHighlights = [HighlightItem]()
    var yesterdaysHighlights = [HighlightItem]()
    var lastSevenDaysHighlights = [HighlightItem]()
    var lastFourteenDaysHighlights = [HighlightItem]()
}

class HistoryHighlightsManager {
    // MARK: - Variables

    // These variables are
    private static let defaultViewTimeWeight = 10.0
    private static let defaultFrequencyWeight = 4.0

    // MARK: - Public interface

    public static func getHighlightsForRecentlyViewed(
        with profile: Profile,
        completion: @escaping ([HighlightItem]?) -> Void)
    {
        fetchData(with: profile, andLimit: 1000) { (historyHighlights, historyData) in
            guard let highlights = historyHighlights,
                  !highlights.isEmpty,
                  let history = historyData,
                  !history.isEmpty
            else { return completion(nil) }

        // fetch Sites with limit of highlights count
        // build search groups
        // remove dupe highlights
        // map remaining Sites with highlights (keep highlight order)
        // collate HH Sites & SG
        // order by date
        }
    }

    public static func getHighlightsForHistoryPanel(
        with profile: Profile,
        usingSites sites: [Site],
        andSearchGroups searchGroups: [ASGroup<Site>],
        completion: @escaping ([Site], _ searchGroups: [ASGroup<Site>]) -> Void
    ) {

        // fetch highlights
        // fetch Sites with limit of highlights count
        // build search groups
        // remove dupe highlights
        // map remaining Sites with highlights (keep highlight order)
        // collate HH Sites & SG
        // order by date

    }

    // MARK: - Private functions

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
}
