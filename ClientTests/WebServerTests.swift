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
    fileprivate func setupWebServer() {
        webServer.addHandler(forMethod: "GET", path: "/hello", request: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse! in
            return GCDWebServerDataResponse(html: "<html><body><p>Hello World</p></body></html>")
        }
        if webServer.start(withPort: 0, bonjourName: nil) == false {
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
        XCTAssertTrue(webServer.isRunning)
    }

    func testWebServerIsServingRequests() {
        let response: NSString?
        do {
            response = try NSString(contentsOf: URL(string: "\(webServerBase!)/hello")!, encoding: String.Encoding.utf8.rawValue)
        } catch _ {
            response = nil
        }
        XCTAssertNotNil(response)
        XCTAssertTrue(response == "<html><body><p>Hello World</p></body></html>")
    }
}
