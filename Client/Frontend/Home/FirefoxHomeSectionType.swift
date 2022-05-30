// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum FirefoxHomeSectionType: Int, CaseIterable {
    case logoHeader
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

    func cellHeight() -> CGFloat {
        switch self {
        case .pocket: return FirefoxHomeViewModel.UX.homeHorizontalCellHeight * FxHomePocketViewModel.numberOfItemsInColumn
        case .jumpBackIn: return FirefoxHomeViewModel.UX.homeHorizontalCellHeight
        case .recentlySaved: return FirefoxHomeViewModel.UX.recentlySavedCellHeight
        case .historyHighlights: return FirefoxHomeViewModel.UX.historyHighlightsCellHeight
        case .topSites: return FirefoxHomeViewModel.UX.topSitesHeight
        case .customizeHome: return FirefoxHomeViewModel.UX.customizeHomeHeight
        case .logoHeader: return FirefoxHomeViewModel.UX.logoHeaderHeight
        }
    }

    // TODO: Laurie
//    // Pocket, historyHighlight, recently saved and jump back in should have full width and add inset in their respective sections
//    // TODO: https://mozilla-hub.atlassian.net/browse/FXIOS-3928
//    // Fix pocket & recently saved cell layout to be able to see next column to enable set full width here and set inset in section
//    var parentMinimumInset: CGFloat {
//        switch self {
////        case .recentlySaved: return 0
////        case .pocket: return 0
//        case .jumpBackIn, .historyHighlights, .topSites: return 0
//        default: return FirefoxHomeViewModel.UX.minimumInsets
//        }
//    }
//
//    /*
//     There are edge cases to handle when calculating section insets
//    - An iPhone 7+ is considered regular width when in landscape
//    - An iPad in 66% split view is still considered regular width
//     */
//    func sectionInsets(_ traits: UITraitCollection, frameWidth: CGFloat) -> CGFloat {
//        var currentTraits = traits
//        if (traits.horizontalSizeClass == .regular && UIScreen.main.bounds.size.width != frameWidth) || UIDevice.current.userInterfaceIdiom == .phone {
//            currentTraits = UITraitCollection(horizontalSizeClass: .compact)
//        }
//        var insets = FirefoxHomeViewModel.UX.sectionInsetsForSizeClass[currentTraits.horizontalSizeClass]
//        let window = UIWindow.keyWindow
//        let safeAreaInsets = window?.safeAreaInsets.left ?? 0
//        insets += parentMinimumInset + safeAreaInsets
//        return insets
//    }
//
//    func cellSize(for traits: UITraitCollection, frameWidth: CGFloat) -> CGSize {
//        let height = cellHeight()
//        let inset = sectionInsets(traits, frameWidth: frameWidth) * 2
//
//        return CGSize(width: frameWidth - inset, height: height)
//    }

    var headerView: UIView? {
        let view = ASHeaderView()
        view.title = title
        return view
    }

    var cellIdentifier: String {
        switch self {
        case .logoHeader: return FxHomeLogoHeaderCell.cellIdentifier
        case .topSites: return "" // Top sites has more than 1 cell type, dequeuing is done through FxHomeSectionHandler protocol
        case .pocket: return "" // Pocket has more than 1 cell type, dequeuing is done through FxHomeSectionHandler protocol
        case .jumpBackIn: return FxHomeHorizontalCell.cellIdentifier
        case .recentlySaved: return FxHomeRecentlySavedCell.cellIdentifier
        case .historyHighlights: return HistoryHighlightsCell.cellIdentifier
        case .customizeHome: return FxHomeCustomizeHomeView.cellIdentifier
        }
    }

    static var cellTypes: [ReusableCell.Type] {
        return [FxHomeLogoHeaderCell.self,
                TopSiteItemCell.self,
                EmptyTopSiteCell.self,
                FxHomeHorizontalCell.self,
                FxHomePocketDiscoverMoreCell.self,
                FxHomeRecentlySavedCell.self,
                HistoryHighlightsCell.self,
                FxHomeCustomizeHomeView.self
        ]
    }

    init(at indexPath: IndexPath) {
        self.init(rawValue: indexPath.section)!
    }

    init(_ section: Int) {
        self.init(rawValue: section)!
    }
}
