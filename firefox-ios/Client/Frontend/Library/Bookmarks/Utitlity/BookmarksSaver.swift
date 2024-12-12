// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Shared

protocol BookmarksSaver {
    /// Saves or updates a bookmark or folder
    /// Returns a GUID when creating a bookmark or folder, or nil when updating them
    func save(bookmark: FxBookmarkNode, parentFolderGUID: String) async -> Result<GUID?, Error>
}

struct DefaultBookmarksSaver: BookmarksSaver {
    enum SaveError: Error {
        case bookmarkTypeDontSupportSaving
        case saveOperationFailed
    }

    let profile: Profile

    func save(bookmark: FxBookmarkNode, parentFolderGUID: String) async -> Result<GUID?, Error> {
        return await withCheckedContinuation { continuation in
            let operation: Deferred<Maybe<GUID?>>? = {
                switch bookmark.type {
                case .bookmark:
                    guard let bookmark = bookmark as? BookmarkItemData else { return deferMaybe(nil) }
                    let position: UInt32? = parentFolderGUID == BookmarkRoots.MobileFolderGUID ? 0 : nil

                    if bookmark.parentGUID == nil {
                        return profile.places.createBookmark(parentGUID: parentFolderGUID,
                                                             url: bookmark.url,
                                                             title: bookmark.title,
                                                             position: position).bind { result in
                            return result.isFailure ? deferMaybe(BookmarkDetailPanelError())
                                                    : deferMaybe(result.successValue)
                        }
                    } else {
                        return profile.places.updateBookmarkNode(guid: bookmark.guid,
                                                                 parentGUID: parentFolderGUID,
                                                                 position: bookmark.position,
                                                                 title: bookmark.title,
                                                                 url: bookmark.url).bind { result in
                            return result.isFailure ? deferMaybe(BookmarkDetailPanelError()) : deferMaybe(nil)
                        }
                    }

                case .folder:
                    guard let folder = bookmark as? BookmarkFolderData else { return deferMaybe(nil) }
                    let position: UInt32? = parentFolderGUID == BookmarkRoots.MobileFolderGUID ? 0 : nil

                    if folder.parentGUID == nil {
                        return profile.places.createFolder(parentGUID: parentFolderGUID,
                                                           title: folder.title,
                                                           position: position).bind { result in
                            return result.isFailure ? deferMaybe(BookmarkDetailPanelError())
                                                    : deferMaybe(result.successValue)
                        }
                    } else {
                        return profile.places.updateBookmarkNode( guid: folder.guid,
                                                                  parentGUID: parentFolderGUID,
                                                                  position: folder.position,
                                                                  title: folder.title).bind { result in
                            return result.isFailure ? deferMaybe(BookmarkDetailPanelError()) : deferMaybe(nil)
                        }
                    }

                default:
                    return nil
                }
            }()

            if let operation {
                operation.uponQueue(.main, block: { result in
                    if let successValue = result.successValue {
                        continuation.resume(returning: .success(successValue))
                    } else {
                        continuation.resume(returning: .failure(SaveError.saveOperationFailed))
                    }
                })
            } else {
                continuation.resume(returning: .failure(SaveError.bookmarkTypeDontSupportSaving))
            }
        }
    }
}
