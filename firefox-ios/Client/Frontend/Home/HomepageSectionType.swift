// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum HomepageSectionType: Int, CaseIterable {
    case logoHeader
    case messageCard
    case topSites
    case jumpBackIn
    case recentlySaved
    case historyHighlights
    case pocket
    case customizeHome

    var title: String? {
        switch self {
        case .pocket: return .FirefoxHomepage.Pocket.SectionTitle
        case .jumpBackIn: return .FirefoxHomeJumpBackInSectionTitle
        case .recentlySaved: return .RecentlySavedSectionTitle
        case .topSites: return .ASShortcutsTitle
        case .historyHighlights: return .FirefoxHomepage.HistoryHighlights.Title
        default: return nil
        }
    }

    var cellIdentifier: String {
        switch self {
        case .logoHeader: return HomeLogoHeaderCell.cellIdentifier
        case .messageCard: return HomepageMessageCardCell.cellIdentifier
        case .topSites: return "" // Top sites has more than 1 cell type, dequeuing is done through FxHomeSectionHandler protocol
        case .pocket: return "" // Pocket has more than 1 cell type, dequeuing is done through FxHomeSectionHandler protocol
        case .jumpBackIn: return "" // JumpBackIn has more than 1 cell type, dequeuing is done through FxHomeSectionHandler protocol
        case .recentlySaved: return RecentlySavedCell.cellIdentifier
        case .historyHighlights: return HistoryHighlightsCell.cellIdentifier
        case .customizeHome: return CustomizeHomepageSectionCell.cellIdentifier
        }
    }

    static var cellTypes: [ReusableCell.Type] {
        return [HomeLogoHeaderCell.self,
                HomepageMessageCardCell.self,
                TopSiteItemCell.self,
                EmptyTopSiteCell.self,
                JumpBackInCell.self,
                PocketDiscoverCell.self,
                PocketStandardCell.self,
                RecentlySavedCell.self,
                HistoryHighlightsCell.self,
                CustomizeHomepageSectionCell.self,
                SyncedTabCell.self
        ]
    }

    init(_ section: Int) {
        self.init(rawValue: section)!
    }

    func newPrivateTabActionTelemetry() {
        switch self {
        case .topSites:
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .newPrivateTab,
                                         value: .topSite)
        case .pocket:
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .newPrivateTab,
                                         value: .pocketSite)
        default: return
        }
    }
}
