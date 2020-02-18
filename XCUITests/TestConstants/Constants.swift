//
//  Constants.swift
//  XCUITests
//
//  Created by horatiu purec on 10/02/2020.
//  Copyright © 2020 Mozilla. All rights reserved.
//

let serverPort = Int.random(in: 1025..<65000)

public struct Constants {
    public static let defaultWaitTime: Double = 2
    public static let smallWaitTime: Double = 5
    public static let mediumWaitTime: Double = 10
    
    // Constants for ActivityStreamTests
    static let defaultTopSite = ["topSiteLabel": "wikipedia", "bookmarkLabel": "Wikipedia"]
    static let newTopSite = ["url": "www.mozilla.org", "topSiteLabel": "mozilla", "bookmarkLabel": "Internet for people, not profit — Mozilla"]
    static let allDefaultTopSites = ["facebook", "youtube", "amazon", "wikipedia", "twitter"]
    static let testWithDB = ["testActivityStreamPages","testTopSitesAdd", "testTopSitesOpenInNewTab", "testTopSitesOpenInNewPrivateTab", "testTopSitesBookmarkNewTopSite", "testTopSitesShareNewTopSite", "testContextMenuInLandscape"]
    // Using the DDDBBs created for these tests containing enough entries for the tests that used them listed above
    static let pagesVisitediPad = "browserActivityStreamPagesiPad.db"
    static let pagesVisitediPhone = "browserActivityStreamPagesiPhone.db"
    static let urlExample = "http://example.com"
    
    // Constants for BookmarkingTests
    static let url_1 = "test-example.html"
    static let url_2 = ["url": "test-mozilla-org.html",
                        "bookmarkLabel": "Internet for people, not profit — Mozilla"]
    static let urlLabelExample_3 = "Example Domain"
    static let url_3 = "localhost:\(serverPort)/test-fixture/test-example.html"
    static let urlLabelExample_4 = "Example Login Page 2"
    static let url_4 = "test-password-2.html"
}
