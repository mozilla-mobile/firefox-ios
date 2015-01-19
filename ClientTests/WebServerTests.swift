/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest

class WebServerTests: XCTestCase {

    let webServer = GCDWebServer()

    override func setUp() {
        super.setUp()
        webServer.addDefaultHandlerForMethod("GET", requestClass: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse! in
            return GCDWebServerDataResponse(HTML: "<html><body><p>Hello World</p></body></html>")
        }
        webServer.startWithPort(17825, bonjourName: nil)
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testWebServerIsRunning() {
        XCTAssertTrue(webServer.running)
    }

    func testWebServerIsServingRequests() {
        let response = NSString(contentsOfURL: NSURL(string: "http://localhost:17825/")!, encoding: NSUTF8StringEncoding, error: nil)
        XCTAssertNotNil(response)
        XCTAssertTrue(response == "<html><body><p>Hello World</p></body></html>")
    }

}
