// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage

protocol FirefoxHomeContextMenuHelperDelegate: UIViewController {
    func presentWithModalDismissIfNeeded(_ viewController: UIViewController, animated: Bool)
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool)
}

extension FirefoxHomeContextMenuHelperDelegate {
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool = false) {
        homePanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate, selectNewTab: selectNewTab)
    }
}

class FirefoxHomeContextMenuHelper: HomePanelContextMenu {

    typealias ContextHelperDelegate = FirefoxHomeContextMenuHelperDelegate & UIPopoverPresentationControllerDelegate
    private var viewModel: FirefoxHomeViewModel

    weak var delegate: ContextHelperDelegate?
    var getPopoverSourceRect: ((UIView?) -> CGRect)?

    init(viewModel: FirefoxHomeViewModel) {
        self.viewModel = viewModel
    }

    func presentContextMenu(for site: Site,
                            with sourceView: UIView?,
                            sectionType: FirefoxHomeSectionType,
                            completionHandler: @escaping () -> PhotonActionSheet?
    ) {
        fetchBookmarkStatus(for: site) {
            guard let contextMenu = completionHandler() else { return }
            self.delegate?.present(contextMenu, animated: true, completion: nil)
        }
    }

    func getContextMenuActions(for site: Site, with sourceView: UIView?, sectionType: FirefoxHomeSectionType) -> [PhotonRowActions]? {
        guard let siteURL = URL(string: site.url) else { return nil }

        guard var actions = getDefaultContextMenuActions(for: site,
                                                         delegate: delegate,
                                                         sectionType: sectionType,
                                                         isZeroSearch: viewModel.isZeroSearch)
        else { return nil }

        let bookmarkAction = getBookmarkAction(site: site)
        let shareAction = getShareAction(siteURL: siteURL, sourceView: sourceView)
        actions.append(contentsOf: [bookmarkAction,
                                    shareAction])

        if sectionType == .topSites {
            actions.append(contentsOf: viewModel.topSiteViewModel.getTopSitesAction(site: site))
        }

        return actions
    }

    private func getBookmarkAction(site: Site) -> PhotonRowActions {
        let bookmarkAction: SingleActionViewModel
        if site.bookmarked ?? false {
            bookmarkAction = getRemoveBookmarkAction(site: site)
        } else {
            bookmarkAction = getAddBookmarkAction(site: site)
        }
        return bookmarkAction.items
    }

    private func getRemoveBookmarkAction(site: Site) -> SingleActionViewModel {
        return SingleActionViewModel(title: .RemoveBookmarkContextMenuTitle, iconString: ImageIdentifiers.actionRemoveBookmark, tapHandler: { _ in
            self.viewModel.profile.places.deleteBookmarksWithURL(url: site.url) >>== {
                self.viewModel.topSiteViewModel.tileManager.refreshIfNeeded(forceTopSites: false)
                site.setBookmarked(false)
            }

            TelemetryWrapper.recordEvent(category: .action, method: .delete, object: .bookmark, value: .activityStream)
        })
    }

    private func getAddBookmarkAction(site: Site) -> SingleActionViewModel {
        return SingleActionViewModel(title: .BookmarkContextMenuTitle, iconString: ImageIdentifiers.actionAddBookmark, tapHandler: { _ in
            let shareItem = ShareItem(url: site.url, title: site.title, favicon: site.icon)
            _ = self.viewModel.profile.places.createBookmark(parentGUID: BookmarkRoots.MobileFolderGUID, url: shareItem.url, title: shareItem.title)

            var userData = [QuickActions.TabURLKey: shareItem.url]
            if let title = shareItem.title {
                userData[QuickActions.TabTitleKey] = title
            }
            QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                                withUserData: userData,
                                                                                toApplication: .shared)
            site.setBookmarked(true)
            self.viewModel.topSiteViewModel.tileManager.refreshIfNeeded(forceTopSites: true)
            TelemetryWrapper.recordEvent(category: .action, method: .add, object: .bookmark, value: .activityStream)
        })
    }

    private func getShareAction(siteURL: URL, sourceView: UIView?) -> PhotonRowActions {
        return SingleActionViewModel(title: .ShareContextMenuTitle, iconString: ImageIdentifiers.share, tapHandler: { _ in
            let helper = ShareExtensionHelper(url: siteURL, tab: nil)
            let controller = helper.createActivityViewController { (_, _) in }
            if UIDevice.current.userInterfaceIdiom == .pad,
               let popoverController = controller.popoverPresentationController,
               let getSourceRect = self.getPopoverSourceRect {

                popoverController.sourceView = sourceView
                popoverController.sourceRect = getSourceRect(sourceView)
                popoverController.permittedArrowDirections = [.up, .down, .left]
                popoverController.delegate = self.delegate
            }

            self.delegate?.presentWithModalDismissIfNeeded(controller, animated: true)
        }).items
    }

    private func fetchBookmarkStatus(for site: Site, completionHandler: @escaping () -> Void) {
        viewModel.profile.places.isBookmarked(url: site.url).uponQueue(.main) { result in
            let isBookmarked = result.successValue ?? false
            site.setBookmarked(isBookmarked)
            completionHandler()
        }
    }
}
