//
//  FaviconTests.swift
//  Client
//
//  Created by Wes Johnston on 11/18/14.
//  Copyright (c) 2014 Mozilla. All rights reserved.
//

import Foundation
import UIKit
import XCTest

// TODO: Move this to an AccountTest
class SiteTests: XCTestCase {
    func testEquality() {
        var siteUrl = "http://www.example.com"
        var siteUrl2 = "http://www.example2.com"
        var site11 = Site(title: "Title 1", url: siteUrl)
        var site12 = Site(title: "Title 1", url: siteUrl)
        var site2 = Site(title: "Title 2", url: siteUrl2)

        // Compare sites to sites
        XCTAssertEqual(site11, site11, "Sites are equal")
        XCTAssertEqual(site11, site12, "Sites are equal")
        XCTAssertNotEqual(site11, site2, "Sites are not equal")

        // Compare sites to strings ==
        XCTAssertTrue(site11 == siteUrl, "Sites are equal")
        XCTAssertTrue(siteUrl == site11, "Sites are equal")
        XCTAssertFalse(site11 == siteUrl2, "Sites are equal")
        XCTAssertFalse(siteUrl2 == site11, "Sites are equal")

        // Compare sites to strings !=
        XCTAssertTrue(site11 != siteUrl2, "Sites are equal")
        XCTAssertTrue(siteUrl2 != site11, "Sites are equal")
        XCTAssertFalse(site11 != siteUrl, "Sites are equal")
        XCTAssertFalse(siteUrl != site11, "Sites are equal")
    }
}