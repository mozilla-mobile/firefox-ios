/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON

public struct FxADevicePushParams {
    let callback: String
    let publicKey: String
    let authKey: String
}

public struct FxADevice {
    let name: String
    let id: String?
    let type: String?
    let pushParams: FxADevicePushParams?
    let isCurrentDevice: Bool

    fileprivate init(name: String, id: String?, type: String?, isCurrentDevice: Bool = false, push: FxADevicePushParams?) {
        self.name = name
        self.id = id
        self.type = type
        self.isCurrentDevice = isCurrentDevice
        self.pushParams = push
    }

    static func forRegister(_ name: String, type: String, push: FxADevicePushParams?) -> FxADevice {
        return FxADevice(name: name, id: nil, type: type, push: push)
    }

    static func forUpdate(_ name: String, id: String, push: FxADevicePushParams?) -> FxADevice {
        return FxADevice(name: name, id: id, type: nil, push: push)
    }

    func toJSON() -> JSON {
        var parameters = [String: String]()
        parameters["name"] = name
        parameters["id"] = id
        parameters["type"] = type
        if let push = self.pushParams {
            parameters["pushCallback"] = push.callback
            parameters["pushPublicKey"] = push.publicKey
            parameters["pushAuthKey"] = push.authKey
        }
        return JSON(parameters as NSDictionary)
    }

    static func fromJSON(_ json: JSON) -> FxADevice? {
        guard json.error == nil,
            let id = json["id"].string,
            let name = json["name"].string,
            let type = json["type"].string else {
                return nil
        }

        let isCurrentDevice = json["isCurrentDevice"].bool ?? false

        let push: FxADevicePushParams?
        if let pushCallback = json["pushCallback"].stringValue(),
            let publicKey = json["pushPublicKey"].stringValue(), publicKey != "",
            let authKey   = json["pushAuthKey"].stringValue(), authKey != "" {
            push = FxADevicePushParams(callback: pushCallback, publicKey: publicKey, authKey: authKey)
        } else {
            push = nil
        }

        return FxADevice(name: name, id: id, type: type, isCurrentDevice: isCurrentDevice, push: push)
    }
}
