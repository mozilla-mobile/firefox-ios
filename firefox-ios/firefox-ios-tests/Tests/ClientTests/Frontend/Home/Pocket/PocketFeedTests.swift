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
        super.tearDown()
        pocketAPI = nil
        webServer = nil
    }

    func testPocketStoriesCaching() async throws {
        let pocketFeed = PocketProvider(endPoint: pocketAPI, prefs: MockProfilePrefs())
        let feedNumber = 11

        // Fetch stories from the API
        do {
            let items = try await pocketFeed.fetchStories(items: feedNumber)
            XCTAssertEqual(
                items.count,
                feedNumber,
                "We are fetching a static feed. There are \(feedNumber) items in it"
            )

            // Stop the webserver so we can check caching
            self.webServer.stop()

            // Fetch stories again (should use cache)
            let cachedItems = try await pocketFeed.fetchStories(items: feedNumber)
            XCTAssertEqual(
                cachedItems.count,
                feedNumber,
                "We are fetching a static feed. There are \(feedNumber) items in it"
            )

            let item = cachedItems.first
            XCTAssertNotNil(item?.domain, "Why")
            XCTAssertNotNil(item?.imageURL, "You")
            XCTAssertNotNil(item?.storyDescription, "Do")
            XCTAssertNotNil(item?.title, "This")
            XCTAssertNotNil(item?.url, "?")
        } catch {
            XCTFail("Expected success, got \(error) instead")
        }
    }
}
