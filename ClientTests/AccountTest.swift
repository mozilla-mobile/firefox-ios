/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class TestAccountManager : AccountProfileManager {
    override func login(username: String, password: String, error: ((error: RequestError) -> ())) {
        let credential = NSURLCredential(user: username, password: password, persistence: .None)
        let account = MockAccountProfile()
        self.loginCallback(account: account)
        return
    }
}

/*
    func makeAuthRequest(request: String, success: (data: AnyObject?) -> (), error: (error: RequestError) -> ()) {
        if (request == "bookmarks/recent") {
            var jsonString = "["
            for i in 0...10 {
                jsonString += "{\"title\": \"Title\", \"bmkUri\": \"http://www.example.com\"},"
            }
            jsonString += "]"

            let jsonData = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            let json : AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonData!, options: NSJSONReadingOptions.MutableContainers, error: nil)

            success(data: json)
            return
        }
        
        error(error: RequestError.ConnectionFailed)
    }
*/

/*
 * A base test type for tests that need to login to the test account
 */
class AccountTest: XCTestCase {
    func withTestAccount(callback: (profile: Profile) -> Void) {
        var ranTest = false
        let expectation = self.expectationWithDescription("asynchronous request")
        var prof : Profile!

        let am = TestAccountManager(loginCallback: { (profile: Profile) -> Void in
            ranTest = true
            prof = profile
            expectation.fulfill()
        }, logoutCallback: { (profile: Profile) -> Void in
            XCTAssertTrue(ranTest, "Tests were run")
        })

        am.login("testUser", password: "testPassword") {
            (error: RequestError) -> Void in
            XCTAssertTrue(false, "Error logging in \(error)")
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10.0, handler:nil)
        if (prof == nil) {
            XCTFail("Profile never set.")
            return
        }

        callback(profile: prof)
        prof.logout()
    }
}
