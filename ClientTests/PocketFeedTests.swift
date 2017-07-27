/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import GCDWebServers
import XCTest

@testable import Client

class PocketStoriesTests: XCTestCase {

    var pocketAPI: String!
    let webServer: GCDWebServer = GCDWebServer()
    var webServerBase: String!

    /// Setup a basic web server that binds to a random port and that has one default handler on /hello
    fileprivate func setupWebServer() {
        let path = Bundle(for: type(of: self)).path(forResource: "pocketglobalfeed", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))

        webServer.addHandler(forMethod: "GET", path: "/pocketglobalfeed", request: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse! in
            return GCDWebServerDataResponse(data: data, contentType: "application/json")
        }

        if webServer.start(withPort: 0, bonjourName: nil) == false {
            XCTFail("Can't start the GCDWebServer")
        }
        webServerBase = "http://localhost:\(webServer.port)"
        pocketAPI = webServerBase + "/pocketglobalfeed"
    }

    override func setUp() {
        super.setUp()
        setupWebServer()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testPocketStoriesCaching() {
        let expect = expectation(description: "Pocket")
        let PocketFeed = Pocket(endPoint: pocketAPI)

        PocketFeed.globalFeed(items: 4).upon { result in
            let items = result.successValue!
            XCTAssertEqual(items.count, 2, "We are fetching a static feed. There are only 2 items in it")
            self.webServer.stop() // Stop the webserver so we can check caching

            // Try again now that the webserver is down
            PocketFeed.globalFeed(items: 4).upon { result in
                let items = result.successValue!
                XCTAssertEqual(items.count, 2, "We are fetching a static feed. There are only 2 items in it")
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

}
