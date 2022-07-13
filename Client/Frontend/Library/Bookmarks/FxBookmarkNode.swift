// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Storage

// Provides a layer of abstraction so we have more power over BookmarkNodeData provided by App Services.
// For instance, this enables us to have the LocalDesktopFolder.
protocol FxBookmarkNode {
    var type: BookmarkNodeType { get }
    var guid: String { get }
    var parentGUID: String? { get }
    var position: UInt32 { get }
}

extension FxBookmarkNode {
    var isNonEmptyFolder: Bool {
        guard let bookmarkFolder = self as? BookmarkFolderData else {
            return false
        }

        return !bookmarkFolder.childGUIDs.isEmpty
    }

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

extension BookmarkNodeData: FxBookmarkNode {}

// TODO: Laurie - put this in its own file. bring image code with it
protocol BookmarksCell {
    func getViewModel(forSite site: Site?,
                      profile: Profile?,
                      completion: ((OneLineTableViewCellViewModel) -> Void)?) -> OneLineTableViewCellViewModel
}

extension BookmarksCell {
    func getViewModel(forSite site: Site? = nil,
                      profile: Profile? = nil,
                      completion: ((OneLineTableViewCellViewModel) -> Void)? = nil) -> OneLineTableViewCellViewModel {
        self.getViewModel(forSite: site, profile: profile, completion: completion)
    }
}

extension BookmarkFolderData: BookmarksCell {

    func getViewModel() -> OneLineTableViewCellViewModel {
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
}

extension BookmarkItemData: BookmarksCell {
    func getViewModel(forSite site: Site?,
                      profile: Profile?,
                      completion: ((OneLineTableViewCellViewModel) -> Void)?) -> OneLineTableViewCellViewModel {

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
}
