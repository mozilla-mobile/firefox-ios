/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

// Equivalent to Android Sync's EngineSettings, but here
// we use them for meta/global itself.
public struct EngineMeta {
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
            return optFilter(mapValues(map, EngineMeta.fromJSON))
        }
        return nil
    }
}

public struct MetaGlobal {
    let syncID: String
    let storageVersion: Int
    let engines: [String: EngineMeta]?      // Is this really optional?
    let declined: [String]?

    public static func fromPayload(string: String) -> MetaGlobal? {
        return fromPayload(JSON(string: string))
    }

    // TODO: is it more useful to support partial globals?
    // TODO: how do we return error states here?
    public static func fromPayload(json: JSON) -> MetaGlobal? {
        if json.isError {
            return nil
        }
        if let syncID = json["syncID"].asString {
            if let storageVersion = json["storageVersion"].asInt {
                let engines = EngineMeta.mapFromJSON(json["engines"].asDictionary)
                let declined = json["declined"].asArray
                return MetaGlobal(syncID: syncID,
                                  storageVersion: storageVersion,
                                  engines: engines,
                                  declined: jsonsToStrings(declined))
            }
        }
        return nil
    }
}

public class GlobalEnvelope: EnvelopeJSON {
    public lazy var global: MetaGlobal? = {
        return MetaGlobal.fromPayload(self.payload)
    }()
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
