// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public typealias Title = String
public typealias Url = String

public struct BookmarkMetadata: Equatable {
    let addedAt: Date?
    let modifiedAt: Date?

    public static var empty: BookmarkMetadata {
        BookmarkMetadata(addedAt: nil, modifiedAt: nil)
    }

    internal var stringValue: String {
        var returnValue = ""
        if let addedAt = addedAt {
            returnValue += " \(String.addDate)=\"\(Int(addedAt.timeIntervalSince1970))\""
        }
        if let modifiedAt = modifiedAt {
            returnValue += " \(String.lastModified)=\"\(Int(modifiedAt.timeIntervalSince1970))\""
        }
        return returnValue
    }
}

public enum BookmarkItem: Equatable {
    case folder(Title, [BookmarkItem], BookmarkMetadata)
    case bookmark(Title, Url, BookmarkMetadata)
}
