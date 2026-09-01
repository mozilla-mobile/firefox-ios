// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppIntents
import Common
import Foundation
import Shared
import Storage

import class MozillaAppServices.BookmarkItemData

/// Resolves `BrowserEntity` values back from the open tabs and from the bookmarks store, for App Intents and for the
/// entities associated to the items in the Spotlight index.
///
/// `EnumerableEntityQuery` is what allows the entity to be used as a spoken parameter of an `AppShortcut`: the open
/// tabs and the recent bookmarks are the vocabulary Siri matches a phrase against.
@available(iOS 18.0, *)
struct BrowserEntityQuery: EntityQuery, EntityStringQuery, EnumerableEntityQuery {
    private static let bookmarkFetchLimit: UInt = 10

    func entities(for identifiers: [BrowserEntityID]) async throws -> [BrowserEntity] {
        let tabURLs = Set(identifiers.filter { $0.type == .tab }.map { $0.url })
        var found = await openTabEntities().filter { tabURLs.contains($0.url) }

        for identifier in identifiers where identifier.type == .bookmark {
            found += await bookmarkEntities(matching: identifier.url)
        }

        return found
    }

    func entities(matching string: String) async throws -> [BrowserEntity] {
        let openTabs = await openTabEntities().filter {
            $0.title.localizedCaseInsensitiveContains(string)
            || $0.url.absoluteString.localizedCaseInsensitiveContains(string)
        }
        let bookmarks = await searchedBookmarkEntities(query: string)

        return openTabs + bookmarks
    }

    func suggestedEntities() async throws -> [BrowserEntity] {
        return await openTabsAndRecentBookmarks()
    }

    func allEntities() async throws -> [BrowserEntity] {
        return await openTabsAndRecentBookmarks()
    }

    private func openTabsAndRecentBookmarks() async -> [BrowserEntity] {
        let openTabs = await openTabEntities()
        let bookmarks = await recentBookmarkEntities()

        return openTabs + bookmarks
    }

    @MainActor
    private func openTabEntities() -> [BrowserEntity] {
        let windowManager: WindowManager = AppContainer.shared.resolve()
        return windowManager.allWindowTabManagers()
            .flatMap { $0.normalTabs }
            .compactMap { BrowserEntity(tab: $0) }
    }

    @MainActor
    private func bookmarkEntities(matching url: URL) async -> [BrowserEntity] {
        return await bookmarkEntities(from: places.getBookmarksWithURL(url: url.absoluteString))
    }

    @MainActor
    private func searchedBookmarkEntities(query: String) async -> [BrowserEntity] {
        return await bookmarkEntities(from: places.searchBookmarks(query: query, limit: Self.bookmarkFetchLimit))
    }

    @MainActor
    private func recentBookmarkEntities() async -> [BrowserEntity] {
        return await bookmarkEntities(from: places.getRecentBookmarks(limit: Self.bookmarkFetchLimit))
    }

    @MainActor
    private var places: RustPlaces {
        let profile: Profile = AppContainer.shared.resolve()
        return profile.places
    }

    @MainActor
    private func bookmarkEntities(from deferred: Deferred<Maybe<[BookmarkItemData]>>) async -> [BrowserEntity] {
        return await withCheckedContinuation { continuation in
            deferred.uponQueue(.main) { result in
                let bookmarks = result.successValue ?? []
                continuation.resume(returning: bookmarks.compactMap { BrowserEntity(bookmark: $0) })
            }
        }
    }
}
