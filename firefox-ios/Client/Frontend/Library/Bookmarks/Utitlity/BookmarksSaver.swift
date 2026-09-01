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

    /// Deletes a bookmark or a folder, removing the bookmarks it contains from the Spotlight index
    @MainActor
    func delete(bookmark: FxBookmarkNode) async -> Result<Void, Error>

    /// Deletes every bookmark saved for the given url, removing them from the Spotlight index
    @MainActor
    func deleteBookmarks(withURL url: String) async -> Result<Void, Error>
}

struct DefaultBookmarksSaver: BookmarksSaver {
    enum SaveError: Error {
        case bookmarkTypeDontSupportSaving
        case saveOperationFailed
        case deleteOperationFailed
    }

    let profile: Profile
    var spotlightIndexer: BrowserEntityIndexer = DefaultBrowserEntityIndexer()

    @MainActor
    func save(bookmark: FxBookmarkNode, parentFolderGUID: String) async -> Result<GUID?, any Error> {
        switch bookmark.type {
        case .bookmark:
            let previousURL = await savedURL(ofBookmarkWith: bookmark.guid)
            let result = await saveBookmark(bookmark: bookmark, parentFolderGUID: parentFolderGUID)
            if case .success = result {
                await indexInSpotlight(bookmark, replacing: previousURL)
            }
            return result
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
            let spotlightIndexer = spotlightIndexer
            let entity = BrowserEntity(bookmark: bookmark)
            profile.places.createBookmark(parentGUID: parentFolderGUID,
                                          url: bookmark.url,
                                          title: bookmark.title,
                                          position: bookmark.position) { result in
                switch result {
                case .success(let guid):
                    if let entity {
                        Task { await spotlightIndexer.index([entity]) }
                    }
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
    func delete(bookmark: FxBookmarkNode) async -> Result<Void, Error> {
        let indexedURLs = await savedURLs(of: bookmark)
        let result: Result<Void, Error> = await withCheckedContinuation { continuation in
            profile.places.deleteBookmarkNode(guid: bookmark.guid).uponQueue(.main) { result in
                continuation.resume(returning: Self.voidResult(from: result))
            }
        }

        if case .success = result {
            await removeFromSpotlightIndex(indexedURLs)
        }
        return result
    }

    @MainActor
    func deleteBookmarks(withURL url: String) async -> Result<Void, Error> {
        let result: Result<Void, Error> = await withCheckedContinuation { continuation in
            profile.places.deleteBookmarksWithURL(url: url).uponQueue(.main) { result in
                continuation.resume(returning: Self.voidResult(from: result))
            }
        }

        if case .success = result {
            await removeFromSpotlightIndex([url])
        }
        return result
    }

    private static func voidResult(from maybe: Maybe<Void>) -> Result<Void, Error> {
        guard maybe.isSuccess else { return .failure(maybe.failureValue ?? SaveError.deleteOperationFailed) }

        return .success(())
    }

    // MARK: - Spotlight index

    @MainActor
    private func indexInSpotlight(_ bookmark: FxBookmarkNode, replacing previousURL: String?) async {
        guard let bookmark = bookmark as? BookmarkItemData else { return }

        if let previousURL, previousURL != bookmark.url {
            await removeFromSpotlightIndex([previousURL])
        }
        guard let entity = BrowserEntity(bookmark: bookmark) else { return }

        await spotlightIndexer.index([entity])
    }

    private func removeFromSpotlightIndex(_ urls: [String]) async {
        let identifiers = urls.compactMap { URL(string: $0) }.map { BrowserEntityID(type: .bookmark, url: $0) }
        await spotlightIndexer.remove(identifiers)
    }

    /// The url a bookmark is currently saved with, used to drop its Spotlight entry when the url is updated.
    @MainActor
    private func savedURL(ofBookmarkWith guid: GUID) async -> String? {
        guard !guid.isEmpty else { return nil }

        return await withCheckedContinuation { continuation in
            profile.places.getBookmark(guid: guid).uponQueue(.main) { result in
                let bookmark = (result.successValue ?? nil) as? BookmarkItemData
                continuation.resume(returning: bookmark?.url)
            }
        }
    }

    /// The urls indexed for a node: its own url for a bookmark, the urls of its whole subtree for a folder.
    @MainActor
    private func savedURLs(of bookmark: FxBookmarkNode) async -> [String] {
        switch bookmark.type {
        case .bookmark:
            return (bookmark as? BookmarkItemData).map { [$0.url] } ?? []
        case .folder:
            let tree: BookmarkNodeData? = await withCheckedContinuation { continuation in
                profile.places.getBookmarksTree(rootGUID: bookmark.guid, recursive: true).uponQueue(.main) { result in
                    continuation.resume(returning: result.successValue ?? nil)
                }
            }
            return Self.savedURLs(in: tree)
        default:
            return []
        }
    }

    private static func savedURLs(in node: BookmarkNodeData?) -> [String] {
        if let bookmark = node as? BookmarkItemData { return [bookmark.url] }
        guard let folder = node as? BookmarkFolderData else { return [] }

        return (folder.children ?? []).flatMap { savedURLs(in: $0) }
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
