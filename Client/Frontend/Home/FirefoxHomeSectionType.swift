// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum FirefoxHomeSectionType: Int, CaseIterable {
    case logoHeader
    case topSites
    case libraryShortcuts
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
        case .libraryShortcuts: return .AppMenu.AppMenuLibraryTitleString
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
        case .libraryShortcuts: return FirefoxHomeViewModel.UX.libraryShortcutsHeight
        case .customizeHome: return FirefoxHomeViewModel.UX.customizeHomeHeight
        case .logoHeader: return FirefoxHomeViewModel.UX.logoHeaderHeight
        }
    }

    // Pocket, historyHighlight, recently saved and jump back in should have full width and add inset in their respective sections
    // TODO: https://mozilla-hub.atlassian.net/browse/FXIOS-3928
    // Fix pocket & recently saved cell layout to be able to see next column to enable set full width here and set inset in section
    var parentMinimumInset: CGFloat {
        switch self {
//        case .recentlySaved: return 0
//        case .pocket: return 0
        case .jumpBackIn, .historyHighlights, .topSites: return 0
        default: return FirefoxHomeViewModel.UX.minimumInsets
        }
    }

    /*
     There are edge cases to handle when calculating section insets
    - An iPhone 7+ is considered regular width when in landscape
    - An iPad in 66% split view is still considered regular width
     */
    func sectionInsets(_ traits: UITraitCollection, frameWidth: CGFloat) -> CGFloat {
        var currentTraits = traits
        if (traits.horizontalSizeClass == .regular && UIScreen.main.bounds.size.width != frameWidth) || UIDevice.current.userInterfaceIdiom == .phone {
            currentTraits = UITraitCollection(horizontalSizeClass: .compact)
        }
        var insets = FirefoxHomeViewModel.UX.sectionInsetsForSizeClass[currentTraits.horizontalSizeClass]
        let window = UIWindow.keyWindow
        let safeAreaInsets = window?.safeAreaInsets.left ?? 0
        insets += parentMinimumInset + safeAreaInsets
        return insets
    }

    func cellSize(for traits: UITraitCollection, frameWidth: CGFloat) -> CGSize {
        let height = cellHeight()
        let inset = sectionInsets(traits, frameWidth: frameWidth) * 2

        return CGSize(width: frameWidth - inset, height: height)
    }

    var headerView: UIView? {
        let view = ASHeaderView()
        view.title = title
        return view
    }

    var cellIdentifier: String {
        switch self {
        case .logoHeader: return FxHomeLogoHeaderCell.cellIdentifier
        case .topSites: return TopSiteCollectionCell.cellIdentifier
        case .pocket: return FxHomePocketCollectionCell.cellIdentifier
        case .jumpBackIn: return FxHomeJumpBackInCollectionCell.cellIdentifier
        case .recentlySaved: return FxHomeRecentlySavedCollectionCell.cellIdentifier
        case .historyHighlights: return FxHomeHistoryHighlightsCollectionCell.cellIdentifier
        case .libraryShortcuts: return  ASLibraryCell.cellIdentifier
        case .customizeHome: return FxHomeCustomizeHomeView.cellIdentifier
        }
    }

    var cellType: UICollectionViewCell.Type {
        switch self {
        case .logoHeader: return FxHomeLogoHeaderCell.self
        case .topSites: return TopSiteCollectionCell.self
        case .pocket: return FxHomePocketCollectionCell.self
        case .jumpBackIn: return FxHomeJumpBackInCollectionCell.self
        case .recentlySaved: return FxHomeRecentlySavedCollectionCell.self
        case .historyHighlights: return FxHomeHistoryHighlightsCollectionCell.self
        case .libraryShortcuts: return ASLibraryCell.self
        case .customizeHome: return FxHomeCustomizeHomeView.self
        }
    }

    init(at indexPath: IndexPath) {
        self.init(rawValue: indexPath.section)!
    }

    init(_ section: Int) {
        self.init(rawValue: section)!
    }
}
