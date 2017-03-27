/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Account
import XCTest

class PushCryptoTests: XCTestCase {

    let push = PushCrypto.sharedInstance

    func testRoundtrip_base64urlSafe() {
        let ogString = "I am the walrus! I am the eggman!"
        let ogData = ogString.data(using: .utf8)!

        let encodedString = ogData.base64urlSafeEncodedString

        guard let decodedData = encodedString.base64urlSafeDecodedData else {
            return XCTFail("base64urlSafeDecodedData failed")
        }

        guard let decodedString = decodedData.utf8EncodedString else {
            return XCTFail("utf8EncodedString failed")
        }

        XCTAssertEqual(decodedString, ogString)
    }

    func testRoundtrip_base64urlSafe_withSpecialChars() {
        let encoded = "mW-ti1CqLQK4PyZBKy4q7g"

        XCTAssertEqual(encoded.base64urlSafeDecodedData!.base64urlSafeEncodedString, encoded)
    }

    struct Aes128GcmTest {
        let payload: String
        let recvPrivKey: String
        let authSecret: String
        let plaintext: String
    }

    func testDecrypt_aes128gcm() {
        let tests = [
            Aes128GcmTest(
                payload: "SVzmyN6TpFOehi6GNJk8uwAAABhBBDwzeKLAq5VOFJhxjoXwi7cj-30l4TWmY_44WITrgZIza_kKVO1yDxwEXAtAXpu8OiFCsWyJCGc0w3Trr3CZ5kJ-LTLIraUBhwPFSxC0geECfXIJ2Ma0NVP6Ezr6WX8t3EWluoFAlE5kkLuNbZm6HQLmDZX0jOZER3wXIx2VuXpPld0",
                recvPrivKey: "yJnRHTLit-b-dJh4b1DyO5is5Tl60mHeObpkSezBLK0",
                authSecret: "mW-ti1CqLQK4PyZBKy4q7g",
                plaintext: "I am the walrus"
            ),
            Aes128GcmTest(
                payload: "DGv6ra1nlYgDCS1FRnbzlwAAEABBBP4z9KsN6nGRTbVYI_c7VJSPQTBtkgcy27mlmlMoZIIgDll6e3vCYLocInmYWAmS6TlzAC8wEqKK6PBru3jl7A_yl95bQpu6cVPTpK4Mqgkf1CXztLVBSt2Ks3oZwbuwXPXLWyouBWLVWGNWQexSgSxsj_Qulcy4a-fN",
                recvPrivKey: "q1dXpw3UpT5VOmu_cf_v6ih07Aems3njxI-JWgLcM94",
                authSecret: "BTBZMqHH6r4Tts7J_aSIgg",
                plaintext: "When I grow up, I want to be a watermelon"
            ),
        ]

        for test in tests {
            if let deciphered = try? push.aes128gcm(payload: test.payload,
                                                    decryptWith: test.recvPrivKey,
                                                    authenticateWith: test.authSecret) {
                XCTAssertEqual(deciphered, test.plaintext)
            } else {
                XCTFail("Failed to decipher \(test.plaintext)")
            }
        }
    }

    func testFail_aes128gcm() {
        let tests = [
            Aes128GcmTest(
                payload: "bad base 64 encoding",
                recvPrivKey: "yJnRHTLit-b-dJh4b1DyO5is5Tl60mHeObpkSezBLK0",
                authSecret: "mW-ti1CqLQK4PyZBKy4q7g",
                plaintext: "bad base64"
            ),
            Aes128GcmTest(
                payload: "DGv6ra1nlYgDCS1FRnbzlwAAEABBBP4z9KsN6nGRTbVYI_c7VJSPQTBtkgcy27mlmlMoZIIgDll6e3vCYLocInmYWAmS6TlzAC8wEqKK6PBru3jl7A_yl95bQpu6cVPTpK4Mqgkf1CXztLVBSt2Ks3oZwbuwXPXLWyouBWLVWGNWQexSgSxsj_Qulcy4a-fN",
                recvPrivKey: "badkey",
                authSecret: "BTBZMqHH6r4Tts7J_aSIgg",
                plaintext: "bad key"
            ),
        ]

        for test in tests {
            do {
                let _ = try push.aes128gcm(payload: test.payload,
                                           decryptWith: test.recvPrivKey,
                                           authenticateWith: test.authSecret)

                XCTFail("Somehow, deciphered \(test.plaintext)")
            } catch PushCryptoError.base64DecodeError {
                XCTAssertEqual(test.plaintext, tests[0].plaintext)
            } catch PushCryptoError.decryptionError(_) {
                XCTAssertEqual(test.plaintext, tests[1].plaintext)
            } catch PushCryptoError.utf8EncodingError {
                XCTFail("Not tested")
            } catch {
                XCTFail("Not tested but found \(error)")
            }
        }
    }

    func testRoundTrip_aes128gcm() {
        // The real reason for this test is to test generateKeys()
        guard let keys = try? push.generateKeys() else {
            return XCTFail("Generating keys should not fail")
        }

        let plaintext = "I am the egg man!"

        guard let payload = try? push.aes128gcm(plaintext: plaintext, encryptWith: keys.p256dhPublicKey, authenticateWith: keys.auth, rs: 1024, padLen: 2) else {
            return XCTFail("Encryption should not fail")
        }

        guard let deciphered = try? push.aes128gcm(payload: payload, decryptWith: keys.p256dhPrivateKey, authenticateWith: keys.auth) else {
            return XCTFail("Decryption should not fail")
        }

        XCTAssertEqual(deciphered, plaintext)
    }

    struct AesGcmTest {
        let plaintext: String
        let recvPrivKey: String
        let authSecret: String
        let ciphertext: String
        let cryptoKey: String
        let encryption: String
    }

    func testDecrypt_aesgcm() {
        let tests = [
            AesGcmTest(
                plaintext: "I am the walrus",
                recvPrivKey: "9FWl15_QUQAWDaD3k3l50ZBZQJ4au27F1V4F0uLSD_M",
                authSecret: "R29vIGdvbyBnJyBqb29iIQ",
                ciphertext: "6nqAQUME8hNqw5J3kl8cpVVJylXKYqZOeseZG8UueKpA",
                cryptoKey: "keyid=\"dhkey\"; dh=\"BNoRDbb84JGm8g5Z5CFxurSqsXWJ11ItfXEWYVLE85Y7CYkDjXsIEc4aqxYaQ1G8BqkXCJ6DPpDrWtdWj_mugHU\"",
                encryption: "keyid=\"dhkey\"; salt=\"lngarbyKfMoi9Z75xYXmkg\""
            ),
            AesGcmTest(
                plaintext: "Small record size",
                recvPrivKey: "4h23G_KkXC9TvBSK2v0Q7ImpS2YAuRd8hQyN0rFAwBg",
                authSecret: "g2rWVHUCpUxgcL9Tz7vyeQ",
                ciphertext: "oY4e5eDatDVt2fpQylxbPJM-3vrfhDasfPc8Q1PWt4tPfMVbz_sDNL_cvr0DXXkdFzS1lxsJsj550USx4MMl01ihjImXCjrw9R5xFgFrCAqJD3GwXA1vzS4T5yvGVbUp3SndMDdT1OCcEofTn7VC6xZ-zP8rzSQfDCBBxmPU7OISzr8Z4HyzFCGJeBfqiZ7yUfNlKF1x5UaZ4X6iU_TXx5KlQy_toV1dXZ2eEAMHJUcSdArvB6zRpFdEIxdcHcJyo1BIYgAYTDdAIy__IJVCPY_b2CE5W_6ohlYKB7xDyH8giNuWWXAgBozUfScLUVjPC38yJTpAUi6w6pXgXUWffende5FreQpnMFL1L4G-38wsI_-ISIOzdO8QIrXHxmtc1S5xzYu8bMqSgCinvCEwdeGFCmighRjj8t1zRWo0D14rHbQLPR_b1P5SvEeJTtS9Nm3iibM",
                cryptoKey: "dh=BCg6ZIGuE2ZNm2ti6Arf4CDVD_8--aLXAGLYhpghwjl1xxVjTLLpb7zihuEOGGbyt8Qj0_fYHBP4ObxwJNl56bk",
                encryption: "salt=5LIDBXbvkBvvb7ZdD-T4PQ; rs=3"
            ),
            AesGcmTest(
                plaintext: "Yet another message",
                recvPrivKey: "4h23G_KkXC9TvBSK2v0Q7ImpS2YAuRd8hQyN0rFAwBg",
                authSecret: "6plwZnSpVUbF7APDXus3UQ",
                ciphertext: "uEC5B_tR-fuQ3delQcrzrDCp40W6ipMZjGZ78USDJ5sMj-6bAOVG3AK6JqFl9E6AoWiBYYvMZfwThVxmDnw6RHtVeLKFM5DWgl1EwkOohwH2EhiDD0gM3io-d79WKzOPZE9rDWUSv64JstImSfX_ADQfABrvbZkeaWxh53EG59QMOElFJqHue4dMURpsMXg",
                cryptoKey: "dh=BEaA4gzA3i0JDuirGhiLgymS4hfFX7TNTdEhSk_HBlLpkjgCpjPL5c-GL9uBGIfa_fhGNKKFhXz1k9Kyens2ZpQ",
                encryption: "salt=ZFhzj0S-n29g9P2p4-I7tA; rs=8"
            ),
            AesGcmTest(
                plaintext: "Some message",
                recvPrivKey: "4h23G_KkXC9TvBSK2v0Q7ImpS2YAuRd8hQyN0rFAwBg",
                authSecret: "aTDc6JebzR6eScy2oLo4RQ",
                ciphertext: "Oo34w2F9VVnTMFfKtdx48AZWQ9Li9M6DauWJVgXU",
                cryptoKey: "dh=BCHFVrflyxibGLlgztLwKelsRZp4gqX3tNfAKFaxAcBhpvYeN1yIUMrxaDKiLh4LNKPtj0BOXGdr-IQ-QP82Wjo",
                encryption: "salt=zCU18Rw3A5aB_Xi-vfixmA; rs=24"
            )
        ]

        for test in tests {
            if let deciphered = try? push.aesgcm(ciphertext: test.ciphertext,
                                                 decryptWith: test.recvPrivKey,
                                                 authenticateWith: test.authSecret,
                                                 encryptionHeader: test.encryption,
                                                 cryptoKeyHeader: test.cryptoKey) {
                XCTAssertEqual(deciphered, test.plaintext)
            } else {
                XCTFail("Failed to decipher \(test.plaintext)")
            }
        }
    }

    func testFail_aesgcm() {
        let tests = [
            AesGcmTest(
                plaintext: "bad base64",
                recvPrivKey: "4h23G_KkXC9TvBSK2v0Q7ImpS2YAuRd8hQyN0rFAwBg",
                authSecret: "aTDc6JebzR6eScy2oLo4RQ",
                ciphertext: "non base64",
                cryptoKey: "dh=BCHFVrflyxibGLlgztLwKelsRZp4gqX3tNfAKFaxAcBhpvYeN1yIUMrxaDKiLh4LNKPtj0BOXGdr-IQ-QP82Wjo",
                encryption: "salt=zCU18Rw3A5aB_Xi-vfixmA; rs=24"
            ),

            AesGcmTest(
                plaintext: "bad key",
                recvPrivKey: "badkey",
                authSecret: "aTDc6JebzR6eScy2oLo4RQ",
                ciphertext: "Oo34w2F9VVnTMFfKtdx48AZWQ9Li9M6DauWJVgXU",
                cryptoKey: "dh=BCHFVrflyxibGLlgztLwKelsRZp4gqX3tNfAKFaxAcBhpvYeN1yIUMrxaDKiLh4LNKPtj0BOXGdr-IQ-QP82Wjo",
                encryption: "salt=zCU18Rw3A5aB_Xi-vfixmA; rs=24"
            ),
        ]

        for test in tests {
            do {
                let _ = try push.aesgcm(ciphertext: test.ciphertext,
                                 decryptWith: test.recvPrivKey,
                                 authenticateWith: test.authSecret,
                                 encryptionHeader: test.encryption,
                                 cryptoKeyHeader: test.cryptoKey)

                XCTFail("Somehow, deciphered \(test.plaintext)")
            } catch PushCryptoError.base64DecodeError {
                XCTAssertEqual(test.plaintext, tests[0].plaintext)
            } catch PushCryptoError.decryptionError(_) {
                XCTAssertEqual(test.plaintext, tests[1].plaintext)
            } catch PushCryptoError.utf8EncodingError {
                XCTFail("Not tested")
            } catch {
                XCTFail("Not tested but found \(error)")
            }
        }
    }

    func testKeyGeneration() {
        guard let keys = try? push.generateKeys() else {
            return XCTFail("Keys can't be tested")
        }
        // We can't really test if the keys are random enough, but we can check if they 
        // roundtrip with the base64urlSafe encoding. 
        for string in [keys.p256dhPublicKey, keys.p256dhPrivateKey, keys.auth] {
            XCTAssertEqual(string.base64urlSafeDecodedData?.base64urlSafeEncodedString, string)
        }
    }
}
