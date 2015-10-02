/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

// Our engine choices need to persist across server changes.
// Note that EngineConfiguration is not enough to evolve an existing meta/global:
// a meta/global generated from this will have different syncIDs and will
// always use this device's engine versions.
public class EngineConfiguration: Equatable {
    let enabled: [String]
    let declined: [String]
    public init(enabled: [String], declined: [String]) {
        self.enabled = enabled
        self.declined = declined
    }

    public class func fromJSON(json: JSON) -> EngineConfiguration? {
        if json.isError {
            return nil
        }
        if let enabled = jsonsToStrings(json["enabled"].asArray) {
            if let declined = jsonsToStrings(json["declined"].asArray) {
                return EngineConfiguration(enabled: enabled, declined: declined)
            }
        }
        return nil
    }

    public func toJSON() -> JSON {
        let json: [String: AnyObject] = ["enabled": self.enabled, "declined": self.declined]
        return JSON(json)
    }
}

public func ==(lhs: EngineConfiguration, rhs: EngineConfiguration) -> Bool {
    return Set(lhs.enabled) == Set(rhs.enabled)
}

extension EngineConfiguration: CustomStringConvertible {
    public var description: String {
        return "EngineConfiguration(enabled: \(self.enabled.sort()), declined: \(self.declined.sort()))"
    }
}

// Equivalent to Android Sync's EngineSettings, but here
// we use them for meta/global itself.
public struct EngineMeta: Equatable {
    let version: Int
    let syncID: String

    public static func fromJSON(json: JSON) -> EngineMeta? {
        if let syncID = json["syncID"].asString {
            if let version = json["version"].asInt {
                return EngineMeta(version: version, syncID: syncID)
            }
        }
        return nil
    }

    public static func mapFromJSON(map: [String: JSON]?) -> [String: EngineMeta]? {
        if let map = map {
            return optFilter(mapValues(map, f: EngineMeta.fromJSON))
        }
        return nil
    }

    public func toJSON() -> JSON {
        let json: [String: AnyObject] = ["version": self.version, "syncID": self.syncID]
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
    public static func fromJSON(json: JSON) -> MetaGlobal? {
        if json.isError {
            return nil
        }
        if let syncID = json["syncID"].asString {
            if let storageVersion = json["storageVersion"].asInt {
                let engines = EngineMeta.mapFromJSON(json["engines"].asDictionary) ?? [:]
                let declined = json["declined"].asArray ?? []
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
            "engines": enginesPayload(),
            "declined": JSON(self.declined)
        ])
        return CleartextPayloadJSON(json)
    }

    public func withSyncID(syncID: String) -> MetaGlobal {
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
public class SyncMeta {
    let syncKey: KeyBundle

    var keys: Keys?
    var global: MetaGlobal?

    public init(syncKey: KeyBundle) {
        self.syncKey = syncKey
    }
}
