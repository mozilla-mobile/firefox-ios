// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage
import UIKit

class PhotonActionSheetViewModel {

    // MARK: - Properties
    var actions: [[PhotonRowActions]]
    var modalStyle: UIModalPresentationStyle

    var closeButtonTitle: String? = nil
    var site: Site? = nil
    var title: String? = nil
    var tintColor = UIColor.theme.actionMenu.foreground

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
         modalStyle: UIModalPresentationStyle) {
        self.actions = actions
        self.site = site
        self.modalStyle = modalStyle
    }

    init(actions: [[PhotonRowActions]],
         closeButtonTitle: String? = nil,
         title: String? = nil,
         modalStyle: UIModalPresentationStyle,
         isMainMenu: Bool = false,
         isMainMenuInverted: Bool = false) {

        self.actions = actions
        self.closeButtonTitle = closeButtonTitle
        self.title = title
        self.modalStyle = modalStyle

        self.isMainMenu = isMainMenu
        self.isMainMenuInverted = isMainMenuInverted
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
    var isMainMenuInverted: Bool = false
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
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: PhotonActionSheet.UX.SiteHeaderName) as! PhotonActionSheetSiteHeaderView
            header.tintColor = tintColor
            header.configure(with: site)
            return header

        case .title:
            guard let title = title else { break }
            if section > 0 {
                return tableView.dequeueReusableHeaderFooterView(withIdentifier: PhotonActionSheet.UX.LineSeparatorSectionHeader)
            } else {
                let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: PhotonActionSheet.UX.TitleHeaderName) as! PhotonActionSheetTitleHeaderView
                header.tintColor = tintColor
                header.configure(with: title)
                return header
            }

        case .other:
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: PhotonActionSheet.UX.SeparatorSectionHeader)
        }

        return tableView.dequeueReusableHeaderFooterView(withIdentifier: PhotonActionSheet.UX.SeparatorSectionHeader)
    }

    func getHeaderHeightForSection(section: Int) -> CGFloat {
        if section == 0 {
            return getHeaderHeightForFirstSection()
        } else {
            return PhotonActionSheet.UX.SeparatorRowHeight
        }
    }

    private func getHeaderHeightForFirstSection() -> CGFloat {
        switch sheetStyle {
        case .site:
            return PhotonActionSheet.UX.TitleHeaderSectionHeightWithSite
        case .title:
            return PhotonActionSheet.UX.TitleHeaderSectionHeight
        case .other:
            return 0
        }
    }

    // MARK: - Pop over style

    // Arrow direction is .any type on iPad, unless it's in small size.
    // On iPhone there's never an arrow
    func getPossibleArrowDirections(trait: UITraitCollection) -> UIPopoverArrowDirection {
        let isSmallSize = PhotonActionSheetViewModel.isSmallSizeForTraitCollection(trait: trait)
        return isSmallSize ? UIPopoverArrowDirection.init(rawValue: 0) : .any
    }

    func getMainMenuPopOverMargins(trait: UITraitCollection, view: UIView, presentedOn viewController: UIViewController) -> UIEdgeInsets {
        if PhotonActionSheetViewModel.isSmallSizeForTraitCollection(trait: trait) {
            return getSmallSizeMargins(view: view, presentedOn: viewController)
        } else {
            return getIpadMargins(view: view, presentedOn: viewController)
        }
    }

    private func getIpadMargins(view: UIView, presentedOn viewController: UIViewController) -> UIEdgeInsets {
        // Save available space
        let viewControllerHeight = viewController.view.frame.size.height
        availableMainMenuHeight = viewControllerHeight - PhotonActionSheet.UX.BigSpacing * 2
        isAtTopMainMenu = true

        return UIEdgeInsets.init(equalInset: PhotonActionSheet.UX.BigSpacing)
    }

    // Small size is either iPhone or iPad in multitasking mode
    private func getSmallSizeMargins(view: UIView, presentedOn viewController: UIViewController) -> UIEdgeInsets {
        // Align menu icons with popover icons
        let extraLandscapeSpacing: CGFloat = UIWindow.isLandscape ? 10 : 0
        let statusIconSize = PhotonActionSheetView.UX.StatusIconSize.width
        let rightInset = view.frame.size.width / 2 - PhotonActionSheet.UX.Spacing - statusIconSize / 2 + extraLandscapeSpacing

        // Calculate top and bottom insets
        let convertedPoint = view.convert(view.frame.origin, to: viewController.view)
        let viewControllerHeight = viewController.view.frame.size.height
        isAtTopMainMenu = convertedPoint.y < viewControllerHeight / 2
        let topInset = isAtTopMainMenu ? UIConstants.ToolbarHeight : PhotonActionSheet.UX.Spacing
        let bottomInset = isAtTopMainMenu ? PhotonActionSheet.UX.SmallSpacing : PhotonActionSheet.UX.BigSpacing

        // Save available space so we can calculate the needed menu height later on
        let buttonSpace = isAtTopMainMenu ? (convertedPoint.y + view.frame.height) : (viewControllerHeight - convertedPoint.y - view.frame.height)
        availableMainMenuHeight = viewControllerHeight - buttonSpace - bottomInset - topInset - viewController.view.safeAreaInsets.top

        return UIEdgeInsets(top: topInset,
                            left: PhotonActionSheet.UX.Spacing,
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
