/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension String {
    static func localized(_ forKey: Key) -> String {
        localized(forKey.rawValue)
    }
    
    static func localized(_ string: String) -> String {
        NSLocalizedString(string, tableName: "Ecosia", comment: "")
    }
    
    enum Key: String {
        case autocomplete = "Autocomplete"
        case daysAgo = "%@ days ago"
        case ecosiaRecommends = "Ecosia recommends"
        case exploreEcosia = "Explore Ecosia"
        case faq = "FAQ"
        case financialReports = "Financial reports"
        case getStarted = "Get started"
        case howEcosiaWorks = "How Ecosia works"
        case keepUpToDate = "Keep up to date with the latest news from our projects and more"
        case moderate = "Moderate"
        case more = "More"
        case mySearches = "My searches"
        case new = "New"
        case off = "Off"
        case personalizedResults = "Personalized results"
        case plantTreesWhile = "Plant trees while you browse the web"
        case privacy = "Privacy"
        case privateTab = "Private"
        case privateEmpty = "Ecosia won’t remember the pages you visited, your search history or your autofill information once you close a tab. Your searches still contribute to trees."
        case relevantResults = "Relevant results based on past searches"
        case safeSearch = "Safe search"
        case search = "Search"
        case searchRegion = "Search region"
        case sendFeedback = "Send feedback"
        case shop = "Shop"
        case shownUnderSearchField = "Shown under the search field"
        case stories = "Stories"
        case strict = "Strict"
        case terms = "Terms and conditions"
        case today = "Today"
        case trees = "TREES"
        case treesPlantedWithEcosia = "TREES PLANTED WITH ECOSIA"
        case useTheseCompanies = "Start using these green companies to plant more trees and become more sustainable"
        case version = "Version %@"
        case weUseTheProfit = "We use the profit from your searches to plant trees where they are needed most"
        case websitesWillAlwaysOpen = "Websites will always open with Ecosia, planting even more trees"
        case youNeedAround45 = "You need around 45 searches to plant a tree. Keep going!"
    }
}
