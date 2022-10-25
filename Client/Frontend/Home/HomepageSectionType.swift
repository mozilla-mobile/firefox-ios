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

private let MinimumInsets: CGFloat = 16

// Ecosia
extension HomepageSectionType {
    func sectionInsets(_ traits: UITraitCollection) -> CGFloat {
        var insets: CGFloat = traits.horizontalSizeClass == .regular ? 100 : 0

        switch self {
        case .libraryShortcuts, .topSites, .impact:
            guard let window = UIApplication.shared.windows.first(where: \.isKeyWindow) else { return MinimumInsets
            }
            let safeAreaInsets = window.safeAreaInsets.left
            insets += MinimumInsets + safeAreaInsets

            let orientation: UIInterfaceOrientation = window.windowScene?.interfaceOrientation ?? .portrait

            /* Ecosia: center layout in iphone landscape or regular size class */
            if traits.horizontalSizeClass == .regular || (orientation.isLandscape && traits.userInterfaceIdiom == .phone) {
                insets = window.bounds.width / 4
            }
            return insets
        default:
            return 0
        }
    }
}
