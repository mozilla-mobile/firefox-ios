// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import GCDWebServers
import Shared
import XCTest

@testable import Client

class PocketStoriesTests: XCTestCase {
    var pocketAPI: String!
    var webServer: GCDWebServer!

    /// Setup a basic web server that binds to a random port and that has one default handler on /hello
    fileprivate func setupWebServer() throws {
        let path = Bundle(for: type(of: self)).path(forResource: "pocketglobalfeed", ofType: "json")
        let data = try Data(contentsOf: URL(fileURLWithPath: path!))

        webServer = GCDWebServer()
        webServer.addHandler(
            forMethod: "GET",
            path: "/pocketglobalfeed",
            request: GCDWebServerRequest.self
        ) { (request) -> GCDWebServerResponse in
            return GCDWebServerDataResponse(data: data, contentType: "application/json")
        }

        if webServer.start(withPort: 0, bonjourName: nil) == false {
            XCTFail("Can't start the GCDWebServer")
        }
        pocketAPI = "http://localhost:\(webServer.port)/pocketglobalfeed"
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        try setupWebServer()
    }

    override func tearDown() {
        pocketAPI = nil
        webServer = nil
        super.tearDown()
    }

    func testPocketStoriesCaching() {
        let expect = expectation(description: "Pocket")
        let pocketFeed = PocketProvider(endPoint: pocketAPI, prefs: MockProfilePrefs())
        let feedNumber = 11

        pocketFeed.fetchStories(items: feedNumber) { result in
            switch result {
            case .success(let items):
                XCTAssertEqual(
                    items.count,
                    feedNumber,
                    "We are fetching a static feed. There are \(feedNumber) items in it"
                )
            case .failure:
                XCTFail("Expected success, got \(result) instead")
            }
            self.webServer.stop() // Stop the webserver so we can check caching

            // Try again now that the webserver is down
            pocketFeed.fetchStories(items: feedNumber) { result in
                switch result {
                case .success(let items):
                    XCTAssertEqual(
                        items.count,
                        feedNumber,
                        "We are fetching a static feed. There are \(feedNumber) items in it"
                    )
                    let item = items.first
                    // These are all not optional so they should never be nil.
                    // But lets check in case someone decides to change something
                    XCTAssertNotNil(item?.domain, "Why")
                    XCTAssertNotNil(item?.imageURL, "You")
                    XCTAssertNotNil(item?.storyDescription, "Do")
                    XCTAssertNotNil(item?.title, "This")
                    XCTAssertNotNil(item?.url, "?")
                    expect.fulfill()

                case .failure:
                    XCTFail("Expected success, got \(result) instead")
                }
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}
