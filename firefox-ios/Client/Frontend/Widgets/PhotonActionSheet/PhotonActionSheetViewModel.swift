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

/// This view model is used for our custom Context Menu for long press action throughout the application.
/// It was also used as the Main menu in our application, and the code is a bit tangled in here
/// due to that reason.
@MainActor
class PhotonActionSheetViewModel: FeatureFlaggable {
    // MARK: - Properties
    var actions: [[PhotonRowActions]]
    var modalStyle: UIModalPresentationStyle
    private let logger: Logger

    var closeButtonTitle: String?
    let site: Site?
    var bookmarkFolderTitle: String?
    var title: String?

    var presentationStyle: PresentationStyle {
        return modalStyle.getPhotonPresentationStyle()
    }

    private enum SheetStyle {
        case site, title, bookmarkFolder, other
    }

    // Style is based on what the view model was init with
    private var sheetStyle: SheetStyle {
        if site != nil {
            return .site
        } else if bookmarkFolderTitle != nil {
            return .bookmarkFolder
        } else if title != nil {
            return .title
        } else {
            return .other
        }
    }

    // MARK: - Initializers
    init(actions: [[PhotonRowActions]],
         site: Site? = nil,
         bookmarkFolderTitle: String? = nil,
         modalStyle: UIModalPresentationStyle,
         logger: Logger = DefaultLogger.shared) {
        self.actions = actions
        self.site = site
        self.bookmarkFolderTitle = bookmarkFolderTitle
        self.modalStyle = modalStyle
        self.logger = logger
    }

    init(actions: [[PhotonRowActions]],
         closeButtonTitle: String? = nil,
         title: String? = nil,
         modalStyle: UIModalPresentationStyle,
         logger: Logger = DefaultLogger.shared) {
        self.actions = actions
        self.closeButtonTitle = closeButtonTitle
        self.title = title
        self.modalStyle = modalStyle
        self.logger = logger
        self.site = nil
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
        case .bookmarkFolder:
            guard let bookmarkFolderTitle = bookmarkFolderTitle else { break }
            guard let header = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: PhotonActionSheetSiteHeaderView.cellIdentifier
            ) as? PhotonActionSheetSiteHeaderView else {
                logger.log("Failed to dequeue PhotonActionSheetSiteHeaderView",
                           level: .fatal,
                           category: .library)
                return UIView()
            }
            header.configure(with: bookmarkFolderTitle)
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
        case .site, .bookmarkFolder:
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

    // We use small size for iPhone and on iPad in multitasking mode
    static func isSmallSizeForTraitCollection(trait: UITraitCollection) -> Bool {
        return trait.verticalSizeClass == .compact || trait.horizontalSizeClass == .compact
    }

    func popOverWidthForTraitCollection(trait: UITraitCollection) -> CGFloat {
        let isSmallWidth = PhotonActionSheetViewModel.isSmallSizeForTraitCollection(trait: trait)
        return isSmallWidth ? 300 : 400
    }
}
