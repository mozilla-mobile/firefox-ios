// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Common
import Shared

extension Attachment: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(filename, forKey: .filename)
        try container.encode(mimetype, forKey: .mimetype)
        try container.encode(location, forKey: .location)
        try container.encode(hash, forKey: .hash)
        try container.encode(size, forKey: .size)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let filename = try container.decode(String.self, forKey: .filename)
        let mimetype = try container.decode(String.self, forKey: .mimetype)
        let location = try container.decode(String.self, forKey: .location)
        let hash = try container.decode(String.self, forKey: .hash)
        let size = try container.decode(UInt64.self, forKey: .size)
        
        self.init(filename: filename, mimetype: mimetype, location: location, hash: hash, size: size)
    }

    private enum CodingKeys: String, CodingKey {
        case filename
        case mimetype
        case location
        case hash
        case size
    }
}
