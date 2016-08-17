/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public struct FxADevice {
    let name: String
    let id: String?
    let type: String?

    private init(name: String, id: String?, type: String?) {
        self.name = name
        self.id = id
        self.type = type
    }

    static func forRegister(name: String, type: String) -> FxADevice {
        return FxADevice(name: name, id: nil, type: type)
    }

    static func forUpdate(name: String, id: String) -> FxADevice {
        return FxADevice(name: name, id: id, type: nil)
    }

    func toJSON() -> JSON {
        var parameters = [String: String]()
        parameters["name"] = name
        parameters["id"] = id
        parameters["type"] = type

        return JSON(parameters)
    }

    static func fromJSON(json: JSON) -> FxADevice? {
        guard !json.isError,
            let id = json["id"].asString,
            let name = json["name"].asString,
            let type = json["type"].asString else {
                return nil
        }

        return FxADevice(name: name, id: id, type: type)
    }
}