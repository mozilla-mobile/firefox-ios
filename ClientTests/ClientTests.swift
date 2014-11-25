// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest

class ClientTests: XCTestCase {
    func testFavicons() {
        var fav : Favicons = BasicFavicons();
        var url = NSURL(string: "http://www.example.com");

        var expectation = expectationWithDescription("asynchronous request")
        fav.getForUrl(url!, options: nil, callback: { (data: Favicon) -> Void in
            XCTAssertEqual(data.siteUrl!, url!, "Site url is correct");
            XCTAssertEqual(data.sourceUrl!, FaviconConsts.DefaultFaviconUrl, "Source url is correct");
            expectation.fulfill()
        });
        waitForExpectationsWithTimeout(10.0, handler:nil)

        expectation = expectationWithDescription("asynchronous request")
        var urls = [url!, url!, url!];
        fav.getForUrls(urls, options: nil, callback: { (data: ArrayCursor<Favicon>) -> Void in
            XCTAssertTrue(data.count == urls.count, "At least one favicon was returned for each url requested");

            var favicon : Favicon = data[0]!;
            XCTAssertEqual(favicon.siteUrl!, url!, "Site url is correct");
            XCTAssertEqual(favicon.sourceUrl!, FaviconConsts.DefaultFaviconUrl, "Favicon url is correct");
            XCTAssertNotNil(favicon.img!, "Favicon image is not null");

            expectation.fulfill()
        });
        waitForExpectationsWithTimeout(10.0, handler:nil)
    }
    
    func testArrayCursor() {
        let data = ["One", "Two", "Three"];
        let t = ArrayCursor<String>(data: data);
        
        // Test subscript access
        XCTAssertNil(t[-1], "Subscript -1 returns nil");
        XCTAssertEqual(t[0]!, "One", "Subscript zero returns the correct data");
        XCTAssertEqual(t[1]!, "Two", "Subscript one returns the correct data");
        XCTAssertEqual(t[2]!, "Three", "Subscript two returns the correct data");
        XCTAssertNil(t[3], "Subscript three returns nil");

        // Test status data with default initializer
        XCTAssertEqual(t.status, CursorStatus.Success, "Cursor as correct status");
        XCTAssertEqual(t.statusMessage, "Success", "Cursor as correct status message");
        XCTAssertEqual(t.count, 3, "Cursor as correct size");

        // Test generator access
        var i = 0;
        for s in t {
            XCTAssertEqual(s, data[i], "Subscript zero returns the correct data");
            i++;
        }

        // Test creating a failed cursor
        let t2 = ArrayCursor<String>(data: data, status: CursorStatus.Failure, statusMessage: "Custom status message");
        XCTAssertEqual(t2.status, CursorStatus.Failure, "Cursor as correct status");
        XCTAssertEqual(t2.statusMessage, "Custom status message", "Cursor as correct status message");
        XCTAssertEqual(t2.count, 0, "Cursor as correct size");

        // Test subscript access return nil for a failed cursor
        XCTAssertNil(t2[0], "Subscript zero returns nil if failure");
        XCTAssertNil(t2[1], "Subscript one returns nil if failure");
        XCTAssertNil(t2[2], "Subscript two returns nil if failure");
        XCTAssertNil(t2[3], "Subscript three returns nil if failure");
    
        // Test that generator doesn't work with failed cursors
        var ran = false;
        for s in t2 {
            println("Got \(s)")
            ran = true;
        }
        XCTAssertFalse(ran, "for...in didn't run for failed cursor");
    }
}
