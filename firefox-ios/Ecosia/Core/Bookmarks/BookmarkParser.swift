// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftSoup

private typealias DateTag = String

public enum BookmarkParserError: Error {
    case noLeadingDL, noBody, cancelled
}

public protocol BookmarkParseable {
    func parseBookmarks() async throws -> [BookmarkItem]
}

public class BookmarkParser: BookmarkParseable {
    private let document: Document
    private let dispatchQueue: DispatchQueue

    public init(html: String, dispatchQueue: DispatchQueue = .init(label: "org.ecosia.ios-core.bookmarks")) throws {
        let document = try SwiftSoup.parse(html)
        self.document = try document.normalizedDocumentIfRequired()
        self.dispatchQueue = dispatchQueue
    }

    public func parseBookmarks() async throws -> [BookmarkItem] {
        try await withCheckedThrowingContinuation { continuation in
            dispatchQueue.async { [weak self] in
                guard let self = self else {
                    return continuation.resume(throwing: BookmarkParserError.cancelled)
                }
                do {
                    let result = try self.parse(element: try self.document.getLeadingDL())
                    continuation.resume(with: .success(result))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

private extension BookmarkParser {
    func parse(element: Element) throws -> [BookmarkItem] {
        var items = [BookmarkItem]()

        let children = try element.getLeadingDL()
            .children()
            .filter({ try $0.select(.dt).hasText() }) /// only <DT> is a valid bookmark/folder element

        for child in children {
            let h3 = try child.select(.h3)
            if let nextFolderItem = h3.first() {
                guard let title = try? nextFolderItem.text() else { continue }
                items.append(.folder(title, try parse(element: child), h3.extractBookmarkMetadata()))
                continue /// item is a folder, don't process as bookmark
            }

            let link = try child.select(.a)
            let href = try link.attr(.href)
            let title = try link.text()

            items.append(.bookmark(title, href, link.extractBookmarkMetadata()))
        }

        return items
    }
}

private extension Elements {
    func extractDate(_ tag: DateTag) -> Date? {
        guard
            let timeIntervalString = try? attr(tag),
            let timeInterval = TimeInterval(timeIntervalString)
        else {
            return nil
        }
        return Date(timeIntervalSince1970: timeInterval)
    }

    func extractBookmarkMetadata() -> BookmarkMetadata {
        BookmarkMetadata(
            addedAt: extractDate(.addDate),
            modifiedAt: extractDate(.lastModified)
        )
    }
}

private extension Element {
    func getLeadingDL() throws -> Element {
        guard let leadingDL = try select(.dl).first() else {
            throw BookmarkParserError.noLeadingDL
        }
        return leadingDL
    }
}
