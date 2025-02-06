// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftSoup

public enum BookmarkSerializerError: Error {
    case cancelled
}

public protocol BookmarkSerializable {
    func serializeBookmarks(_ bookmarks: [BookmarkItem]) async throws -> String
}

public class BookmarkSerializer: BookmarkSerializable {
    private let dispatchQueue: DispatchQueue

    public init(dispatchQueue: DispatchQueue = .init(label: "org.ecosia.ios-core.bookmarks")) {
        self.dispatchQueue = dispatchQueue
    }

    public func serializeBookmarks(_ bookmarks: [BookmarkItem]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            dispatchQueue.async { [weak self] in
                guard let self = self else {
                    return continuation.resume(throwing: BookmarkSerializerError.cancelled)
                }
                /// The trailing open <p> tag is part of the Netscape Bookmark file syntax
                var html =  """
                <!DOCTYPE NETSCAPE-Bookmark-file-1>
                    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
                    <Title>Bookmarks</Title>
                    <H1>Bookmarks</H1>
                    <DL><p>

                """

                for bookmark in bookmarks {
                    html += self.bookmarkBody(for: bookmark, indentation: 2)
                }

                html += """

                \(String.indent(by: 1))</DL><p>
                </HTML>
                """

                continuation.resume(returning: html)
            }
        }
    }

    func bookmarkBody(for bookmark: BookmarkItem, indentation: Int) -> String {
        switch bookmark {
        case let .bookmark(title, url, metadata):
            return """
            \(String.indent(by: indentation))<DT><A\(metadata.stringValue) HREF="\(url)">\(Entities.escape(title))</A>
            """
        case let .folder(title, children, metadata):
            let start = """
            \(String.indent(by: indentation))<DT><H3\(metadata.stringValue) FOLDED>\(Entities.escape(title))</H3>
            \(String.indent(by: indentation))<DL><p>

            """

            let body = children.map {
                bookmarkBody(for: $0, indentation: indentation + 1)
            }.joined(separator: "\n")

            let end = """

            \(String.indent(by: indentation))</DL><p>
            """

            return start + body + end
        }
    }
}

private extension String {
    static func indent(by level: Int) -> String {
        return String(repeating: "\t", count: level)
    }
}
