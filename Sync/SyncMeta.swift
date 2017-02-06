/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON

// Our engine choices need to persist across server changes.
// Note that EngineConfiguration is not enough to evolve an existing meta/global:
// a meta/global generated from this will have different syncIDs and will
// always use this device's engine versions.
open class EngineConfiguration: Equatable {
    let enabled: [String]
    let declined: [String]
    public init(enabled: [String], declined: [String]) {
        self.enabled = enabled
        self.declined = declined
    }

    open class func fromJSON(_ json: JSON) -> EngineConfiguration? {
        if json.isError() {
            return nil
        }
        if let enabled = jsonsToStrings(json["enabled"].array) {
            if let declined = jsonsToStrings(json["declined"].array) {
                return EngineConfiguration(enabled: enabled, declined: declined)
            }
        }
        return nil
    }

    open func toJSON() -> JSON {
        let json: [String: AnyObject] = ["enabled": self.enabled as AnyObject, "declined": self.declined as AnyObject]
        return JSON(json)
    }
}

public func ==(lhs: EngineConfiguration, rhs: EngineConfiguration) -> Bool {
    return Set(lhs.enabled) == Set(rhs.enabled)
}

extension EngineConfiguration: CustomStringConvertible {
    public var description: String {
        return "EngineConfiguration(enabled: \(self.enabled.sorted()), declined: \(self.declined.sorted()))"
    }
}

// Equivalent to Android Sync's EngineSettings, but here
// we use them for meta/global itself.
public struct EngineMeta: Equatable {
    let version: Int
    let syncID: String

    public static func fromJSON(_ json: JSON) -> EngineMeta? {
        if let syncID = json["syncID"].string {
            if let version = json["version"].int {
                return EngineMeta(version: version, syncID: syncID)
            }
        }
        return nil
    }

    public static func mapFromJSON(_ map: [String: JSON]?) -> [String: EngineMeta]? {
        if let map = map {
            return optFilter(mapValues(map, f: EngineMeta.fromJSON))
        }
        return nil
    }

    public func toJSON() -> JSON {
        let json: [String: AnyObject] = ["version": self.version as AnyObject, "syncID": self.syncID as AnyObject]
        return JSON(json)
    }
}

public func ==(lhs: EngineMeta, rhs: EngineMeta) -> Bool {
    return (lhs.version == rhs.version) && (lhs.syncID == rhs.syncID)
}

public struct MetaGlobal: Equatable {
    let syncID: String
    let storageVersion: Int
    let engines: [String: EngineMeta]
    let declined: [String]

    // TODO: is it more useful to support partial globals?
    // TODO: how do we return error states here?
    public static func fromJSON(_ json: JSON) -> MetaGlobal? {
        if json.isError() {
            return nil
        }
        if let syncID = json["syncID"].string {
            if let storageVersion = json["storageVersion"].int {
                let engines = EngineMeta.mapFromJSON(json["engines"].dictionary) ?? [:]
                let declined = json["declined"].array ?? []
                return MetaGlobal(syncID: syncID,
                                  storageVersion: storageVersion,
                                  engines: engines,
                                  declined: jsonsToStrings(declined) ?? [])
            }
        }
        return nil
    }

    public func enginesPayload() -> JSON {
        return JSON(mapValues(engines, f: { $0.toJSON() }))
    }

    // TODO: make a whole record JSON for this.
    public func asPayload() -> CleartextPayloadJSON {
        let json: JSON = JSON([
            "syncID": self.syncID,
            "storageVersion": self.storageVersion,
            "engines": enginesPayload().dictionaryObject as Any,
            "declined": self.declined
        ])
        return CleartextPayloadJSON(json)
    }

    public func withSyncID(_ syncID: String) -> MetaGlobal {
        return MetaGlobal(syncID: syncID, storageVersion: self.storageVersion, engines: self.engines, declined: self.declined)
    }

    public func engineConfiguration() -> EngineConfiguration {
        return EngineConfiguration(enabled: Array(engines.keys), declined: declined)
    }
}

public func ==(lhs: MetaGlobal, rhs: MetaGlobal) -> Bool {
    return (lhs.syncID == rhs.syncID) &&
           (lhs.storageVersion == rhs.storageVersion) &&
           optArrayEqual(lhs.declined, rhs: rhs.declined) &&
           optDictionaryEqual(lhs.engines, rhs: rhs.engines)
}

/**
 * Encapsulates a meta/global, identity-derived keys, and keys.
 */
open class SyncMeta {
    let syncKey: KeyBundle

    var keys: Keys?
    var global: MetaGlobal?

    public init(syncKey: KeyBundle) {
        self.syncKey = syncKey
    }
}
