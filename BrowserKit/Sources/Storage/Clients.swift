// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

public struct RemoteClient: Equatable {
    public let guid: GUID?
    public let modified: Timestamp

    public let name: String
    public let type: String?
    public let os: String?
    public let version: String?
    public let fxaDeviceId: String?

    let protocols: [String]?

    let appPackage: String?
    let application: String?
    let formfactor: String?
    let device: String?

    public init(
        guid: GUID?,
        name: String,
        modified: Timestamp,
        type: String?,
        formfactor: String?,
        os: String?,
        version: String?,
        fxaDeviceId: String?
    ) {
        self.guid = guid
        self.name = name
        self.modified = modified
        self.type = type
        self.formfactor = formfactor
        self.os = os
        self.version = version
        self.fxaDeviceId = fxaDeviceId

        self.device = nil
        self.appPackage = nil
        self.application = nil
        self.protocols = nil
    }
}

// TODO: should this really compare tabs?
public func == (lhs: RemoteClient, rhs: RemoteClient) -> Bool {
    return lhs.guid == rhs.guid &&
        lhs.name == rhs.name &&
        lhs.modified == rhs.modified &&
        lhs.type == rhs.type &&
        lhs.formfactor == rhs.formfactor &&
        lhs.os == rhs.os &&
        lhs.version == rhs.version &&
        lhs.fxaDeviceId == rhs.fxaDeviceId
}
