// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

/// Used to setup bookmarks and folder cell in Bookmarks panel, getting their viewModel
protocol BookmarksFolderCell {
    func getViewModel(forSite site: Site?,
                      profile: Profile?,
                      completion: ((OneLineTableViewCellViewModel) -> Void)?) -> OneLineTableViewCellViewModel

    func didSelect(profile: Profile,
                   libraryPanelDelegate: LibraryPanelDelegate?,
                   navigationController: UINavigationController?)
}

extension BookmarkFolderData: BookmarksFolderCell {

    func getViewModel(forSite site: Site?,
                      profile: Profile?,
                      completion: ((OneLineTableViewCellViewModel) -> Void)?)
    -> OneLineTableViewCellViewModel {
        var title: String
        if isRoot, let localizedString = LocalizedRootBookmarkFolderStrings[guid] {
            title = localizedString
        } else {
            title = self.title
        }

        return OneLineTableViewCellViewModel(title: title,
                                             leftImageView: leftImageView,
                                             leftImageViewContentView: .center,
                                             accessoryView: UIImageView(image: chevronImage),
                                             accessoryType: .disclosureIndicator)
    }

    func didSelect(profile: Profile,
                   libraryPanelDelegate: LibraryPanelDelegate?,
                   navigationController: UINavigationController?) {
        let viewModel = BookmarksPanelViewModel(profile: profile,
                                                bookmarkFolderGUID: guid)
        let nextController = BookmarksPanel(viewModel: viewModel)
        if isRoot, let localizedString = LocalizedRootBookmarkFolderStrings[guid] {
            nextController.title = localizedString
        } else {
            nextController.title = title
        }
        nextController.libraryPanelDelegate = libraryPanelDelegate
        navigationController?.pushViewController(nextController, animated: true)
    }
}

extension BookmarkItemData: BookmarksFolderCell {
    func getViewModel(forSite site: Site?,
                      profile: Profile?,
                      completion: ((OneLineTableViewCellViewModel) -> Void)?)
    -> OneLineTableViewCellViewModel {

        var title: String
        if self.title.isEmpty {
            title = url
        } else {
            title = self.title
        }

        var viewModel = OneLineTableViewCellViewModel(title: title,
                                                      leftImageView: nil,
                                                      leftImageViewContentView: .center,
                                                      accessoryView: nil,
                                                      accessoryType: .disclosureIndicator)

        if let site = site {
            profile?.favicons.getFaviconImage(forSite: site).uponQueue(.main) { result in
                // Check that we successfully retrieved an image (should always happen)
                // and ensure that the cell we were fetching for is still on-screen.
                guard let image = result.successValue else { return }

                viewModel.leftImageView = image
                viewModel.leftImageViewContentView = .scaleAspectFill

                completion?(viewModel)
            }
        }

        return viewModel
    }

    func didSelect(profile: Profile,
                   libraryPanelDelegate: LibraryPanelDelegate?,
                   navigationController: UINavigationController?) {
        libraryPanelDelegate?.libraryPanel(didSelectURLString: url, visitType: .bookmark)
        TelemetryWrapper.recordEvent(category: .action, method: .open, object: .bookmark, value: .bookmarksPanel)
    }
}

// MARK: FxBookmarkNode viewModel helper
extension FxBookmarkNode {

    var leftImageView: UIImage? {
        return LegacyThemeManager.instance.currentName == .dark ? bookmarkFolderIconDark : bookmarkFolderIconNormal
    }

    var chevronImage: UIImage? {
        return UIImage(named: ImageIdentifiers.menuChevron)
    }

    private var bookmarkFolderIconNormal: UIImage? {
        return UIImage(named: ImageIdentifiers.bookmarkFolder)?
            .createScaled(BookmarksPanel.UX.FolderIconSize)
            .tinted(withColor: UIColor.Photon.Grey90)
    }

    private var bookmarkFolderIconDark: UIImage? {
        return UIImage(named: ImageIdentifiers.bookmarkFolder)?
            .createScaled(BookmarksPanel.UX.FolderIconSize)
            .tinted(withColor: UIColor.Photon.Grey10)
    }
}
