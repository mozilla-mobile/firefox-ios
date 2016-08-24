/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public func titleForSpecialGUID(guid: GUID) -> String? {
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

extension SQLiteBookmarks: ShareToDestination {
    public func addToMobileBookmarks(url: NSURL, title: String, favicon: Favicon?) {
        let deferredResult = isBookmarked(url.absoluteString)
        
        deferredResult.upon { result in
            if result.isSuccess && !result.successValue! {
                self.insertBookmark(url, title: title, favicon: favicon,
                                    intoFolder: BookmarkRoots.MobileFolderGUID,
                                    withTitle: BookmarksFolderTitleMobile)
            }
        }
    }

    public func shareItem(item: ShareItem) {
        // We parse here in anticipation of getting real URLs at some point.
        if let url = item.url.asURL {
            let title = item.title ?? url.absoluteString
            self.addToMobileBookmarks(url, title: title, favicon: item.favicon)
        }
    }
}
