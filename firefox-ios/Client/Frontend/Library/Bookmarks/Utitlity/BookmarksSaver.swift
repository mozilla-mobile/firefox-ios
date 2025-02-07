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

    @MainActor
    func save(bookmark: FxBookmarkNode, parentFolderGUID: String) async -> Result<GUID?, any Error> {
        switch bookmark.type {
        case .bookmark:
            return await saveBookmark(bookmark: bookmark, parentFolderGUID: parentFolderGUID)
        case .folder:
            return await saveFolder(bookmark: bookmark, parentFolderGUID: parentFolderGUID)
        default:
            return .failure(SaveError.bookmarkTypeDontSupportSaving)
        }
    }

    func restoreBookmarkNode(bookmarkNode: BookmarkNodeData,
                             parentFolderGUID: String,
                             completion: @escaping (GUID?) -> Void) {
        switch bookmarkNode.type {
        case .bookmark:
            guard let bookmark = bookmarkNode as? BookmarkItemData else {
                completion(nil)
                return
            }
            profile.places.createBookmark(parentGUID: parentFolderGUID,
                                          url: bookmark.url,
                                          title: bookmark.title,
                                          position: bookmark.position) { result in
                switch result {
                case .success(let guid):
                    completion(guid)
                case .failure:
                    completion(nil)
                }
            }

        case .folder:
            guard let folder = bookmarkNode as? BookmarkFolderData else {
                completion(nil)
                return
            }

            profile.places.createFolder(parentGUID: parentFolderGUID,
                                        title: folder.title,
                                        position: folder.position) { result in
                switch result {
                case .success(let guid):
                    completion(guid)
                case .failure:
                    completion(nil)
                }
            }

        default:
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

    private func saveBookmark(bookmark: FxBookmarkNode, parentFolderGUID: String) async -> Result<GUID?, any Error> {
        return await withCheckedContinuation { continuation in
            guard let bookmark = bookmark as? BookmarkItemData else {
                return continuation.resume(returning: .failure(SaveError.saveOperationFailed))
            }
            let position: UInt32? = parentFolderGUID == BookmarkRoots.MobileFolderGUID ? 0 : nil

            if bookmark.parentGUID == nil {
                profile.places.createBookmark(parentGUID: parentFolderGUID,
                                              url: bookmark.url,
                                              title: bookmark.title,
                                              position: position) { result in
                    switch result {
                    case .success(let guid):
                        return continuation.resume(returning: .success(guid))
                    case .failure:
                        return continuation.resume(returning: .failure(SaveError.saveOperationFailed))
                    }
                }
            } else {
                profile.places.updateBookmarkNode(guid: bookmark.guid,
                                                  parentGUID: parentFolderGUID,
                                                  position: bookmark.position,
                                                  title: bookmark.title,
                                                  url: bookmark.url) { result in
                    switch result {
                    case .success:
                        return continuation.resume(returning: .success(nil))
                    case .failure:
                        return continuation.resume(returning: .failure(SaveError.saveOperationFailed))
                    }
                }
            }
        }
    }

    private func saveFolder(bookmark: FxBookmarkNode, parentFolderGUID: String) async -> Result<GUID?, any Error> {
        return await withCheckedContinuation { continuation in
            guard let folder = bookmark as? BookmarkFolderData else {
                return continuation.resume(returning: .failure(SaveError.saveOperationFailed))
            }
            let position: UInt32? = parentFolderGUID == BookmarkRoots.MobileFolderGUID ? 0 : nil

            if folder.parentGUID == nil {
                let bookmarksTelemetry = BookmarksTelemetry()
                bookmarksTelemetry.addBookmarkFolder()

                profile.places.createFolder(parentGUID: parentFolderGUID,
                                            title: folder.title,
                                            position: position) { result in
                    switch result {
                    case .success(let guid):
                        return continuation.resume(returning: .success(guid))
                    case .failure:
                        return continuation.resume(returning: .failure(SaveError.saveOperationFailed))
                    }
                }
            } else {
                profile.places.updateBookmarkNode(guid: folder.guid,
                                                  parentGUID: parentFolderGUID,
                                                  position: folder.position,
                                                  title: folder.title) { result in
                    switch result {
                    case .success:
                        return continuation.resume(returning: .success(nil))
                    case .failure:
                        return continuation.resume(returning: .failure(SaveError.saveOperationFailed))
                    }
                }
            }
        }
    }
}
