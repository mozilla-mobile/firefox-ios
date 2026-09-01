// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppIntents
import Common
import CoreSpotlight
import Foundation
import Shared
import UniformTypeIdentifiers

import class MozillaAppServices.BookmarkItemData

/// The kind of browser item a `BrowserEntity` was built from.
enum BrowserEntityType: String, Sendable {
    case tab
    case bookmark

    /// The user facing name of the type, indexed as the Spotlight `kind` so that it reads well in search results.
    var kind: String {
        switch self {
        case .tab: return "Open Tab"
        case .bookmark: return "Bookmark"
        }
    }

    /// The words that must match for a search to select every item of this type.
    ///
    /// Spotlight matches query terms as prefixes, so the singular form alone doesn't match a query for "tabs": both
    /// forms have to be indexed. The app name is included so that a question mentioning Firefox still selects them.
    var searchKeywords: [String] {
        switch self {
        case .tab: return ["tab", "tabs", "open tab", "open tabs", "firefox", "browser"]
        case .bookmark: return ["bookmark", "bookmarks", "saved page", "saved pages", "firefox", "browser"]
        }
    }
}

/// Identifies a `BrowserEntity` uniquely across both entity types.
///
/// The page url is part of the identity, which means a Spotlight result can be routed to a page without having to
/// read back from the tab manager or from places, and that a page open in several tabs is indexed once.
struct BrowserEntityID: Hashable, Sendable {
    private static let separator: Character = ":"

    let type: BrowserEntityType
    let url: URL

    var rawValue: String {
        return "\(type.rawValue)\(Self.separator)\(url.absoluteString)"
    }

    init(type: BrowserEntityType, url: URL) {
        self.type = type
        self.url = url
    }

    init?(rawValue: String) {
        guard let separatorIndex = rawValue.firstIndex(of: Self.separator),
              let type = BrowserEntityType(rawValue: String(rawValue[rawValue.startIndex..<separatorIndex])),
              let url = URL(string: String(rawValue[rawValue.index(after: separatorIndex)...]))
        else { return nil }

        self.type = type
        self.url = url
    }
}

/// A single browser item that can be surfaced by Spotlight and by App Intents, either an open tab or a bookmark.
struct BrowserEntity: Identifiable, Hashable, Sendable {
    let id: BrowserEntityID
    let title: String
    let lastUsedDate: Date?

    var type: BrowserEntityType { return id.type }
    var url: URL { return id.url }
}

@available(iOS 18.0, *)
extension BrowserEntityID: EntityIdentifierConvertible {
    var entityIdentifierString: String { return rawValue }

    static func entityIdentifier(for entityIdentifierString: String) -> BrowserEntityID? {
        return BrowserEntityID(rawValue: entityIdentifierString)
    }
}

@available(iOS 18.0, *)
extension BrowserEntity: IndexedEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        return TypeDisplayRepresentation(name: "Browser Item")
    }

    static var defaultQuery: BrowserEntityQuery { return BrowserEntityQuery() }

    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "\(title)",
                                     subtitle: "\(type.kind) - \(url.absoluteDisplayString)",
                                     image: .init(systemName: "globe"))
    }

    /// The type is repeated in `kind`, in `keywords` and in `contentDescription` because the on-device model can only
    /// select items through a text match: a question about the open tabs finds nothing unless "tab" and "tabs" are
    /// part of the indexed text of every tab.
    var attributeSet: CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .url)
        attributeSet.title = title
        attributeSet.kind = type.kind
        attributeSet.contentDescription = "\(type.kind) in Firefox: \(url.absoluteDisplayString)"
        attributeSet.contentURL = url
        attributeSet.lastUsedDate = lastUsedDate
        attributeSet.keywords = type.searchKeywords
        return attributeSet
    }
}

extension BrowserEntity {
    /// Returns `nil` for tabs that must not be indexed, such as private tabs and internal pages.
    @MainActor
    init?(tab: Tab) {
        guard !tab.isPrivate,
              let url = tab.url,
              url.isWebPage(includeDataURIs: false),
              !InternalURL.isValid(url: url)
        else { return nil }

        self.init(id: BrowserEntityID(type: .tab, url: url),
                  title: tab.displayTitle,
                  lastUsedDate: Date.fromTimestamp(tab.lastExecutedTime))
    }

    /// Returns `nil` for bookmarks that don't point to an indexable web page.
    init?(bookmark: BookmarkItemData) {
        guard let url = URL(string: bookmark.url),
              url.isWebPage(includeDataURIs: false),
              !InternalURL.isValid(url: url)
        else { return nil }

        let lastModified = bookmark.lastModified > 0 ? Date.fromTimestamp(Timestamp(bookmark.lastModified)) : nil
        self.init(id: BrowserEntityID(type: .bookmark, url: url),
                  title: bookmark.title.isEmpty ? url.absoluteDisplayString : bookmark.title,
                  lastUsedDate: lastModified)
    }
}
