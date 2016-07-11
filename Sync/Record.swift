/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = Logger.syncLogger

let ONE_YEAR_IN_SECONDS = 365 * 24 * 60 * 60;

/**
 * Immutable representation for Sync records.
 *
 * Envelopes consist of:
 *   Required: "id", "collection", "payload".
 *   Optional: "modified", "sortindex", "ttl".
 *
 * Deletedness is a property of the payload.
 */
public class Record<T: CleartextPayloadJSON> {
    public let id: String
    public let payload: T

    public let modified: Timestamp
    public let sortindex: Int
    public let ttl: Int?              // Seconds. Can be null, which means 'don't expire'.

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
    public class func payloadFromPayloadString(_ envelope: EnvelopeJSON, payload: String) -> T? {
        return T(payload)
    }

    // TODO: consider using error tuples.
    public class func fromEnvelope(_ envelope: EnvelopeJSON, payloadFactory: (String) -> T?) -> Record<T>? {
        if !(envelope.isValid()) {
            log.error("Invalid envelope.")
            return nil
        }

        guard let payload = payloadFactory(envelope.payload) else {
            log.error("Unable to parse payload.")
            return nil
        }

        if !payload.isValid() {
            log.warning("Invalid payload \(payload.toString(true)).")
        }

        return Record<T>(envelope: envelope, payload: payload)
    }

    /**
     * Accepts an envelope and a decrypted payload.
     * Inputs are not validated. Use `fromEnvelope` above.
     */
    convenience init(envelope: EnvelopeJSON, payload: T) {
        // TODO: modified, sortindex, ttl
        self.dynamicType.init(id: envelope.id, payload: payload, modified: envelope.modified, sortindex: envelope.sortindex)
    }

    init(id: GUID, payload: T, modified: Timestamp = Timestamp(time(nil)), sortindex: Int = 0, ttl: Int? = nil) {
        self.id = id

        self.payload = payload;

        self.modified = modified
        self.sortindex = sortindex
        self.ttl = ttl
    }

    func equalIdentifiers(_ rec: Record) -> Bool {
        return rec.id == self.id
    }

    // Override me.
    func equalPayloads(_ rec: Record) -> Bool {
        return equalIdentifiers(rec) && rec.payload.deleted == self.payload.deleted
    }

    func equals(_ rec: Record) -> Bool {
        return rec.sortindex == self.sortindex &&
               rec.modified == self.modified &&
               equalPayloads(rec)
    }
}
