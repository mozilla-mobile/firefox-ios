//
//  PushCrypto.swift
//  Client
//
//  Created by James Hugman on 2/9/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
import FxA
import Shared

let TAG_LENGTH = 16;
let KEY_LENGTH = 16;
let NONCE_LENGTH = 12;
let SHA_256_LENGTH = 32;

class PushCrypto {

    func decode(input: String) -> NSData? {
        return Bytes.decodeBase64(input)
    }

    func HMAC_hash(key key: NSData, input: NSData) -> NSData {
        return input.hmacSha256WithKey(key)
    }

    func HKDF_extract(salt salt: NSData, ikm: NSData) -> NSData {
        return HMAC_hash(key: salt, input: ikm)
    }

    func HKDF_expand(prk prk: NSData, info: NSData, len: Int) -> NSData {
        let output = NSMutableData()
        var T = NSData()
        var counter: UInt8 = 0

        while output.length < 1 {
            counter += 1
            let cbuf = NSData(bytes: [counter] as [UInt8], length: 1)

            if let TData = NSData.dataByAppendingDatas([T, info, cbuf]) as? NSData {
                T = HMAC_hash(key: prk, input: TData)
                output.appendData(T)
            }
        }
        return output.subdataWithRange(NSMakeRange(0, len))
    }
    /*
     function HKDF_expand(prk, info, l) {
         keylog('prk', prk);
         keylog('info', info);
         var output = new Buffer(0);
         var T = new Buffer(0);
         info = new Buffer(info, 'ascii');
         var counter = 0;
         var cbuf = new Buffer(1);
         while (output.length < l) {
             cbuf.writeUIntBE(++counter, 0, 1);
             T = HMAC_hash(prk, Buffer.concat([T, info, cbuf]));
             output = Buffer.concat([output, T]);
         }

         return keylog('expand', output.slice(0, l));
     }
     
     */


    /*
     function HKDF(salt, ikm, info, len) {
        return HKDF_expand(HKDF_extract(salt, ikm), info, len);
     }
     */

    func HKDF(salt salt: NSData, ikm: NSData, info: NSData, len: Int) -> NSData {
        return HKDF_expand(prk: HKDF_extract(salt: salt, ikm: ikm), info: info, len: len)
    }

    /*
     function info(base, context) {
         var result = Buffer.concat([
            new Buffer('Content-Encoding: ' + base + '\0', 'ascii'),
            context
         ]);
         keylog('info ' + base, result);
         return result;
     }
     */
    func makeInfo(base: String, context: NSData) -> NSData {
        return "Content-Encoding: \(base)".asciiEncodedData.zeroTerminated
    }

    func lengthPrefix(buffer buffer: NSData) -> NSData {
        let len = UInt16(buffer.length.bigEndian)
        let b = NSMutableData(bytes: [len] as [UInt16], length: 2)
        b.appendData(buffer)
        return b
    }

    /*
     function lengthPrefix(buffer) {
         var b = Buffer.concat([new Buffer(2), buffer]);
         b.writeUIntBE(buffer.length, 0, 2);
         return b;
     }
     */

    /*
    function extractDH(header, mode) {
        var key = header.privateKey;
        if (!key) {
            if (!header.keymap || !header.keyid || !header.keymap[header.keyid]) {
                throw new Error('No known DH key for ' + header.keyid);
            }
            key = header.keymap[header.keyid];
        }
        if (!header.keylabels[header.keyid]) {
            throw new Error('No known DH key label for ' + header.keyid);
        }
        var senderPubKey, receiverPubKey;
        if (mode === MODE_ENCRYPT) {
            senderPubKey = key.getPublicKey();
            receiverPubKey = header.dh;
        } else if (mode === MODE_DECRYPT) {
            senderPubKey = header.dh;
            receiverPubKey = key.getPublicKey();
        } else {
            throw new Error('Unknown mode only ' + MODE_ENCRYPT + ' and ' + MODE_DECRYPT + ' supported');
        }
        return {
            secret: key.computeSecret(header.dh),
            context: Buffer.concat([
                Buffer.from(header.keylabels[header.keyid], 'ascii'),
                Buffer.from([0]),
                lengthPrefix(receiverPubKey), // user agent
                lengthPrefix(senderPubKey)    // application server
            ])
        };
    }
    */

    func extractDH(header header: PushCryptoHeader, mode: PushCryptoMode) throws -> PushCryptoResult {
        let key: PushCryptoPrivateKey
        if let k = header.privateKey {
            key = k
        } else if let keyid = header.keyid, k = header.keymap?[keyid] {
            key = k
        } else {
            // throw new Error('No known DH key for ' + header.keyid);
            throw PushCryptoError()
        }
        guard let keyid = header.keyid,
            let keyLabel = header.keylabels?[keyid] else {
            // new Error('No known DH key label for ' + header.keyid);
            throw PushCryptoError()
        }
        let senderPubKey: NSData
        let receiverPubKey: NSData

        switch mode {
        case .MODE_ENCRYPT:
            senderPubKey = getPublicKey(key)
            receiverPubKey = header.dh!
        case .MODE_DECRYPT:
            senderPubKey = header.dh!
            receiverPubKey = getPublicKey(key)
        }

        let context = NSData.dataByAppendingDatas([
                keyLabel.asciiEncodedData.zeroTerminated,
                lengthPrefix(buffer: receiverPubKey),
                lengthPrefix(buffer: senderPubKey)]) as! NSData
        let secret: NSData = computeSecret(key, publicKey: header.dh!) // TODO key.computeSecret(header.dh)
        return PushCryptoResult(secret: secret, context: context)
    }


    /*
     function extractSecretAndContext(header, mode) {
         var result = { secret: null, context: new Buffer(0) };
         if (header.key) {
             result.secret = header.key;
             if (result.secret.length !== KEY_LENGTH) {
                 throw new Error('An explicit key must be ' + KEY_LENGTH + ' bytes');
             }
         } else if (header.dh) { // receiver/decrypt
             result = extractDH(header, mode);
         } else if (typeof header.keyid !== undefined) {
             result.secret = header.keymap[header.keyid];
         }
         if (!result.secret) {
             throw new Error('Unable to determine key');
         }
         keylog('secret', result.secret);
         keylog('context', result.context);
         if (header.authSecret) {
             result.secret = HKDF(
                 header.authSecret,
                 result.secret,
                 info('auth', new Buffer(0)),
                 SHA_256_LENGTH);
            keylog('authsecret', result.secret);
         }
         return result;
     }
     */
    func extractSecretAndContext(header header: PushCryptoHeader, mode: PushCryptoMode) throws -> PushCryptoResult {
        let result: PushCryptoResult
        if let key = header.key {
            if key.length != KEY_LENGTH {
                // throw new Error('An explicit key must be ' + KEY_LENGTH + ' bytes');
                throw PushCryptoError()
            }
            result = PushCryptoResult(secret: key, context: NSData())
        } else {
            result = try extractDH(header: header, mode: mode)
        }

        if let authSecret = header.authSecret {
            let info = makeInfo("auth", context: NSData())
            let secret = HKDF(salt: authSecret, ikm: result.secret, info: info, len: SHA_256_LENGTH)
            return PushCryptoResult(secret: secret, context: result.context)
        }

        return result
    }


    /*
     function webpushSecret(header, mode) {
         if (!header.authSecret) {
             throw new Error('No authentication secret for webpush');
         }
         keylog('authsecret', header.authSecret);

         var remotePubKey, senderPubKey, receiverPubKey;
         if (mode === MODE_ENCRYPT) {
             senderPubKey = header.privateKey.getPublicKey();
             remotePubKey = receiverPubKey = header.dh;
         } else if (mode === MODE_DECRYPT) {
             remotePubKey = senderPubKey = header.keyid;
             receiverPubKey = header.privateKey.getPublicKey();
         } else {
             throw new Error('Unknown mode only ' + MODE_ENCRYPT +
             ' and ' + MODE_DECRYPT + ' supported');
         }
         keylog('remote pubkey', remotePubKey);
         keylog('sender pubkey', senderPubKey);
         keylog('receiver pubkey', receiverPubKey);
         return keylog('secret dh',
             HKDF(header.authSecret,
                 header.privateKey.computeSecret(remotePubKey),
                 Buffer.concat([
                     Buffer.from('WebPush: info\0'),
                     receiverPubKey,
                     senderPubKey
                 ]),
                 SHA_256_LENGTH));
     }
     */

    func webpushSecret(header: PushCryptoHeader, mode: PushCryptoMode) throws -> NSData {
        guard let authSecret = header.authSecret else {
            throw PushCryptoError()
        }

        guard let privateKey = header.privateKey else {
            throw PushCryptoError()
        }

        let remotePubKey: NSData
        let senderPubKey: NSData
        let receiverPubKey: NSData

        switch mode {
        case .MODE_ENCRYPT:
            senderPubKey = getPublicKey(privateKey)
            remotePubKey = header.dh!
            receiverPubKey = remotePubKey
        case .MODE_DECRYPT:
            remotePubKey = header.keyid!.utf8EncodedData // TODO WTF
            senderPubKey = remotePubKey
            receiverPubKey = getPublicKey(privateKey)
        }

        let sharedSecret = computeSecret(privateKey, publicKey: remotePubKey) // TODO header.privateKey.computeSecret(remotePubKey)
        return HKDF(salt: authSecret,
                    ikm: sharedSecret,
                    info: NSData.dataByAppendingDatas([
                        "WebPush: info".utf8EncodedData.zeroTerminated,
                        receiverPubKey,
                        senderPubKey,
                     ])! as! NSData,
                    len: SHA_256_LENGTH)
    }

    /*
    function extractSecret(header, mode) {
        if (header.key) {
            if (header.key.length !== KEY_LENGTH) {
                throw new Error('An explicit key must be ' + KEY_LENGTH + ' bytes');
            }
            return keylog('secret key', header.key);
        }

        if (!header.privateKey) {
            // Lookup based on keyid
            var key = header.keymap && header.keymap[header.keyid];
            if (!key) {
            throw new Error('No saved key (keyid: "' + header.keyid + '")');
            }
            return key;
        }

        return webpushSecret(header, mode);
    }
    */


    func extractSecret(header: PushCryptoHeader, mode: PushCryptoMode) throws -> NSData {
        if let key = header.key {
            return key
        }

        guard let _ = header.privateKey else {
            if let keyid = header.keyid, let key = header.keymap?[keyid] {
                return key
            }
            // throw new Error('No saved key (keyid: "' + header.keyid + '")');
            throw PushCryptoError()
        }

        return try webpushSecret(header, mode: mode)
    }

    /*
     
        function deriveKeyAndNonce(header, mode) {
          if (!header.salt) {
            throw new Error('must include a salt parameter for ' + header.version);
          }
          var keyInfo;
          var nonceInfo;
          var secret;
          if (header.version === 'aesgcm128') {
            // really old
            keyInfo = 'Content-Encoding: aesgcm128';
            nonceInfo = 'Content-Encoding: nonce';
            secret = extractSecretAndContext(header, mode).secret;
          } else if (header.version === 'aesgcm') {
            // old
            var s = extractSecretAndContext(header, mode);
            keyInfo = info('aesgcm', s.context);
            nonceInfo = info('nonce', s.context);
            secret = s.secret;
          } else if (header.version === 'aes128gcm') {
            // latest
            keyInfo = Buffer.from('Content-Encoding: aes128gcm\0');
            nonceInfo = Buffer.from('Content-Encoding: nonce\0');
            secret = extractSecret(header, mode);
          } else {
            throw new Error('Unable to set context for mode ' + params.version);
          }
          var prk = HKDF_extract(header.salt, secret);
          var result = {
            key: HKDF_expand(prk, keyInfo, KEY_LENGTH),
            nonce: HKDF_expand(prk, nonceInfo, NONCE_LENGTH)
          };
          keylog('key', result.key);
          keylog('nonce base', result.nonce);
          return result;
        }
     */
    func deriveKeyAndNonce(header: PushCryptoHeader, mode: PushCryptoMode) throws -> PushCryptoKeyAndNonce {
        guard let salt = header.salt else {
            // throw new Error('must include a salt parameter for ' + header.version);
            throw PushCryptoError()
        }
        let keyInfo: NSData
        let nonceInfo: NSData
        let secret: NSData

        switch header.version {
        case .aesgcm128:
            // really old
            let s = try extractSecretAndContext(header: header, mode: mode)
            keyInfo = "Content-Encoding: aesgcm128".utf8EncodedData
            nonceInfo = "Content-Encoding: nonce".utf8EncodedData
            secret = s.secret
        case .aesgcm:
            // old
            let s = try extractSecretAndContext(header: header, mode: mode)
            keyInfo = makeInfo("aesgcm", context: s.context)
            nonceInfo = makeInfo("nonce", context: s.context)
            secret = s.secret
        case .aes128gcm:
            // latest
            keyInfo = "Content-Encoding: aes128gcm".utf8EncodedData.zeroTerminated
            nonceInfo = "Content-Encoding: nonce".utf8EncodedData.zeroTerminated
            secret = try extractSecret(header, mode: mode);
        }
        let prk = HKDF_extract(salt: salt, ikm: secret);
        return PushCryptoKeyAndNonce(
            key: HKDF_expand(prk: prk, info: keyInfo, len: KEY_LENGTH),
            nonce: HKDF_expand(prk: prk, info: nonceInfo, len: NONCE_LENGTH)
        )
    }

    /*
 
        /* Parse command-line arguments. */
        function parseParams(params) {
          var header = {};
          if (params.version) {
            header.version = params.version;
          } else {
            header.version = (params.padSize === 1) ? 'aesgcm128' : 'aesgcm';
          }

          header.rs = parseInt(params.rs, 10);
          if (isNaN(header.rs)) {
            header.rs = 4096;
          }
          if (header.rs <= PAD_SIZE[header.version]) {
            throw new Error('The rs parameter has to be greater than ' +
                            PAD_SIZE[header.version]);
          }

          if (params.salt) {
            header.salt = decode(params.salt);
            if (header.salt.length !== KEY_LENGTH) {
              throw new Error('The salt parameter must be ' + KEY_LENGTH + ' bytes');
            }
          }
          header.keyid = params.keyid;
          if (params.key) {
            header.key = decode(params.key);
          } else {
            header.privateKey = params.privateKey;
            if (!header.privateKey) {
              header.keymap = params.keymap || saved.keymap;
            }
            if (header.version !== 'aes128gcm') {
              header.keylabels = params.keylabels || saved.keylabels;
            }
            if (params.dh) {
              header.dh = decode(params.dh);
            }
          }
          if (params.authSecret) {
            header.authSecret = decode(params.authSecret);
          }
          return header;
        }
     */
    func parseParams(params: [String: AnyObject]) throws -> PushCryptoHeader {
        let version: PushVersion
        if let v = params["version"] as? PushVersion {
            version = v
        } else if let padSize = params["padSize"] as? Int {
            if padSize == 1 {
                version = .aesgcm128
            } else {
                version = .aesgcm
            }
        } else {
            // Unknown version error.
            throw PushCryptoError()
        }

        let rs: Int
        if let v = params["padSize"] as? Int {
            rs = v
        } else {
            rs = 4096
        }

        if rs <= version.padSize {
            // throw new Error('The rs parameter has to be greater than ' + PAD_SIZE[header.version]);
            throw PushCryptoError()
        }

        let salt: NSData?
        if let v = params["salt"] as? String {
            salt = decode(v)
            if let salt = salt where salt.length != KEY_LENGTH {
                // throw new Error('The salt parameter must be ' + KEY_LENGTH + ' bytes');
                throw PushCryptoError()
            }
        } else {
            salt = nil
        }

        let keyid = params["keyid"] as? String ?? nil

        let authSecret: NSData?
        if let v = params["authSecret"] as? String {
            authSecret = decode(v)
        } else {
            authSecret = nil
        }

        let key: NSData?
        let privateKey: PushCryptoPrivateKey?
        let keymap: [String: PushCryptoPrivateKey]?
        let keylabels: [String: String]?
        let dh: NSData?

        if let v = params["key"] as? String {
            key = decode(v)
            privateKey = nil
            keymap = nil
            keylabels = nil
            dh = nil
        } else {
            key = nil
            if let v = params["privateKey"] as? PushCryptoPrivateKey {
                privateKey = v // we still don't know what type the private key is.
                keymap = nil
            } else {
                privateKey = nil
                keymap = params["keymap"] as? [String: PushCryptoPrivateKey] ?? nil
            }

            if let v = params["keylabels"] as? [String: String] where version == .aes128gcm {
                keylabels = v
            } else {
                keylabels = nil
            }

            if let v = params["dh"] as? String {
                dh = decode(v)
            } else {
                dh = nil
            }
        }

        return PushCryptoHeader(authSecret: authSecret, dh: dh, privateKey: privateKey, key: key, keyid: keyid, keylabels: keylabels, keymap: keymap, rs: rs, salt: salt, version: version)
    }

    /*
        function generateNonce(base, counter) {
          var nonce = new Buffer(base);
          var m = nonce.readUIntBE(nonce.length - 6, 6);
          var x = ((m ^ counter) & 0xffffff) +
              ((((m / 0x1000000) ^ (counter / 0x1000000)) & 0xffffff) * 0x1000000);
          nonce.writeUIntBE(x, nonce.length - 6, 6);
          keylog('nonce' + counter, nonce);
          return nonce;
        }
     
     * generate a 96-bit nonce for use in GCM, 48-bits of which are populated *
        function generateNonce(base, index) {
          if (index >= Math.pow(2, 48)) {
            throw new CryptoError('Nonce index is too large', BAD_CRYPTO);
          }
          var nonce = base.slice(0, 12);
          nonce = new Uint8Array(nonce);
          for (var i = 0; i < 6; ++i) {
            nonce[nonce.byteLength - 1 - i] ^= (index / Math.pow(256, i)) & 0xff;
          }
          return nonce;
        }
     */

    func generateNonce(nonce: NSData, counter: Int) -> NSData {
        // TODO
        return NSData()
    }


    /*
        // Used when decrypting aes128gcm to populate the header values. Modifies the
        // header values in place and returns the size of the header.
        function readHeader(buffer, header) {
          var idsz = buffer.readUIntBE(20, 1);
          header.salt = buffer.slice(0, KEY_LENGTH);
          header.rs = buffer.readUIntBE(KEY_LENGTH, 4);
          header.keyid = buffer.slice(21, 21 + idsz);
          return 21 + idsz;
        }
     */

    func readUIntBE(data: NSData, start: Int, len: Int) -> Int {
        // TODO
        return 0
    }

    func readHeader(buffer: NSData, header: PushCryptoHeader) -> (NSData, PushCryptoHeader) {
        let idsz = readUIntBE(buffer, start: 20, len: 1)
        let rs = readUIntBE(buffer, start: KEY_LENGTH, len: 4)

        let salt = buffer.subdataWithRange(NSMakeRange(0, KEY_LENGTH))
        let endHeader = 21 + idsz
        let keyid = buffer.subdataWithRange(NSMakeRange(21, endHeader)).utf8EncodedString

        let newBuffer = buffer.subdataWithRange(NSMakeRange(endHeader, buffer.length))

        let newHeader = PushCryptoHeader(authSecret: header.authSecret, dh: header.dh, privateKey: header.privateKey, key: header.key, keyid: keyid, keylabels: header.keylabels, keymap: header.keymap, rs: rs, salt: salt, version: header.version)

        return (newBuffer, newHeader)
    }

    /*
        function decryptRecord(key, counter, buffer, header) {
          keylog('decrypt', buffer);
          var nonce = generateNonce(key.nonce, counter);
          var gcm = crypto.createDecipheriv(AES_GCM, key.key, nonce);
          gcm.setAuthTag(buffer.slice(buffer.length - TAG_LENGTH));
          var data = gcm.update(buffer.slice(0, buffer.length - TAG_LENGTH));
          data = Buffer.concat([data, gcm.final()]);
          keylog('decrypted', data);
          var padSize = PAD_SIZE[header.version];
          var pad = data.readUIntBE(0, padSize);
          if (pad + padSize > data.length) {
            throw new Error('padding exceeds block size');
          }
          keylog('padding', data.slice(0, padSize + pad));
          var padCheck = new Buffer(pad);
          padCheck.fill(0);
          if (padCheck.compare(data.slice(padSize, padSize + pad)) !== 0) {
            throw new Error('invalid padding');
          }
          return data.slice(padSize + pad);
        }
     */

    func gcmDecipheriv(key: NSData, nonce: NSData, buffer: NSData) -> NSData {
        /*
         var gcm = crypto.createDecipheriv(AES_GCM, key.key, nonce);
          gcm.setAuthTag(buffer.slice(buffer.length - TAG_LENGTH));
          var data = gcm.update(buffer.slice(0, buffer.length - TAG_LENGTH));
          data = Buffer.concat([data, gcm.final()]);
          keylog('decrypted', data);
         */
        return NSData()
    }

    func decryptRecord(key: PushCryptoKeyAndNonce, counter: Int, buffer: NSData, header: PushCryptoHeader) throws -> NSData {

        let nonce = generateNonce(key.nonce, counter: counter)

        let data = gcmDecipheriv(key.key, nonce: nonce, buffer: buffer)
        let padSize = header.version.padSize
        let pad = readUIntBE(data, start: 0, len: padSize)
        if pad + padSize > data.length {
            // throw new Error('padding exceeds block size');
            throw PushCryptoError()
        }

        let padCheck = NSData().dataLeftZeroPaddedToLength(UInt(pad)) as! NSData
        let dataSlice = data.subdataWithRange(NSMakeRange(padSize, pad))
        if !padCheck.isEqualToData(dataSlice) {
            // throw new Error('invalid padding');
            throw PushCryptoError()
        }
        let padEnd = padSize + pad
        return data.subdataWithRange(NSMakeRange(padEnd, data.length - padEnd))
    }

    /*
         **
         * Decrypt some bytes.  This uses the parameters to determine the key and block
         * size, which are described in the draft.  Binary values are base64url encoded.
         *
         * |params.version| contains the version of encoding to use: aes128gcm is the latest,
         * but aesgcm and aesgcm128 are also accepted (though the latter two might
         * disappear in a future release).  If omitted, assume aesgcm, unless
         * |params.padSize| is set to 1, which means aesgcm128.
         *
         * If |params.key| is specified, that value is used as the key.
         *
         * If |params.keyid| is specified without |params.dh|, the keyid value is used
         * to lookup the |params.keymap| for a buffer containing the key.
         *
         * For version aesgcm and aesgcm128, |params.dh| includes the public key of the sender.  The ECDH key
         * pair used to decrypt is looked up using |params.keymap[params.keyid]|.
         *
         * Version aes128gcm is stricter.  The |params.privateKey| includes the private
         * key of the receiver.  The keyid is extracted from the header and used as the
         * ECDH public key of the sender.
         *
        function decrypt(buffer, params) {
          var header = parseParams(params);
          if (header.version === 'aes128gcm') {
            var headerLength = readHeader(buffer, header);
            buffer = buffer.slice(headerLength);
          }
          var key = deriveKeyAndNonce(header, MODE_DECRYPT);
          var start = 0;
          var result = new Buffer(0);

          for (var i = 0; start < buffer.length; ++i) {
            var end = start + header.rs + TAG_LENGTH;
            if (end === buffer.length) {
              throw new Error('Truncated payload');
            }
            end = Math.min(end, buffer.length);
            if (end - start <= TAG_LENGTH) {
              throw new Error('Invalid block: too small at ' + i);
            }
            var block = decryptRecord(key, i, buffer.slice(start, end),
                                      header);
            result = Buffer.concat([result, block]);
            start = end;
          }
          return result;
        }
     */
    func decrypt(buffer data: NSData, params: [String: AnyObject]) throws -> NSData {
        var header = try parseParams(params)
        let buffer: NSData
        if header.version == .aes128gcm {
            (buffer, header) = readHeader(data, header: header)
        } else {
            buffer = data
        }

        let key = try deriveKeyAndNonce(header, mode: .MODE_DECRYPT)
        var start = 0
        var i = 0
        let result = NSMutableData()

        while start < buffer.length {
            var end = start + header.rs + TAG_LENGTH
            if end == buffer.length { // == WTF
                // throw new Error('Truncated payload');
                throw PushCryptoError()
            }

            end = min(end, buffer.length) // WTF

            if end - start <= TAG_LENGTH {
                // throw new Error('Invalid block: too small at ' + i);
                throw PushCryptoError()
            }

            let encryptedBlock = buffer.subdataWithRange(NSMakeRange(start, end - start))
            let block = try decryptRecord(key, counter: i, buffer: encryptedBlock, header: header);
            result.appendData(block)
            start = end;

            i += 1
        }

        return result
    }
}

extension PushCrypto {
    func getPublicKey(privateKey: PushCryptoPrivateKey) -> NSData {
        return NSData()
    }

    func computeSecret(privateKey: PushCryptoPrivateKey, publicKey: NSData) -> NSData {
        return NSData()
    }
}

typealias PushCryptoPrivateKey = NSData

// TODO split header up into two types (one with .key, one without)
struct PushCryptoHeader {
    let authSecret: NSData?
    let dh: NSData?   // a public key
    let privateKey: PushCryptoPrivateKey? // some kind of keypair key.getPublicKey(), key.computeSecret(dh)
    let key: NSData? // result.secret

    let keyid: String?
    let keylabels: [String: String]?

    let keymap: [String: NSData]?
    let rs: Int
    let salt: NSData?
    let version: PushVersion
}

struct PushCryptoResult {
    let secret: NSData
    let context: NSData
}

struct PushCryptoKeyAndNonce {
    let key: NSData
    let nonce: NSData
}

struct PushCryptoError: ErrorType {}

enum PushCryptoMode: String {
    case MODE_DECRYPT = "decrypt"
    case MODE_ENCRYPT = "encrypt"
}

enum PushVersion {
    case aesgcm128
    case aesgcm
    case aes128gcm

    var padSize: Int {
        switch self {
        case aesgcm128:
            return 1
        case aesgcm:
            return 2
        case aes128gcm:
            return 2
        }
    }
}
