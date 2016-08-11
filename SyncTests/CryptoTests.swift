/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import FxA
import UIKit
import Shared
import Storage
@testable import Sync

import XCTest

class CryptoTests: XCTestCase {
    let hmacB16 = "b1e6c18ac30deb70236bc0d65a46f7a4dce3b8b0e02cf92182b914e3afa5eebc"
    let ivB64 = "GX8L37AAb2FZJMzIoXlX8w=="

    let hmacKey = Bytes.decodeBase64("MMntEfutgLTc8FlTLQFms8/xMPmCldqPlq/QQXEjx70=")
    let encKey = Bytes.decodeBase64("9K/wLdXdw+nrTtXo4ZpECyHFNr4d7aYHqeg3KW9+m6Q=")


    let ciphertextB64 = "NMsdnRulLwQsVcwxKW9XwaUe7ouJk5Wn80QhbD80l0HEcZGCynh45qIbeYBik0lgcHbKmlIxTJNwU+OeqipN+/j7MqhjKOGIlvbpiPQQLC6/ffF2vbzL0nzMUuSyvaQzyGGkSYM2xUFt06aNivoQTvU2GgGmUK6MvadoY38hhW2LCMkoZcNfgCqJ26lO1O0sEO6zHsk3IVz6vsKiJ2Hq6VCo7hu123wNegmujHWQSGyf8JeudZjKzfi0OFRRvvm4QAKyBWf0MgrW1F8SFDnVfkq8amCB7NhdwhgLWbN+21NitNwWYknoEWe1m6hmGZDgDT32uxzWxCV8QqqrpH/ZggViEr9uMgoy4lYaWqP7G5WKvvechc62aqnsNEYhH26A5QgzmlNyvB+KPFvPsYzxDnSCjOoRSLx7GG86wT59QZw="

    let cleartextB64 = "eyJpZCI6IjVxUnNnWFdSSlpYciIsImhpc3RVcmkiOiJmaWxlOi8vL1VzZXJzL2phc29uL0xpYnJhcnkvQXBwbGljYXRpb24lMjBTdXBwb3J0L0ZpcmVmb3gvUHJvZmlsZXMva3NnZDd3cGsuTG9jYWxTeW5jU2VydmVyL3dlYXZlL2xvZ3MvIiwidGl0bGUiOiJJbmRleCBvZiBmaWxlOi8vL1VzZXJzL2phc29uL0xpYnJhcnkvQXBwbGljYXRpb24gU3VwcG9ydC9GaXJlZm94L1Byb2ZpbGVzL2tzZ2Q3d3BrLkxvY2FsU3luY1NlcnZlci93ZWF2ZS9sb2dzLyIsInZpc2l0cyI6W3siZGF0ZSI6MTMxOTE0OTAxMjM3MjQyNSwidHlwZSI6MX1dfQ=="

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testHMAC() {
        let keyBundle = KeyBundle(encKey: encKey, hmacKey: hmacKey)
        // HMAC is computed against the Base64 ciphertext.
        let ciphertextRaw: NSData = dataFromBase64(ciphertextB64)
        XCTAssertNotNil(ciphertextRaw)
        XCTAssertEqual(hmacB16, keyBundle.hmacString(ciphertextRaw))
    }

    func dataFromBase64(b64: String) -> NSData {
        return Bytes.dataFromBase64(b64)!
    }

    func testDecrypt() {
        let keyBundle = KeyBundle(encKey: encKey, hmacKey: hmacKey)
        // Decryption is done against raw bytes.
        let ciphertext = Bytes.decodeBase64(ciphertextB64)
        let iv = Bytes.decodeBase64(ivB64)
        let s = keyBundle.decrypt(ciphertext, iv: iv)
        let cleartext = NSString(data: Bytes.decodeBase64(cleartextB64),
                                 encoding: NSUTF8StringEncoding)
        XCTAssertTrue(cleartext!.isEqualToString(s!))
    }

    func testEncrypt() {
        let keyBundle = KeyBundle(encKey: encKey, hmacKey: hmacKey)
        let cleartext = Bytes.decodeBase64(cleartextB64)

        // With specified IV.
        let iv = Bytes.decodeBase64(ivB64)
        if let (b, ivOut) = keyBundle.encrypt(cleartext, iv: iv) {
            // The output IV should be the input.
            XCTAssertEqual(ivOut, iv)
            XCTAssertEqual(b, Bytes.decodeBase64(ciphertextB64))
        } else {
            XCTFail("Encrypt failed.")
        }

        // With a random IV.
        if let (b, ivOut) = keyBundle.encrypt(cleartext) {
            // The output IV should be different.
            // TODO: check that it's not empty!
            XCTAssertNotEqual(ivOut, iv)

            // The result will not match the ciphertext for which a different IV was used.
            XCTAssertNotEqual(b, Bytes.decodeBase64(ciphertextB64))
        } else {
            XCTFail("Encrypt failed.")
        }
    }
    
    func testSignVerify() {
        let cleartext = Bytes.decodeBase64(cleartextB64)
        
        // DSA
        let dsa = DSAKeyPair.generateKeyPairWithSize(1024)
        XCTAssertNotEqual(dsa, nil)
        XCTAssertNotEqual(dsa.privateKey, nil)
        XCTAssertNotEqual(dsa.publicKey, nil)
        
        let sigDSA = dsa.privateKey.signMessage(cleartext)
        XCTAssertNotEqual(sigDSA, nil)
        
        let verDSA = dsa.publicKey.verifySignature(sigDSA, againstMessage: cleartext)
        XCTAssertTrue(verDSA)
        
        // RSA
        let rsa = DSAKeyPair.generateKeyPairWithSize(1024)
        XCTAssertNotEqual(rsa, nil)
        XCTAssertNotEqual(rsa.privateKey, nil)
        XCTAssertNotEqual(rsa.publicKey, nil)
        
        let sigRSA = rsa.privateKey.signMessage(cleartext)
        XCTAssertNotEqual(sigRSA, nil)

        let verRSA = rsa.publicKey.verifySignature(sigRSA, againstMessage: cleartext)
        XCTAssertTrue(verRSA)
        
        // ECDSA
        let ecdsa = ECDSAKeyPair.generateKeyPairForGroup(ECDSAGroup.P256)
        XCTAssertNotEqual(ecdsa, nil)
        XCTAssertNotEqual(ecdsa.privateKey, nil)
        XCTAssertNotEqual(ecdsa.publicKey, nil)
        
        let sigECDSA = ecdsa.privateKey.signMessage(cleartext)
        XCTAssertNotEqual(sigECDSA, nil)
        
        let verECDSA = ecdsa.publicKey.verifySignature(sigECDSA, againstMessage: cleartext)
        XCTAssertTrue(verECDSA)

        let privBytes = ecdsa.privateKey.BinaryRepresentation()
        XCTAssertNotNil(privBytes)
        
        let privECDSA2 = ECDSAPrivateKey(binaryRepresentation: privBytes, group: .P256)
        XCTAssertNotNil(privECDSA2)
        let sigECDSA2 = privECDSA2.signMessage(cleartext)
        let verECDSA2 = ecdsa.publicKey.verifySignature(sigECDSA2, againstMessage: cleartext)
        XCTAssertTrue(verECDSA2)

        let pubBytes = ecdsa.publicKey.BinaryRepresentation()
        let pubECDSA3 = ECDSAPublicKey(binaryRepresentation: pubBytes, group: .P256)
        XCTAssertNotNil(pubECDSA3)
        let verECDSA3 = pubECDSA3.verifySignature(sigECDSA, againstMessage: cleartext)
        XCTAssertTrue(verECDSA3)

        // Just test that this runs and produces non-empty output
        let cert = ecdsa.privateKey.selfSignedCertificateWithName("Test cert", slack: 0, lifetime: 60 * 60)
        XCTAssertNotNil(cert)
    }
}
