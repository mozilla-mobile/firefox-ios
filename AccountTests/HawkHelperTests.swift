// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Account
@testable import Client
import Foundation

import Shared
import XCTest

class HawkHelperTests: XCTestCase {
    func testSpecSignatureExample() {
        let input = "hawk.1.header\n" +
        "1353832234\n" +
        "j4h3g2\n" +
        "GET\n" +
        "/resource/1?b=1&a=2\n" +
        "example.com\n" +
        "8000\n" +
        "\n" +
        "some-app-ext-data\n"

        let expected = HawkHelper.getSignatureFor(input.utf8EncodedData, key: "werxhqb98rpaxn39848xrunpaw3489ruxnpa98w4rxn".utf8EncodedData)
        XCTAssertEqual("6R4rV5iE+NPoym+WwjeHzjAGXUtLNIxmo1vpMofpLAE=", expected)
    }

    func testSpecRequestString() {
        let timestamp = Int64(1353832234)
        let nonce = "j4h3g2"
        let extra = "some-app-ext-data"
        let url = URL(string: "http://example.com:8000/resource/1?b=1&a=2")!
        let expected = "hawk.1.header\n" +
            "1353832234\n" +
            "j4h3g2\n" +
            "GET\n" +
            "/resource/1?b=1&a=2\n" +
            "example.com\n" +
            "8000\n" +
            "\n" +
        "some-app-ext-data\n"

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        XCTAssertEqual(HawkHelper.getRequestStringFor(request, timestampString: String(timestamp), nonce: nonce, hash: "", extra: extra).components(separatedBy: "\n"), expected.components(separatedBy: "\n"))
    }

    func testSpecWithoutPayloadExample() {
        let helper = HawkHelper(id: "dh37fgj492je", key: "werxhqb98rpaxn39848xrunpaw3489ruxnpa98w4rxn".utf8EncodedData)
        let timestamp = Int64(1353832234)
        let url = URL(string: "http://example.com:8000/resource/1?b=1&a=2")!
        let nonce = "j4h3g2"
        let extra = "some-app-ext-data"
        let expected = "Hawk id=\"dh37fgj492je\", ts=\"1353832234\", nonce=\"j4h3g2\", ext=\"some-app-ext-data\", mac=\"6R4rV5iE+NPoym+WwjeHzjAGXUtLNIxmo1vpMofpLAE=\""

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let value = helper.getAuthorizationValueFor(request, at: timestamp, nonce: nonce, extra: extra)
        XCTAssertEqual(value, expected)
    }

    func testSpecWithPayloadExample() {
        let helper = HawkHelper(id: "dh37fgj492je", key: "werxhqb98rpaxn39848xrunpaw3489ruxnpa98w4rxn".utf8EncodedData)
        let body = "Thank you for flying Hawk"
        var request = URLRequest(url: URL(string: "http://example.com:8000/resource/1?b=1&a=2")!)
        request.httpMethod = "POST"
        request.httpBody = body.utf8EncodedData
        let timestamp = Int64(1353832234)
        let nonce = "j4h3g2"
        let extra = "some-app-ext-data"
        let expected = "Hawk id=\"dh37fgj492je\", ts=\"1353832234\", nonce=\"j4h3g2\", hash=\"Yi9LfIIFRtBEPt74PVmbTF/xVAwPn7ub15ePICfgnuY=\", ext=\"some-app-ext-data\", mac=\"aSe1DERmZuRl3pI36/9BdZmnErTw3sNzOOAUlfeKjVw=\""

        let value = helper.getAuthorizationValueFor(request, at: timestamp, nonce: nonce, extra: extra)
            XCTAssertEqual(value, expected)
    }

    func testGetBaseContentType() {
        XCTAssertEqual("text/plain", HawkHelper.getBaseContentTypeFor("text/plain"))
        XCTAssertEqual("text/plain", HawkHelper.getBaseContentTypeFor("text/plain;one"))
        XCTAssertEqual("text/plain", HawkHelper.getBaseContentTypeFor("text/plain;one;two"))
        XCTAssertEqual("text/html", HawkHelper.getBaseContentTypeFor("text/html;charset=UTF-8"))
        XCTAssertEqual("text/html", HawkHelper.getBaseContentTypeFor("text/html; charset=UTF-8"))
        XCTAssertEqual("text/html", HawkHelper.getBaseContentTypeFor("text/html ;charset=UTF-8"))
    }
}
