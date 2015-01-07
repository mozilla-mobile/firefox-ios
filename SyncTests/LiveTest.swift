/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest
import Client

class LiveTest: XCTestCase {
    var shouldSkip: Bool = false
    var credentials: JSON! = nil

    func loadCredentials() -> JSON? {
        if let url = NSBundle(forClass: LiveTest.self).URLForResource("signedInUser", withExtension: "json") {
            let obj = JSON.fromNSURL(url)
            if (obj.isError ||
                !obj.isDictionary) {
                return nil
            }
            return obj
        }
        return nil
    }

    override func setUp() {
        credentials = loadCredentials()
        shouldSkip = credentials == nil
    }

    func testLoadCredentials() {
        if (shouldSkip) {
            println("Skipping testLoadCredentials: no test credentials.")
            return
        }
        XCTAssertNotNil(credentials)
    }

    func testCredentialsContents() {
        if (shouldSkip) {
            println("Skipping testCredentialsContents: no test credentials.")
            return
        }

        let version: JSON = credentials!["version"]
        XCTAssertTrue(version.isInt)
        XCTAssertEqual(version.asInt!, 1, "Version is current.")

        let acc = credentials!["accountData"]

        XCTAssertNotNil(acc["email"])
        XCTAssertFalse(acc["email"].isError)
        XCTAssertFalse(acc["sessionToken"].isError)
        XCTAssertFalse(acc["verified"].isError)
        XCTAssertTrue(acc["horse"].isError)
    }
}