/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@interface ECEUtils : NSObject {
- (NSData*) generateIVFromNonce: (NSData*) aNonce andCounter: (UInt64) counter;

- (NSData*) gcmDecipher: (NSData*) cipherText withKey: (NSData*) key andIV: (NSData*) nonce;

- (NSData*) ecdh_computeSharedSecret: (NSData*) publicKey;
}
