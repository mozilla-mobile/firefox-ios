/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Account
import Shared

import SwiftyJSON

/**
 * Swift can't do functional factories. I would like to have one of the following
 * approaches be viable:
 *
 * 1. Derive the constructor from the consumer of the factory.
 * 2. Accept a type as input.
 *
 * Neither of these are viable, so we instead pass an explicit constructor closure.
 *
 * Most of these approaches produce either odd compiler errors, or -- worse --
 * compile and then yield runtime EXC_BAD_ACCESS (see Radar 20230159).
 *
 * For this reason, be careful trying to simplify or improve this code.
 */
public func keysPayloadFactory<T: CleartextPayloadJSON>(keyBundle: KeyBundle, _ f: @escaping (JSON) -> T) -> (String) -> T? {
    return { (payload: String) -> T? in
        let potential = EncryptedJSON(json: payload, keyBundle: keyBundle)
        if !potential.isValid() {
            return nil
        }

        let cleartext = potential.cleartext
        if cleartext == nil {
            return nil
        }
        return f(cleartext!)
    }
}

// TODO: how much do we want to move this into EncryptedJSON?
public func keysPayloadSerializer<T: CleartextPayloadJSON>(keyBundle: KeyBundle, _ f: @escaping (T) -> JSON) -> (Record<T>) -> JSON? {
    return { (record: Record<T>) -> JSON? in
        let json = f(record.payload)
        if json.isNull() {
            // This should never happen, but if it does, we don't want to leak this
            // record to the server!
            return nil
        }
        // Get the most basic kind of encoding: no pretty printing.
        // This can throw; if so, we return nil.
        // `rawData` simply calls JSONSerialization.dataWithJSONObject:options:error, which
        // guarantees UTF-8 encoded output.

        guard let bytes: Data = try? json.rawData(options: []) else { return nil }

        // Given a valid non-null JSON object, we don't ever expect a round-trip to fail.
        assert(!JSON(bytes).isNull())

        // We pass a null IV, which means "generate me a new one".
        // We then include the generated IV in the resulting record.
        if let (ciphertext, iv) = keyBundle.encrypt(bytes, iv: nil) {
            // So we have the encrypted payload. Now let's build the envelope around it.
            let ciphertext = ciphertext.base64EncodedString

            // The HMAC is computed over the base64 string. As bytes. Yes, I know.
            if let encodedCiphertextBytes = ciphertext.data(using: .ascii, allowLossyConversion: false) {
                let hmac = keyBundle.hmacString(encodedCiphertextBytes)
                let iv = iv.base64EncodedString

                // The payload is stringified JSON. Yes, I know.
                let payload: Any = JSON(["ciphertext": ciphertext, "IV": iv, "hmac": hmac]).stringify()! as Any
                let obj = ["id": record.id,
                           "sortindex": record.sortindex,
                           // This is how SwiftyJSON wants us to express a null that we want to
                    // serialize. Yes, this is gross.
                    "ttl": record.ttl ?? NSNull(),
                    "payload": payload]
                return JSON(obj)
            }
        }
        return nil
    }
}

open class Keys: Equatable {
    let valid: Bool
    let defaultBundle: KeyBundle
    var collectionKeys: [String: KeyBundle] = [String: KeyBundle]()

    public init(defaultBundle: KeyBundle) {
        self.defaultBundle = defaultBundle
        self.valid = true
    }

    public init(payload: KeysPayload?) {
        if let payload = payload, payload.isValid(),
            let keys = payload.defaultKeys {
            self.defaultBundle = keys
            self.collectionKeys = payload.collectionKeys
            self.valid = true
            return
        }
        self.defaultBundle = KeyBundle.invalid
        self.valid = false
    }

    public convenience init(downloaded: EnvelopeJSON, master: KeyBundle) {
        let f: (JSON) -> KeysPayload = { KeysPayload($0) }
        let keysRecord = Record<KeysPayload>.fromEnvelope(downloaded, payloadFactory: keysPayloadFactory(keyBundle: master, f))
        self.init(payload: keysRecord?.payload)
    }

    open class func random() -> Keys {
        return Keys(defaultBundle: KeyBundle.random())
    }

    open func forCollection(_ collection: String) -> KeyBundle {
        if let bundle = collectionKeys[collection] {
            return bundle
        }
        return defaultBundle
    }

    open func encrypter<T>(_ collection: String, encoder: RecordEncoder<T>) -> RecordEncrypter<T> {
        return RecordEncrypter(bundle: forCollection(collection), encoder: encoder)
    }

    open func asPayload() -> KeysPayload {
        let json = JSON([
            "id": "keys",
            "collection": "crypto",
            "default": self.defaultBundle.asPair(),
            "collections": mapValues(self.collectionKeys, f: { $0.asPair() })
            ])
        return KeysPayload(json)
    }

    public static func ==(lhs: Keys, rhs: Keys) -> Bool {
        return lhs.valid == rhs.valid &&
            lhs.defaultBundle == rhs.defaultBundle &&
            lhs.collectionKeys == rhs.collectionKeys
    }
}

/**
 * Yup, these are basically typed tuples.
 */
public struct RecordEncoder<T: CleartextPayloadJSON> {
    let decode: (JSON) -> T
    let encode: (T) -> JSON
}

public struct RecordEncrypter<T: CleartextPayloadJSON> {
    let serializer: (Record<T>) -> JSON?
    let factory: (String) -> T?

    init(bundle: KeyBundle, encoder: RecordEncoder<T>) {
        self.serializer = keysPayloadSerializer(keyBundle: bundle, encoder.encode)
        self.factory = keysPayloadFactory(keyBundle: bundle, encoder.decode)
    }

    init(serializer: @escaping (Record<T>) -> JSON?, factory: @escaping (String) -> T?) {
        self.serializer = serializer
        self.factory = factory
    }
}

