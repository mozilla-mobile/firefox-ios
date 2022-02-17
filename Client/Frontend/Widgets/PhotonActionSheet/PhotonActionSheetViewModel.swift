// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage
import UIKit

class PhotonActionSheetViewModel {

    var actions: [[PhotonActionSheetItem]]
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

    init(actions: [[PhotonActionSheetItem]],
         site: Site? = nil,
         modalStyle: UIModalPresentationStyle) {
        self.actions = actions
        self.site = site
        self.modalStyle = modalStyle
    }

    init(actions: [[PhotonActionSheetItem]],
         closeButtonTitle: String? = nil,
         title: String? = nil,
         modalStyle: UIModalPresentationStyle,
         toolbarMenuInversed: Bool = false) {

        self.actions = actions
        self.closeButtonTitle = closeButtonTitle
        self.title = title
        self.modalStyle = modalStyle

        self.toolbarMenuInversed = toolbarMenuInversed
        setToolbarMenuStyle()
    }

    /// The toolbar menu can be a very long menu and it has to scroll most of the times.
    /// One of the design requirements is that the long menu is opened to see the last item first.
    /// Since tableviews shows the first row by default, we inverse the menu to show last item first.
    /// This avoid us having to call Apple's API to scroll the tableview (with scrollToRow or with setContentOffset)
    /// which was causing an unwanted content size change (and menu apparation was wonky).
    var toolbarMenuInversed: Bool = false
    func setToolbarMenuStyle() {
        guard toolbarMenuInversed, UIDevice.current.userInterfaceIdiom != .pad else { return }

        // Inverse database
        actions = actions.map { $0.reversed() }
        actions.reverse()

        // Flip cells
        actions.forEach { $0.forEach { $0.isFlipped = true } }
    }

    // MARK: - TableView

    func getViewHeader(tableView: UITableView, section: Int) -> UIView? {
        switch sheetStyle {
        case .site:
            guard let site = site else { break }
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: PhotonActionSheetUX.SiteHeaderName) as! PhotonActionSheetSiteHeaderView
            header.tintColor = tintColor
            header.configure(with: site)
            return header

        case .title:
            guard let title = title else { break }
            if section > 0 {
                return tableView.dequeueReusableHeaderFooterView(withIdentifier: "SeparatorSectionHeader")
            } else {
                let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: PhotonActionSheetUX.TitleHeaderName) as! PhotonActionSheetTitleHeaderView
                header.tintColor = tintColor
                header.configure(with: title)
                return header
            }

        case .other:
            return defaultHeaderView()
        }

        return defaultHeaderView()
    }

    func getHeaderHeightForSection(section: Int) -> CGFloat {
        if section == 0 {
            return getHeaderHeightForFirstSection()
        } else {
            return PhotonActionSheetUX.SeparatorRowHeight
        }
    }

    private func getHeaderHeightForFirstSection() -> CGFloat {
        switch sheetStyle {
        case .site:
            return PhotonActionSheetUX.TitleHeaderSectionHeightWithSite
        case .title:
            return PhotonActionSheetUX.TitleHeaderSectionHeight
        case .other:
            return 0
        }
    }

    private func defaultHeaderView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.theme.tableView.separator
        return view
    }

    // MARK: - Pop over style

    func getPossibleArrowDirections() -> UIPopoverArrowDirection {
        return UIDevice.current.userInterfaceIdiom == .pad ? .any : UIPopoverArrowDirection.init(rawValue: 0)
    }

    func getPopOverMargins(view: UIView) -> UIEdgeInsets {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return getIpadMargins(view: view)
        } else {
            return getiPhoneMargins(view: view)
        }
    }

    private func getIpadMargins(view: UIView) -> UIEdgeInsets {
        return UIEdgeInsets.init(equalInset: PhotonActionSheetUX.iPadSpacing)
    }

    private func getiPhoneMargins(view: UIView) -> UIEdgeInsets {
        // Top spacing: Make sure at least half of a cell height is visible at the top of the popover if content is scrollable
        let rowHeight = PhotonActionSheetUX.RowHeight
        let estimatedRowNumber = (view.frame.size.height - 3 * PhotonActionSheetUX.SeparatorRowHeight) / rowHeight
        let topSpacing = view.frame.size.height - estimatedRowNumber * rowHeight

        // Align menu icons with popover icons
        let leftRightSpacing = view.frame.size.width / 2 - PhotonActionSheetCellUX.Padding - PhotonActionSheetCellUX.StatusIconSize.width / 2

        return UIEdgeInsets(top: topSpacing,
                            left: leftRightSpacing,
                            bottom: PhotonActionSheetUX.BottomPopOverSheetSpacing,
                            right: leftRightSpacing)
    }

    func popOverWidthForTraitCollection(trait: UITraitCollection) -> CGFloat {
        let isSmallWidth = trait.verticalSizeClass != .compact && trait.horizontalSizeClass != .regular
        return isSmallWidth ? 250 : 400
    }
}
