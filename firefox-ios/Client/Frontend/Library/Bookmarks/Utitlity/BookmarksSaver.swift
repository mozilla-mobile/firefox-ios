// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Shared

protocol BookmarksSaver {
    /// Saves or updates a bookmark
    func save(bookmark: FxBookmarkNode, parentFolderGUID: String) async -> Result<Bool, Error>
}

struct DefaultBookmarksSaver: BookmarksSaver {
    let profile: Profile
    
    func save(bookmark: FxBookmarkNode, parentFolderGUID: String) async -> Result<Bool, Error> {
        return await withCheckedContinuation { continuation in
            let operation: Success? = {
                switch bookmark.type {
                case .bookmark:
                    // no parent create it
                    guard let bookmark = bookmark as? BookmarkItemData else { return nil }
                    let position: UInt32? = parentFolderGUID == BookmarkRoots.MobileFolderGUID ? 0 : nil
                    if bookmark.parentGUID == nil {
                        return profile.places.createBookmark(parentGUID: parentFolderGUID,
                                                             url: bookmark.url,
                                                             title: bookmark.title,
                                                             position: position).bind { result in
                            return result.isFailure ? deferMaybe(BookmarkDetailPanelError()) : succeed()
                        }
                    } else {
                        return profile.places.updateBookmarkNode(guid: bookmark.guid,
                                                                 parentGUID: parentFolderGUID,
                                                                 position: bookmark.position,
                                                                 title: bookmark.title,
                                                                 url: bookmark.url)
                    }
                case .folder:
                    return profile.places.updateBookmarkNode(guid: bookmark.guid,
                                                             parentGUID: parentFolderGUID,
                                                             position: bookmark.position,
                                                             title: bookmark.title)
                default:
                    return nil
                }
            }()
            operation?.uponQueue(.main, block: { _ in
                continuation.resume(returning: .success(true))
            })
        }
    }
}
