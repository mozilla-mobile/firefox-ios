// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Shared

protocol BookmarksSaver {
    /// Saves or updates a bookmark
    func save(bookmark: FxBookmarkNode, parentFolderGUID: String) async -> Result<Void, Error>
}

struct DefaultBookmarksSaver: BookmarksSaver {
    enum SaveError: Error {
        case bookmarkTypeDontSupportSaving
    }

    let profile: Profile

    func save(bookmark: FxBookmarkNode, parentFolderGUID: String) async -> Result<Void, Error> {
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
                    guard let folder = bookmark as? BookmarkFolderData else { return nil }
                    if folder.parentGUID == nil {
                        let position: UInt32? = parentFolderGUID == BookmarkRoots.MobileFolderGUID ? 0 : nil
                        return profile.places.createFolder(parentGUID: parentFolderGUID,
                                                           title: folder.title,
                                                           position: position).bind { result in
                            return result.isFailure ? deferMaybe(BookmarkDetailPanelError()) : succeed()
                        }
                    } else {
                        return profile.places.updateBookmarkNode(guid: bookmark.guid,
                                                                 parentGUID: parentFolderGUID,
                                                                 position: bookmark.position,
                                                                 title: bookmark.title)
                    }
                default:
                    return nil
                }
            }()
            if let operation {
                operation.uponQueue(.main, block: { result in
                    if let result = result.successValue {
                        continuation.resume(returning: .success(result))
                    } else {
                        continuation.resume(returning: .failure(SaveError.bookmarkTypeDontSupportSaving))
                    }
                })
            } else {
                continuation.resume(returning: .failure(SaveError.bookmarkTypeDontSupportSaving))
            }
        }
    }
}
