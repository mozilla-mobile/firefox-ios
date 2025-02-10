// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

enum HomepageSectionType: Int, CaseIterable {
    case homepageHeader
    case messageCard
    case topSites
    case jumpBackIn
    case bookmarks
    case historyHighlights
    case pocket
    case customizeHome

    var title: String? {
        switch self {
        case .pocket: return .FirefoxHomepage.Pocket.SectionTitle
        case .jumpBackIn: return .FirefoxHomeJumpBackInSectionTitle
        case .bookmarks: return .BookmarksSectionTitle
        case .historyHighlights: return .FirefoxHomepage.HistoryHighlights.Title
        default: return nil
        }
    }

    var cellIdentifier: String {
        switch self {
        case .homepageHeader: return LegacyHomepageHeaderCell.cellIdentifier
        case .messageCard: return LegacyHomepageMessageCardCell.cellIdentifier
        // Top sites has more than 1 cell type, dequeuing is done through FxHomeSectionHandler protocol
        case .topSites: return ""
        // Pocket has more than 1 cell type, dequeuing is done through FxHomeSectionHandler protocol
        case .pocket: return ""
        // JumpBackIn has more than 1 cell type, dequeuing is done through FxHomeSectionHandler protocol
        case .jumpBackIn: return ""
        case .bookmarks: return LegacyBookmarksCell.cellIdentifier
        case .historyHighlights: return HistoryHighlightsCell.cellIdentifier
        case .customizeHome: return CustomizeHomepageSectionCell.cellIdentifier
        }
    }

    static var cellTypes: [ReusableCell.Type] {
        return [LegacyHomepageHeaderCell.self,
                LegacyHomepageMessageCardCell.self,
                TopSiteItemCell.self,
                EmptyTopSiteCell.self,
                LegacyJumpBackInCell.self,
                PocketDiscoverCell.self,
                LegacyPocketStandardCell.self,
                LegacyBookmarksCell.self,
                HistoryHighlightsCell.self,
                CustomizeHomepageSectionCell.self,
                LegacySyncedTabCell.self
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
