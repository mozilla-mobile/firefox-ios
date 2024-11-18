// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Storage
import UIKit

public enum PresentationStyle {
    case centered // used in the home panels
    case bottom // used to display the menu on phone sized devices
    case popover // when displayed on the iPad
}

class PhotonActionSheetViewModel: FeatureFlaggable {
    // MARK: - Properties
    var actions: [[PhotonRowActions]]
    var modalStyle: UIModalPresentationStyle
    private let logger: Logger

    var closeButtonTitle: String?
    var site: Site?
    var title: String?

    var presentationStyle: PresentationStyle {
        return modalStyle.getPhotonPresentationStyle()
    }

    private enum SheetStyle {
        case site, title, other
    }

    // Style is based on what the view model was init with
    private var sheetStyle: SheetStyle {
        if site != nil {
            return .site
        } else if title != nil {
            return .title
        } else {
            return .other
        }
    }

    // MARK: - Initializers
    init(actions: [[PhotonRowActions]],
         site: Site? = nil,
         modalStyle: UIModalPresentationStyle,
         logger: Logger = DefaultLogger.shared) {
        self.actions = actions
        self.site = site
        self.modalStyle = modalStyle
        self.logger = logger
    }

    init(actions: [[PhotonRowActions]],
         closeButtonTitle: String? = nil,
         title: String? = nil,
         modalStyle: UIModalPresentationStyle,
         isMainMenu: Bool = false,
         isMainMenuInverted: Bool = false,
         logger: Logger = DefaultLogger.shared) {
        self.actions = actions
        self.closeButtonTitle = closeButtonTitle
        self.title = title
        self.modalStyle = modalStyle

        self.isMainMenu = isMainMenu
        self.isMainMenuInverted = isMainMenuInverted
        self.logger = logger
        setMainMenuStyle()
    }

    // MARK: - Main menu (Hamburger menu)

    var isMainMenu = false
    var isAtTopMainMenu = false
    var availableMainMenuHeight: CGFloat = 0

    /// The main menu (or hamburger menu) can be a very long menu and it has to scroll most of the times.
    /// One of the design requirements is that the long menu is opened to see the last item first.
    /// Since tableviews shows the first row by default, we inverse the menu to show last item first.
    /// This avoid us having to call Apple's API to scroll the tableview (with scrollToRow or
    /// with setContentOffset) which was causing an unwanted content size change (and
    /// menu apparation was wonky).
    var isMainMenuInverted = false

    private func setMainMenuStyle() {
        guard isMainMenuInverted else { return }

        // Inverse database. The database is made up of multidimensional arrays, so multiple
        // reverse actions are required.
        actions = actions.map { $0.reversed() }.reversed()

        // Flip cells
        actions.forEach { $0.forEach { $0.items.forEach { $0.isFlipped = true } } }
    }

    // Main menu is inverted if hamburger icon is at the bottom
    // It isn't inverted for edge case of iPhone in landscape mode with top search bar (when toolbar isn't shown)
    static func hasInvertedMainMenu(trait: UITraitCollection, isBottomSearchBar: Bool) -> Bool {
        let showingToolbar = trait.verticalSizeClass != .compact && trait.horizontalSizeClass != .regular
        let isIphoneEdgeCase = !isBottomSearchBar && !showingToolbar
        return PhotonActionSheetViewModel.isSmallSizeForTraitCollection(trait: trait) && !isIphoneEdgeCase
    }

    // MARK: - TableView

    func getViewHeader(tableView: UITableView, section: Int) -> UIView? {
        switch sheetStyle {
        case .site:
            guard let site = site else { break }
            guard let header = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: PhotonActionSheetSiteHeaderView.cellIdentifier
            ) as? PhotonActionSheetSiteHeaderView else {
                logger.log("Failed to dequeue PhotonActionSheetSiteHeaderView",
                           level: .fatal,
                           category: .library)
                return UIView()
            }
            header.configure(with: site)
            return header

        case .title:
            guard let title = title else { break }
            if section > 0 {
                return tableView.dequeueReusableHeaderFooterView(
                    withIdentifier: PhotonActionSheetLineSeparator.cellIdentifier)
            } else {
                guard let header = tableView.dequeueReusableHeaderFooterView(
                    withIdentifier: PhotonActionSheetTitleHeaderView.cellIdentifier
                ) as? PhotonActionSheetTitleHeaderView else {
                    logger.log("Failed to dequeue PhotonActionSheetTitleHeaderView",
                               level: .fatal,
                               category: .library)
                    return UIView()
                }
                header.configure(with: title)
                return header
            }

        case .other:
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: PhotonActionSheetSeparator.cellIdentifier)
        }

        return tableView.dequeueReusableHeaderFooterView(withIdentifier: PhotonActionSheetSeparator.cellIdentifier)
    }

    func getHeaderHeightForSection(section: Int) -> CGFloat {
        if section == 0 {
            return getHeaderHeightForFirstSection()
        } else {
            return PhotonActionSheet.UX.separatorRowHeight
        }
    }

    private func getHeaderHeightForFirstSection() -> CGFloat {
        switch sheetStyle {
        case .site:
            return UITableView.automaticDimension
        case .title:
            return PhotonActionSheet.UX.titleHeaderSectionHeight
        case .other:
            return 0
        }
    }

    // MARK: - Pop over style

    // Arrow direction is .any type on iPad, unless it's in small size.
    // On iPhone there's never an arrow
    func getPossibleArrowDirections(trait: UITraitCollection) -> UIPopoverArrowDirection {
        let isSmallSize = PhotonActionSheetViewModel.isSmallSizeForTraitCollection(trait: trait)
        return isSmallSize ? UIPopoverArrowDirection(rawValue: 0) : .any
    }

    func getMainMenuPopOverMargins(
        trait: UITraitCollection,
        view: UIView,
        presentedOn viewController: UIViewController
    ) -> UIEdgeInsets {
        if PhotonActionSheetViewModel.isSmallSizeForTraitCollection(trait: trait) {
            return getSmallSizeMargins(view: view, presentedOn: viewController)
        } else {
            return getIpadMargins(view: view, presentedOn: viewController)
        }
    }

    private func getIpadMargins(view: UIView, presentedOn viewController: UIViewController) -> UIEdgeInsets {
        // Save available space
        let viewControllerHeight = viewController.view.frame.size.height
        availableMainMenuHeight = viewControllerHeight - PhotonActionSheet.UX.bigSpacing * 2
        isAtTopMainMenu = true

        return UIEdgeInsets(equalInset: PhotonActionSheet.UX.bigSpacing)
    }

    // Small size is either iPhone or iPad in multitasking mode
    private func getSmallSizeMargins(view: UIView, presentedOn viewController: UIViewController) -> UIEdgeInsets {
        // Align menu icons with popover icons
        let extraLandscapeSpacing: CGFloat = UIWindow.isLandscape ? 10 : 0
        let isToolbarRefactorEnabled = featureFlags.isFeatureEnabled(.toolbarRefactor, checking: .buildOnly)
        let statusIconSize = isToolbarRefactorEnabled ? 0 : PhotonActionSheetView.UX.StatusIconSize.width
        let halfFrameWidth = view.frame.size.width / 2
        let rightInset = halfFrameWidth - PhotonActionSheet.UX.spacing - statusIconSize / 2 + extraLandscapeSpacing

        // Calculate top and bottom insets
        let convertedPoint = view.convert(view.frame.origin, to: viewController.view)
        let viewControllerHeight = viewController.view.frame.size.height
        isAtTopMainMenu = convertedPoint.y < viewControllerHeight / 2
        let topInset = isAtTopMainMenu ? UIConstants.ToolbarHeight : PhotonActionSheet.UX.spacing
        let bottomInset = isAtTopMainMenu ? PhotonActionSheet.UX.smallSpacing : PhotonActionSheet.UX.bigSpacing

        // Save available space so we can calculate the needed menu height later on
        let topMenuHeight = convertedPoint.y + view.frame.height
        let bottomMenuHeight = viewControllerHeight - convertedPoint.y - view.frame.height
        let buttonSpace = isAtTopMainMenu ? topMenuHeight : bottomMenuHeight
        let insetHeight = buttonSpace - bottomInset - topInset
        availableMainMenuHeight = viewControllerHeight - insetHeight - viewController.view.safeAreaInsets.top

        return UIEdgeInsets(top: topInset,
                            left: PhotonActionSheet.UX.spacing,
                            bottom: bottomInset,
                            right: rightInset)
    }

    // We use small size for iPhone and on iPad in multitasking mode
    static func isSmallSizeForTraitCollection(trait: UITraitCollection) -> Bool {
        return trait.verticalSizeClass == .compact || trait.horizontalSizeClass == .compact
    }

    func popOverWidthForTraitCollection(trait: UITraitCollection) -> CGFloat {
        let isSmallWidth = PhotonActionSheetViewModel.isSmallSizeForTraitCollection(trait: trait)
        return isSmallWidth ? 300 : 400
    }
}
