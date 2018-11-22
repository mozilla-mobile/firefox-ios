/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest

import Shared
import Storage
import WebKit
import Alamofire
@testable import Client

class ClientTests: XCTestCase {

    func testSyncUA() {
        let ua = UserAgent.syncUserAgent
        let device = DeviceInfo.deviceModel()
        let systemVersion = UIDevice.current.systemVersion
        let expectedRegex = "^Firefox-iOS-Sync/[0-9\\.]+b[0-9]* \\(\(device); iPhone OS \(systemVersion)\\) \\([-_A-Za-z0-9= \\(\\)]+\\)$"
        let loc = ua.range(of: expectedRegex, options: .regularExpression)
        XCTAssertTrue(loc != nil, "Sync UA is as expected. Was \(ua)")
    }

    // Simple test to make sure the WKWebView UA matches the expected FxiOS pattern.
    func testUserAgent() {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

        let compare: (String) -> Bool = { ua in
            let range = ua.range(of: "^Mozilla/5\\.0 \\(.+\\) AppleWebKit/[0-9\\.]+ \\(KHTML, like Gecko\\) FxiOS/\(appVersion)b[0-9]* Mobile/[A-Za-z0-9]+ Safari/[0-9\\.]+$", options: .regularExpression)
            return range != nil
        }

        XCTAssertTrue(compare(UserAgent.defaultUserAgent()), "User agent computes correctly.")
        XCTAssertTrue(compare(UserAgent.cachedUserAgent(checkiOSVersion: true)!), "User agent is cached correctly.")

        let expectation = self.expectation(description: "Found Firefox user agent")

        let webView = WKWebView()
        webView.evaluateJavaScript("navigator.userAgent") { result, error in
            let userAgent = result as! String
            if compare(userAgent) {
                expectation.fulfill()
            } else {
                XCTFail("User agent did not match expected pattern! \(userAgent)")
            }
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testDesktopUserAgent() {
        let compare: (String) -> Bool = { ua in
            let range = ua.range(of: "^Mozilla/5\\.0 \\(Macintosh; Intel Mac OS X [0-9_]+\\) AppleWebKit/[0-9\\.]+ \\(KHTML, like Gecko\\) Version/[0-9\\.]+ Safari/[0-9\\.]+$", options: .regularExpression)
            return range != nil
        }

        XCTAssertTrue(compare(UserAgent.desktopUserAgent()), "Desktop user agent computes correctly.")
    }

    fileprivate func hostIsValid(_ host: String) -> Bool {
        let expectation = self.expectation(description: "Validate host for \(host)")
        let request = URLRequest(url: URL(string: "http://\(host):6571/about/license")!)
        var response: HTTPURLResponse?
        Alamofire.request(request).authenticate(usingCredential: WebServer.sharedInstance.credentials).response { (res) -> Void in
            response = res.response
            expectation.fulfill()
        }
        waitForExpectations(timeout: 100, handler: nil)
        return response?.statusCode == 200
    }

}
