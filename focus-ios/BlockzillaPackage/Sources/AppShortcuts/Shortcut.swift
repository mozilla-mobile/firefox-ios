/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct Shortcut: Equatable, Encodable, Hashable {
    public var url: URL
    public var name: String
    public var imageURL: URL?

    public init(url: URL, name: String = "", imageURL: URL? = nil) {
        self.url = url
        self.name = name.isEmpty ? Shortcut.defaultName(for: url) : name
        self.imageURL = imageURL
    }
}

extension Shortcut {
    private static func defaultName(for url: URL) -> String {
        if let host = url.host {
            var shortUrl = host.replacingOccurrences(of: "www.", with: "")
            if shortUrl.hasPrefix("mobile.") {
                shortUrl = shortUrl.replacingOccurrences(of: "mobile.", with: "")
            }
            if shortUrl.hasPrefix("m.") {
                shortUrl = shortUrl.replacingOccurrences(of: "m.", with: "")
            }
            if let domain = shortUrl.components(separatedBy: ".").first?.capitalized {
                return domain
            }
        }
        return ""
    }
}

extension Shortcut {
    var capital: String? {
        name.first.map(String.init)?.capitalized
    }
}

extension Shortcut: Decodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        url = try values.decode(URL.self, forKey: .url)
        name = (try? values.decode(String.self, forKey: .name)) ?? Shortcut.defaultName(for: url)
        imageURL = try? values.decode(URL.self, forKey: .imageURL)
    }
}
