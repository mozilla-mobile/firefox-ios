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
    case merino
    case customizeHome

    // TODO: FXIOS-12980: Replace "Stories" title with "Top Stories" string once it is translated in v143
    var title: String? {
        switch self {
        case .merino: return .FirefoxHomepage.Pocket.SectionTitle
        case .jumpBackIn: return .FirefoxHomeJumpBackInSectionTitle
        case .bookmarks: return .BookmarksSectionTitle
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
        case .merino: return ""
        // JumpBackIn has more than 1 cell type, dequeuing is done through FxHomeSectionHandler protocol
        case .jumpBackIn: return ""
        case .bookmarks: return LegacyBookmarksCell.cellIdentifier
        case .customizeHome: return CustomizeHomepageSectionCell.cellIdentifier
        }
    }

    static var cellTypes: [ReusableCell.Type] {
        return [LegacyHomepageHeaderCell.self,
                LegacyHomepageMessageCardCell.self,
                TopSiteItemCell.self,
                EmptyTopSiteCell.self,
                LegacyJumpBackInCell.self,
                LegacyPocketStandardCell.self,
                LegacyBookmarksCell.self,
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
        case .merino:
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .newPrivateTab,
                                         value: .pocketSite)
        default: return
        }
    }
}
