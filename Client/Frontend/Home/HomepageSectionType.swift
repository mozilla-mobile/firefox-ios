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

}

// Ecosia
private let sectionInsetsForSizeClass = UXSizeClasses(compact: 0, regular: 101, other: 16)
private let MinimumInsets: CGFloat = 16

extension HomepageSectionType {
    func sectionInsets(_ traits: UITraitCollection) -> CGFloat {
        var currentTraits = traits
        let orientation: UIInterfaceOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation ?? .portrait

        if (traits.horizontalSizeClass == .regular && orientation.isPortrait) || UIDevice.current.userInterfaceIdiom == .phone {
            currentTraits = UITraitCollection(horizontalSizeClass: .compact)
        }

        var insets = sectionInsetsForSizeClass[currentTraits.horizontalSizeClass]

        switch self {
        case .libraryShortcuts, .topSites, .impact:
            let window = UIApplication.shared.windows.first(where: \.isKeyWindow)
            let safeAreaInsets = window?.safeAreaInsets.left ?? 0
            insets += MinimumInsets + safeAreaInsets

            /* Ecosia: center layout in landscape for iPhone */
            if orientation.isLandscape,
               UIDevice.current.userInterfaceIdiom == .phone {
                insets = UIScreen.main.bounds.width / 4
            }

            return insets
        default:
            return 0
        }
    }
}
