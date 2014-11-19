/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

let ONE_YEAR_IN_SECONDS = 365 * 24 * 60 * 60;

public class EnvelopeJSON : JSON {
    public init(_ jsonString: String) {
        super.init(JSON.parse(jsonString))
    }

    override public init(_ json: JSON) {
        super.init(json)
    }

    public func isValid() -> Bool {
        return !isError &&
               self["id"].isString &&
               //self["collection"].isString &&
               self["payload"].isString
    }

    public var id: String {
        return self["id"].asString!
    }
    
    public var collection: String {
        return self["collection"].asString ?? ""
    }
    
    public var payload: String {
        return self["payload"].asString!
    }
    
    public var sortindex: Int {
        return self["sortindex"].asInt ?? 0
    }

    public var modified: UInt64 {
        if (self["modified"].isInt) {
            return UInt64(self["modified"].asInt!) * 1000
        }

        if (self["modified"].isDouble) {
            return UInt64(1000 * (self["modified"].asDouble? ?? 0.0))
        }

        return 0
    }
}

public class CleartextPayloadJSON : JSON {
    public init(_ jsonString: String) {
        super.init(JSON.parse(jsonString))
    }

    override public init(_ json: JSON) {
        super.init(json)
    }

    // Override me.
    public func isValid() -> Bool {
        return !isError
    }

    public var deleted: Bool {
        let d = self["deleted"]
        if d.isBool {
            return d.asBool!
        } else {
            return false;
        }
    }

    // Override me.
    public func equalPayloads (obj: CleartextPayloadJSON) -> Bool {
        return self.deleted == obj.deleted
    }
}

/**
 * Immutable representation for Sync records.
 *
 * Envelopes consist of:
 *   Required: "id", "collection", "payload".
 *   Optional: "modified", "sortindex", "ttl".
 *
 * Deletedness is a property of the payload.
 */
@objc public class Record<T : CleartextPayloadJSON> {
    public let id: String
    public let payload: T

    public let modified: UInt64
    public let sortindex: Int
    public let ttl: Int              // Seconds.

    // This is a hook for decryption.
    // Right now it only parses the string. In subclasses, it'll parse the
    // string, decrypt the contents, and return the data as a JSON object.
    // From the docs:
    //
    //   payload  none  string 256k
    //   A string containing a JSON structure encapsulating the data of the record.
    //   This structure is defined separately for each WBO type.
    //   Parts of the structure may be encrypted, in which case the structure
    //   should also specify a record for decryption.
    //
    // @seealso EncryptedRecord.
    public class func payloadFromPayloadString(envelope: EnvelopeJSON, payload: String) -> T? {
        return T(payload)
    }

    // TODO: consider using error tuples.
    public class func fromEnvelope(envelope: EnvelopeJSON, payloadFactory: (String) -> T?) -> Record<T>? {
        if !(envelope.isValid()) {
            println("Invalid envelope.")
            return nil
        }

        let payload = payloadFactory(envelope.payload)
        if (payload == nil) {
            println("Unable to parse payload.")
            return nil
        }
        
        if payload!.isValid() {
            return Record<T>(envelope: envelope, payload: payload!)
        }
        
        println("Invalid payload \(payload!.toString(pretty: true)).")
        return nil
    }

    /**
     * Accepts an envelope and a decrypted payload.
     * Inputs are not validated. Use `fromEnvelope` above.
     */
    convenience init(envelope: EnvelopeJSON, payload: T) {
        // TODO: modified, sortindex, ttl
        self.init(id: envelope.id, payload: payload, modified: envelope.modified, sortindex: envelope.sortindex)
    }

    init(id: String, payload: T, modified: UInt64 = UInt64(time(nil)), sortindex: Int = 0, ttl: Int = ONE_YEAR_IN_SECONDS) {
        self.id = id

        self.payload = payload;

        self.modified = modified
        self.sortindex = sortindex
        self.ttl = ttl
    }
    
    func equalIdentifiers(rec: Record) -> Bool {
        return rec.id == self.id
    }
    
    // Override me.
    func equalPayloads(rec: Record) -> Bool {
        return equalIdentifiers(rec) && rec.payload.deleted == self.payload.deleted
    }
    
    func equals(rec: Record) -> Bool {
        return rec.sortindex == self.sortindex &&
               rec.modified == self.modified &&
               equalPayloads(rec)
    }
}