/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public func titleForSpecialGUID(_ guid: GUID) -> String? {
    switch guid {
    case BookmarkRoots.RootGUID:
        return "<Root>"
    case BookmarkRoots.MobileFolderGUID:
        return BookmarksFolderTitleMobile
    case BookmarkRoots.ToolbarFolderGUID:
        return BookmarksFolderTitleToolbar
    case BookmarkRoots.MenuFolderGUID:
        return BookmarksFolderTitleMenu
    case BookmarkRoots.UnfiledFolderGUID:
        return BookmarksFolderTitleUnsorted
    default:
        return nil
    }
}

class BookmarkURLTooLargeError: MaybeErrorType {
    init() {
    }
    var description: String {
        return "URL too long to bookmark."
    }
}

extension String {
    public func truncateToUTF8ByteCount(_ keep: Int) -> String {
        let byteCount = self.lengthOfBytes(using: String.Encoding.utf8)
        if byteCount <= keep {
            return self
        }
        let toDrop = keep - byteCount

        // If we drop this many characters from the string, we will drop at least this many bytes.
        // That's aggressive, but that's OK for our purposes.
        guard let endpoint = self.index(self.endIndex, offsetBy: toDrop, limitedBy: self.startIndex) else {
            return ""
        }
        return self.substring(to: endpoint)
    }
}

extension SQLiteBookmarks: ShareToDestination {
    public func addToMobileBookmarks(_ url: URL, title: String, favicon: Favicon?) -> Success {
        if url.absoluteString.lengthOfBytes(using: String.Encoding.utf8) > AppConstants.DB_URL_LENGTH_MAX {
            return deferMaybe(BookmarkURLTooLargeError())
        }

        let title = title.truncateToUTF8ByteCount(AppConstants.DB_TITLE_LENGTH_MAX)

        return isBookmarked(String(describing: url), direction: Direction.local)
            >>== { yes in
                guard !yes else { return succeed() }
                return self.insertBookmark(url, title: title, favicon: favicon,
                                           intoFolder: BookmarkRoots.MobileFolderGUID,
                                           withTitle: BookmarksFolderTitleMobile)
        }
    }

    public func shareItem(_ item: ShareItem) -> Success {
        // We parse here in anticipation of getting real URLs at some point.
        if let url = item.url.asURL {
            let title = item.title ?? url.absoluteString
            return self.addToMobileBookmarks(url, title: title, favicon: item.favicon)
        }
        return succeed()
    }
}
