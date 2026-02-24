// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Shared

protocol BookmarksSaver {
    /// Saves or updates a bookmark or folder
    /// Returns a GUID when creating a bookmark or folder, or nil when updating them
    @MainActor
    func save(bookmark: FxBookmarkNode, parentFolderGUID: String) async -> Result<GUID?, Error>
    @MainActor
    func createBookmark(url: String, title: String?, position: UInt32?) async
    func restoreBookmarkNode(bookmarkNode: BookmarkNodeData,
                             parentFolderGUID: String,
                             completion: @escaping @Sendable(GUID?) -> Void)
}

struct DefaultBookmarksSaver: BookmarksSaver {
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
                             completion: @escaping @Sendable (GUID?) -> Void) {
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

    @MainActor
    func createBookmark(url: String, title: String?, position: UInt32?) async {
        let bookmarkData = BookmarkItemData(guid: "",
                                            dateAdded: 0,
                                            lastModified: 0,
                                            parentGUID: nil,
                                            position: position ?? 0,
                                            url: url,
                                            title: title ?? "")
        // Add new bookmark to the top of the folder
        // Save bookmark to recent bookmark folder
        let parentGuid = await resolvedParentFolderGuid()
        _ = await save(bookmark: bookmarkData, parentFolderGUID: parentGuid)
    }

    @MainActor
    private func resolvedParentFolderGuid() async -> String {
        guard let recentBookmarkFolderGuid = profile.prefs.stringForKey(PrefsKeys.RecentBookmarkFolder) else {
            return BookmarkRoots.MobileFolderGUID
        }

        let bookmarkExists = await withCheckedContinuation { continuation in
            profile.places.getBookmark(guid: recentBookmarkFolderGuid)
                .uponQueue(.main) { result in
                    continuation.resume(returning: (result.successValue ?? nil) != nil)
                }
        }

        if !bookmarkExists {
            profile.prefs.removeObjectForKey(PrefsKeys.RecentBookmarkFolder)
        }

        return bookmarkExists ? recentBookmarkFolderGuid : BookmarkRoots.MobileFolderGUID
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
