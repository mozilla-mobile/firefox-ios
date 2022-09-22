// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum HomepageSectionType: Int, CaseIterable {
    case logoHeader
    case libraryShortcuts
    case topSites
    case impact

    var title: String? {
        switch self {
        case .topSites: return .ASShortcutsTitle
        default: return nil
        }
    }

    var cellIdentifier: String {
        switch self {
        case .logoHeader: return NTPLogoCell.cellIdentifier
        case .libraryShortcuts: return NTPLibraryCell.cellIdentifier
        case .topSites: return "" // Top sites has more than 1 cell type, dequeuing is done through FxHomeSectionHandler protocol
        case .impact: return NTPImpactCell.cellIdentifier
         }
    }

    static var cellTypes: [ReusableCell.Type] {
        return [NTPLogoCell.self,
                TopSiteItemCell.self,
                EmptyTopSiteCell.self,
                NTPLibraryCell.self,
                NTPImpactCell.self,
        ]
    }

    init(_ section: Int) {
        self.init(rawValue: section)!
    }

    func sectionInsets(_ traits: UITraitCollection) -> CGFloat {
        var currentTraits = traits
        if (traits.horizontalSizeClass == .regular && UIApplication.shared.statusBarOrientation.isPortrait) || UIDevice.current.userInterfaceIdiom == .phone {
            currentTraits = UITraitCollection(horizontalSizeClass: .compact)
        }
        // TODO: move FirefoxHomeUX
        var insets = FirefoxHomeUX.sectionInsetsForSizeClass[currentTraits.horizontalSizeClass]

        switch self {
        case .libraryShortcuts, .topSites, .impact:
            let window = UIApplication.shared.keyWindow
            let safeAreaInsets = window?.safeAreaInsets.left ?? 0
            insets += FirefoxHomeUX.MinimumInsets + safeAreaInsets

            /* Ecosia: center layout in landscape for iPhone */
            if UIApplication.shared.statusBarOrientation.isLandscape, UIDevice.current.userInterfaceIdiom == .phone {
                insets = UIScreen.main.bounds.width / 4
            }

            return insets
        default:
            return 0
        }
    }
}
