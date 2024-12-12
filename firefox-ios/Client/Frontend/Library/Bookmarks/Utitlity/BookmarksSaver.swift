// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Shared

protocol BookmarksSaver {
    /// Saves or updates a bookmark
    func save(bookmark: FxBookmarkNode, parentFolderGUID: String) async -> Result<String?, Error>
}

struct DefaultBookmarksSaver: BookmarksSaver {
    enum SaveError: Error {
        case bookmarkTypeDontSupportSaving
        case saveOperationFailed
    }

    let profile: Profile

    func save(bookmark: FxBookmarkNode, parentFolderGUID: String) async -> Result<String?, Error> {
        return await withCheckedContinuation { continuation in
            let operation: Success? = {
                switch bookmark.type {
                case .bookmark:
                    guard let bookmark = bookmark as? BookmarkItemData else { return nil }
                    let position: UInt32? = parentFolderGUID == BookmarkRoots.MobileFolderGUID ? 0 : nil

                    return bookmark.parentGUID == nil ?
                        profile.places.createBookmark(
                            parentGUID: parentFolderGUID,
                            url: bookmark.url,
                            title: bookmark.title,
                            position: position
                        ).bind { result in
                            continuation.resume(returning: result.isSuccess ? .success(result.successValue)
                                                                            : .failure(SaveError.saveOperationFailed))
                            return succeed()
                        } :
                        profile.places.updateBookmarkNode(
                            guid: bookmark.guid,
                            parentGUID: parentFolderGUID,
                            position: bookmark.position,
                            title: bookmark.title,
                            url: bookmark.url
                        ).bind { result in
                            continuation.resume(returning: result.isSuccess ? .success(nil)
                                                                            : .failure(SaveError.saveOperationFailed))
                            return succeed()
                        }

                case .folder:
                    guard let folder = bookmark as? BookmarkFolderData else { return nil }
                    let position: UInt32? = parentFolderGUID == BookmarkRoots.MobileFolderGUID ? 0 : nil

                    return folder.parentGUID == nil ?
                        profile.places.createFolder(
                            parentGUID: parentFolderGUID,
                            title: folder.title,
                            position: position
                        ).bind { result in
                            continuation.resume(returning: result.isSuccess ? .success(result.successValue)
                                                                            : .failure(SaveError.saveOperationFailed))
                            return succeed()
                        } :
                        profile.places.updateBookmarkNode(
                            guid: folder.guid,
                            parentGUID: parentFolderGUID,
                            position: folder.position,
                            title: folder.title
                        ).bind { result in
                            continuation.resume(returning: result.isSuccess ? .success(nil)
                                                                            : .failure(SaveError.saveOperationFailed))
                            return succeed()
                        }

                default:
                    return nil
                }
            }()

            if let operation {
                operation.uponQueue(.main, block: { result in
                    if result.isFailure {
                        continuation.resume(returning: .failure(SaveError.saveOperationFailed))
                    }
                })
            } else {
                continuation.resume(returning: .failure(SaveError.bookmarkTypeDontSupportSaving))
            }
        }
    }
}
