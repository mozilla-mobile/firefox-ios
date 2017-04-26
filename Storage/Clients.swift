/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import SwiftyJSON

public struct RemoteClient: Equatable {
    public let guid: GUID?
    public let modified: Timestamp

    public let name: String
    public let type: String?

    let version: String?
    let protocols: [String]?

    let os: String?
    let appPackage: String?
    let application: String?
    let formfactor: String?
    let device: String?

    // Requires a valid ClientPayload (: CleartextPayloadJSON: JSON).
    public init(json: JSON, modified: Timestamp) {
        self.guid = json["id"].stringValue
        self.modified = modified
        self.name = json["name"].stringValue
        self.type = json["type"].stringValue

        self.version = json["version"].stringValue
        self.protocols = jsonsToStrings(json["protocols"].arrayValue)
        self.os = json["os"].stringValue
        self.appPackage = json["appPackage"].stringValue
        self.application = json["application"].stringValue
        self.formfactor = json["formfactor"].stringValue
        self.device = json["device"].stringValue
    }

    public init(guid: GUID?, name: String, modified: Timestamp, type: String?, formfactor: String?, os: String?) {
        self.guid = guid
        self.name = name
        self.modified = modified
        self.type = type
        self.formfactor = formfactor
        self.os = os

        self.device = nil
        self.appPackage = nil
        self.application = nil
        self.version = nil
        self.protocols = nil
    }
}

// TODO: should this really compare tabs?
public func ==(lhs: RemoteClient, rhs: RemoteClient) -> Bool {
    return lhs.guid == rhs.guid &&
        lhs.name == rhs.name &&
        lhs.modified == rhs.modified &&
        lhs.type == rhs.type &&
        lhs.formfactor == rhs.formfactor &&
        lhs.os == rhs.os
}

extension RemoteClient: CustomStringConvertible {
    public var description: String {
        return "<RemoteClient GUID: \(guid ?? "nil"), name: \(name), modified: \(modified), type: \(type ?? "nil"), formfactor: \(formfactor ?? "nil"), OS: \(os ?? "nil")>"
    }
}
