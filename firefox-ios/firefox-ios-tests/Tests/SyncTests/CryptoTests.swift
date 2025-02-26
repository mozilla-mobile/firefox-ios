// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

import XCTest

class CryptoTests: XCTestCase {
    let hmacB16 = "b1e6c18ac30deb70236bc0d65a46f7a4dce3b8b0e02cf92182b914e3afa5eebc"
    let ivB64 = "GX8L37AAb2FZJMzIoXlX8w=="

    let hmacKey = Bytes.decodeBase64("MMntEfutgLTc8FlTLQFms8/xMPmCldqPlq/QQXEjx70=")!
    let encKey = Bytes.decodeBase64("9K/wLdXdw+nrTtXo4ZpECyHFNr4d7aYHqeg3KW9+m6Q=")!

    let invalidB64 = "NMsdnRulLwQsVcwxKW9XwaUe7ouJk5~~~~~~~~~~~~~~~"

    let ciphertextB64 = """
NMsdnRulLwQsVcwxKW9XwaUe7ouJk5Wn80QhbD80l0HEcZGCynh45qIbeYBik0lgcHbKmlIxTJNwU+OeqipN+/j\
7MqhjKOGIlvbpiPQQLC6/ffF2vbzL0nzMUuSyvaQzyGGkSYM2xUFt06aNivoQTvU2GgGmUK6MvadoY38hhW2LCM\
koZcNfgCqJ26lO1O0sEO6zHsk3IVz6vsKiJ2Hq6VCo7hu123wNegmujHWQSGyf8JeudZjKzfi0OFRRvvm4QAKyB\
Wf0MgrW1F8SFDnVfkq8amCB7NhdwhgLWbN+21NitNwWYknoEWe1m6hmGZDgDT32uxzWxCV8QqqrpH/ZggViEr9u\
Mgoy4lYaWqP7G5WKvvechc62aqnsNEYhH26A5QgzmlNyvB+KPFvPsYzxDnSCjOoRSLx7GG86wT59QZw=
"""

    let cleartextB64 = """
eyJpZCI6IjVxUnNnWFdSSlpYciIsImhpc3RVcmkiOiJmaWxlOi8vL1VzZXJzL2phc29uL0xpYnJhcnkvQXBwbGl\
jYXRpb24lMjBTdXBwb3J0L0ZpcmVmb3gvUHJvZmlsZXMva3NnZDd3cGsuTG9jYWxTeW5jU2VydmVyL3dlYXZlL2\
xvZ3MvIiwidGl0bGUiOiJJbmRleCBvZiBmaWxlOi8vL1VzZXJzL2phc29uL0xpYnJhcnkvQXBwbGljYXRpb24gU\
3VwcG9ydC9GaXJlZm94L1Byb2ZpbGVzL2tzZ2Q3d3BrLkxvY2FsU3luY1NlcnZlci93ZWF2ZS9sb2dzLyIsInZp\
c2l0cyI6W3siZGF0ZSI6MTMxOTE0OTAxMjM3MjQyNSwidHlwZSI6MX1dfQ==
"""

    func dataFromBase64(b64: String) -> Data {
        return Bytes.dataFromBase64(b64)!
    }

    func testBadBase64() {
        XCTAssertNil(Bytes.decodeBase64(invalidB64))
    }

    func testBase64DecodeUrlSafe() {
        var decodedData = Bytes.base64urlSafeDecodedData("VGhpcyB3b3JrcyE")
        var decodedString = String(data: decodedData!, encoding: .utf8)
        XCTAssertEqual(decodedString, "This works!")

        decodedData = Bytes.base64urlSafeDecodedData("cUw4UjRRSWNRL1pzUnFPQWJlUmZjWmhpbE4vTWtzUnREYUVyTUErPQ")
        decodedString = String(data: decodedData!, encoding: .utf8)
        XCTAssertEqual(decodedString, "qL8R4QIcQ/ZsRqOAbeRfcZhilN/MksRtDaErMA+=")

        decodedData = Bytes.base64urlSafeDecodedData("VGhpcytzaG91bGQvd29yay1maW5l")
        decodedString = String(data: decodedData!, encoding: .utf8)
        XCTAssertEqual(decodedString, "This+should/work-fine")

        decodedData = Bytes.base64urlSafeDecodedData("c29tZS90b2tlbi9zZXJ2ZXIvc3R1ZmY=")
        decodedString = String(data: decodedData!, encoding: .utf8)
        XCTAssertEqual(decodedString, "some/token/server/stuff")

        decodedData = Bytes.base64urlSafeDecodedData("c3ViamVjdHM_X2Q")
        decodedString = String(data: decodedData!, encoding: .utf8)
        XCTAssertEqual(decodedString, "subjects?_d")
    }
}
