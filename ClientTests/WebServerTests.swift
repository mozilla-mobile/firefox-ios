/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import GCDWebServers
import XCTest

/// Minimal web server tests. This class can be used as a base class for tests that need a real web server.
/// Simply add additional handlers your test class' setUp() method.
class WebServerTests: XCTestCase {
    let webServer: GCDWebServer = GCDWebServer()
    var webServerBase: String!

    /// Setup a basic web server that binds to a random port and that has one default handler on /hello
    private func setupWebServer() {
        webServer.addHandlerForMethod("GET", path: "/hello", requestClass: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse! in
            return GCDWebServerDataResponse(HTML: "<html><body><p>Hello World</p></body></html>")
        }
        if webServer.startWithPort(0, bonjourName: nil) == false {
            XCTFail("Can't start the GCDWebServer")
        }
        webServerBase = "http://localhost:\(webServer.port)"
    }

    override func setUp() {
        super.setUp()
        setupWebServer()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testWebServerIsRunning() {
        XCTAssertTrue(webServer.running)
    }

    func testWebServerIsServingRequests() {
        let response: NSString?
        do {
            response = try NSString(contentsOfURL: NSURL(string: "\(webServerBase)/hello")!, encoding: NSUTF8StringEncoding)
        } catch _ {
            response = nil
        }
        XCTAssertNotNil(response)
        XCTAssertTrue(response == "<html><body><p>Hello World</p></body></html>")
    }
}
