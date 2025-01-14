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
    func createBookmark(url: String, title: String?, position: UInt32?) async
    func restoreBookmarkNode(bookmarkNode: BookmarkNodeData,
                             parentFolderGUID: String,
                             completion: @escaping (GUID?) -> Void)
}

struct DefaultBookmarksSaver: BookmarksSaver, BookmarksRefactorFeatureFlagProvider {
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

                    if bookmark.parentGUID == nil {
                        let position: UInt32? = parentFolderGUID == BookmarkRoots.MobileFolderGUID ? 0 : nil
                        return profile.places.createBookmark(parentGUID: parentFolderGUID,
                                                             url: bookmark.url,
                                                             title: bookmark.title,
                                                             position: position).bind { result in
                            return result.isFailure ? deferMaybe(BookmarkDetailPanelError())
                                                    : deferMaybe(result.successValue)
                        }
                    } else {
                        let position: UInt32? = parentFolderGUID == bookmark.parentGUID ? bookmark.position : nil
                        return profile.places.updateBookmarkNode(guid: bookmark.guid,
                                                                 parentGUID: parentFolderGUID,
                                                                 position: position,
                                                                 title: bookmark.title,
                                                                 url: bookmark.url).bind { result in
                            return result.isFailure ? deferMaybe(BookmarkDetailPanelError()) : deferMaybe(nil)
                        }
                    }

                case .folder:
                    guard let folder = bookmark as? BookmarkFolderData else { return deferMaybe(nil) }

                    if folder.parentGUID == nil {
                        let position: UInt32? = parentFolderGUID == BookmarkRoots.MobileFolderGUID ? 0 : nil
                        return profile.places.createFolder(parentGUID: parentFolderGUID,
                                                           title: folder.title,
                                                           position: position).bind { result in
                            return result.isFailure ? deferMaybe(BookmarkDetailPanelError())
                                                    : deferMaybe(result.successValue)
                        }
                    } else {
                        let position: UInt32? = parentFolderGUID == folder.parentGUID ? folder.position : nil
                        return profile.places.updateBookmarkNode( guid: folder.guid,
                                                                  parentGUID: parentFolderGUID,
                                                                  position: position,
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

    func restoreBookmarkNode(bookmarkNode: BookmarkNodeData,
                             parentFolderGUID: String,
                             completion: @escaping (GUID?) -> Void) {
        let operation: Deferred<Maybe<GUID?>>? = {
            switch bookmarkNode.type {
            case .bookmark:
                guard let bookmark = bookmarkNode as? BookmarkItemData else { return nil }
                return profile.places.createBookmark(parentGUID: parentFolderGUID,
                                                     url: bookmark.url,
                                                     title: bookmark.title,
                                                     position: bookmark.position).bind { result in
                    return result.isFailure ? deferMaybe(BookmarkDetailPanelError())
                                            : deferMaybe(result.successValue)
                }

            case .folder:
                guard let folder = bookmarkNode as? BookmarkFolderData else { return nil }

                return profile.places.createFolder(parentGUID: parentFolderGUID,
                                                   title: folder.title,
                                                   position: folder.position).bind { result in
                        return result.isFailure ? deferMaybe(BookmarkDetailPanelError())
                                                : deferMaybe(result.successValue)
                }

            default:
                return nil
            }
        }()

        if let operation {
            operation.uponQueue(.main, block: { result in
                if let successValue = result.successValue {
                    completion(successValue)
                } else {
                    completion(nil)
                }
            })
        } else {
            completion(nil)
        }
    }

    func createBookmark(url: String, title: String?, position: UInt32?) async {
        let bookmarkData = BookmarkItemData(guid: "",
                                            dateAdded: 0,
                                            lastModified: 0,
                                            parentGUID: nil,
                                            position: position ?? 0,
                                            url: url,
                                            title: title ?? "")
        // Add new bookmark to the top of the folder
        // If bookmarks refactor is enabled, save bookmark to recent bookmark folder, otherwise save to root folder
        let recentBookmarkFolderGuid = profile.prefs.stringForKey(PrefsKeys.RecentBookmarkFolder)
        let parentGuid = (isBookmarkRefactorEnabled ? recentBookmarkFolderGuid : nil) ?? BookmarkRoots.MobileFolderGUID
        _ = await save(bookmark: bookmarkData, parentFolderGUID: parentGuid)
    }
}
