// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

public protocol RemoteDevices {
    func replaceRemoteDevices(_ remoteDevices: [RemoteDevice]) -> Success
}

open class RemoteDevice {
    public let id: String?
    public let name: String
    public let type: String?
    public let isCurrentDevice: Bool
    public let lastAccessTime: Timestamp?
    public let availableCommands: [String: Any]?

    public init(
        id: String?,
        name: String,
        type: String?,
        isCurrentDevice: Bool,
        lastAccessTime: Timestamp?,
        availableCommands: [String: Any]?
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.isCurrentDevice = isCurrentDevice
        self.lastAccessTime = lastAccessTime
        self.availableCommands = availableCommands
    }
}
