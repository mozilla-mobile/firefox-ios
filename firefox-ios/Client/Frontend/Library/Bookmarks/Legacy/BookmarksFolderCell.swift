// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

import class MozillaAppServices.BookmarkFolderData
import class MozillaAppServices.BookmarkItemData

/// Used to setup bookmarks and folder cell in Bookmarks panel, getting their viewModel
protocol BookmarksFolderCell {
    @MainActor
    func getViewModel() -> OneLineTableViewCellViewModel
}

extension BookmarkFolderData: BookmarksFolderCell {
    func getViewModel() -> OneLineTableViewCellViewModel {
        var title: String
        if isRoot, let localizedString = LocalizedRootBookmarkFolderStrings[guid] {
            title = localizedString
        } else {
            title = self.title
        }
        return OneLineTableViewCellViewModel(title: title,
                                             leftImageView: leftImageView,
                                             accessoryView: UIImageView(image: chevronImage),
                                             accessoryType: .none,
                                             editingAccessoryView: UIImageView(image: chevronImage))
    }
}

extension BookmarkItemData: BookmarksFolderCell {
    func getViewModel() -> OneLineTableViewCellViewModel {
        var title: String
        if self.title.isEmpty {
            title = url
        } else {
            title = self.title
        }
        return OneLineTableViewCellViewModel(title: title,
                                             leftImageView: nil,
                                             accessoryView: UIImageView(image: chevronImage),
                                             accessoryType: .none,
                                             editingAccessoryView: UIImageView(image: chevronImage))
    }
}

// MARK: FxBookmarkNode viewModel helper
extension FxBookmarkNode {
    var leftImageView: UIImage? {
        return UIImage(named: StandardImageIdentifiers.Large.folder)?.withRenderingMode(.alwaysTemplate)
    }

    var chevronImage: UIImage? {
        return UIImage(named: StandardImageIdentifiers.Large.chevronRight)?
            .withRenderingMode(.alwaysTemplate)
            .imageFlippedForRightToLeftLayoutDirection()
    }
}
