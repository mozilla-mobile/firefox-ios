// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct NewsModel: Codable, Hashable {
    let id: Int
    public internal(set) var text: String
    public let language: Language
    public let publishDate: Date
    public let imageUrl: URL
    public let targetUrl: URL
    public let trackingName: String

    public func hash(into: inout Hasher) {
        into.combine(id)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
