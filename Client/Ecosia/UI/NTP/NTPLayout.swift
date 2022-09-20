/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

protocol NTPLayoutHighlightDataSource: AnyObject {
    func ntpLayoutHighlightText() -> String?
}

struct FirefoxHomeUX {
    static let highlightCellHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 250 : 200
    static let sectionInsetsForSizeClass = UXSizeClasses(compact: 0, regular: 101, other: 16)
    static let numberOfItemsPerRowForSizeClassIpad = UXSizeClasses(compact: 4, regular: 6, other: 2)
    static let spacingBetweenSections: CGFloat = 24
    static let SectionInsetsForIpad: CGFloat = 101
    static let MinimumInsets: CGFloat = 16
    static let LibraryShortcutsHeight: CGFloat = 100
    static let LibraryShortcutsMaxWidth: CGFloat = 350
    static let SearchBarHeight: CGFloat = 60
    static let TopSitesInsets: CGFloat = 6
    static let customizeHomeHeight: CGFloat = 100
    static var ScrollSearchBarOffset: CGFloat {
        (UIDevice.current.userInterfaceIdiom == .phone) ? SearchBarHeight : 0
    }
    static var ToolbarHeight: CGFloat {
        (UIDevice.current.userInterfaceIdiom == .phone && UIDevice.current.orientation.isPortrait) ? 46 : 0
    }
}

class NTPLayout: UICollectionViewFlowLayout {

    // TODO: merge with HomepageSectionType
    enum Section: Int, CaseIterable {
            case logo
            case search
            case libraryShortcuts
            case topSites
            case impact
            case emptySpace

            var title: String? {
                switch self {
                case .topSites: return .AppMenu.AppMenuTopSitesTitleString
                default: return nil
                }
            }

            var headerHeight: CGSize {
                switch self {
                case .topSites:
                    return CGSize(width: 50, height: 54)
                default:
                    return .zero
                }
            }

            func cellHeight(_ traits: UITraitCollection, width: CGFloat) -> CGFloat {
                switch self {
                case .impact: return .nan
                case .logo: return 100
                case .search: return UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).pointSize + 25 + 16
                case .topSites: return 0 //calculated dynamically
                case .libraryShortcuts: return FirefoxHomeUX.LibraryShortcutsHeight
                case .emptySpace:
                    return .nan // will be calculated outside of enum
                }
            }

            /*
             There are edge cases to handle when calculating section insets
            - An iPhone 7+ is considered regular width when in landscape
            - An iPad in 66% split view is still considered regular width
             */
            func sectionInsets(_ traits: UITraitCollection, frameWidth: CGFloat) -> CGFloat {
                var currentTraits = traits
                if (traits.horizontalSizeClass == .regular && UIApplication.shared.statusBarOrientation.isPortrait) || UIDevice.current.userInterfaceIdiom == .phone {
                    currentTraits = UITraitCollection(horizontalSizeClass: .compact)
                }
                var insets = FirefoxHomeUX.sectionInsetsForSizeClass[currentTraits.horizontalSizeClass]

                switch self {
                case .libraryShortcuts, .topSites, .search, .impact:
                    let window = UIApplication.shared.keyWindow
                    let safeAreaInsets = window?.safeAreaInsets.left ?? 0
                    insets += FirefoxHomeUX.MinimumInsets + safeAreaInsets

                    /* Ecosia: center layout in landscape for iPhone */
                    if UIApplication.shared.statusBarOrientation.isLandscape, UIDevice.current.userInterfaceIdiom == .phone {
                        insets = frameWidth / 4
                    }

                    return insets
                case .logo:
                    insets += FirefoxHomeUX.TopSitesInsets
                    return insets
                case .emptySpace:
                    return 0
                }
            }

            func cellSize(for traits: UITraitCollection, frameWidth: CGFloat) -> CGSize {
                let height = cellHeight(traits, width: frameWidth)
                let inset = sectionInsets(traits, frameWidth: frameWidth) * 2
                let width = maxWidth(for: traits, frameWidth: (frameWidth - inset))
                return CGSize(width: width, height: height)
            }

            func maxWidth(for traits: UITraitCollection, frameWidth: CGFloat) -> CGFloat {
                var width = frameWidth
                if traits.userInterfaceIdiom == .pad {
                    let maxWidth: CGFloat = UIApplication.shared.statusBarOrientation.isPortrait ? 375 : 520
                    switch self {
                    case .logo, .search, .libraryShortcuts:
                        width = min(375, width)
                    default:
                        width = min(520, width)
                    }
                }
                return width
            }
/*
            var headerView: UIView? {
                let view = ASHeaderView()
                view.title = title
                return view
            }

            var cellIdentifier: String {
                return "\(cellType)"
            }

            var cellType: UICollectionViewCell.Type {
                switch self {
                case .impact: return TreesCell.self
                case .logo: return LogoCell.self
                case .search: return SearchbarCell.self
                case .topSites: return ASHorizontalScrollCell.self
                case .libraryShortcuts: return ASLibraryCell.self
                case .emptySpace: return EmptyCell.self
                }
            }
*/
            init(at indexPath: IndexPath) {
                self.init(rawValue: indexPath.section)!
            }

            init(_ section: Int) {
                self.init(rawValue: section)!
            }
    }



    private var totalHeight: CGFloat = 0
    weak var highlightDataSource: NTPLayoutHighlightDataSource?

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attr = super.layoutAttributesForElements(in: rect) else { return nil}

        var searchMaxY: CGFloat = 0
        var impactMaxY: CGFloat = 0

        // find search cell
        if let search = attr.first(where: { $0.representedElementCategory == .cell && $0.indexPath.section == Section.search.rawValue  }) {
            searchMaxY = search.frame.maxY
        }

        // find impact cell
        if let impact = attr.first(where: { $0.representedElementCategory == .cell && $0.indexPath.section == Section.impact.rawValue  }) {
            impactMaxY = impact.frame.maxY

            // find counter overlay cell
            if let tooltip = attr.first(where: { $0.representedElementCategory == .supplementaryView && $0.indexPath.section == Section.impact.rawValue }) {
                tooltip.frame = impact.frame

                if let text = highlightDataSource?.ntpLayoutHighlightText() {
                    let font = UIFont.preferredFont(forTextStyle: .callout)
                    let height = text.heightWithConstrainedWidth(width: impact.bounds.width - 4 * NTPTooltip.margin, font: font) + 2 * NTPTooltip.containerMargin + NTPTooltip.margin
                    tooltip.frame.size.height = height
                    tooltip.frame.origin.y -= (height - NTPImpactCell.topMargin)
                }
            }
        }

        // find and update empty cell
        if let emptyIndex = attr.firstIndex(where: { $0.representedElementCategory == .cell && $0.indexPath.section == Section.emptySpace.rawValue  }) {

            let frameHeight = collectionView?.frame.height ?? 0
            var height = frameHeight - impactMaxY + searchMaxY - FirefoxHomeUX.ScrollSearchBarOffset
            height = max(0, height)

            // update frame
            let element = attr[emptyIndex]
            totalHeight = element.frame.origin.y + height
        }
        return attr
    }

    override var collectionViewContentSize: CGSize {
        let size = super.collectionViewContentSize
        return .init(width: size.width, height: totalHeight)
    }

    override func prepare() {
        super.prepare()
    }
}

extension String {
    fileprivate func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)
        return boundingBox.height
    }
}
