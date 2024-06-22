// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Common
import Shared

extension RemoteSettingsRecord: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encode(deleted, forKey: .deleted)
        try container.encode(attachment, forKey: .attachment)
        try container.encode(fields, forKey: .fields)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let lastModified = try container.decode(UInt64.self, forKey: .lastModified)
        let deleted = try container.decode(Bool.self, forKey: .deleted)
        let attachment = try container.decodeIfPresent(Attachment.self, forKey: .attachment)
        let fields = try container.decode(RsJsonObject.self, forKey: .fields)
        
        self.init(id: id, lastModified: lastModified, deleted: deleted, attachment: attachment, fields: fields)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case lastModified
        case deleted
        case attachment
        case fields
    }
}
