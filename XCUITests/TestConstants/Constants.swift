//
//  Constants.swift
//  XCUITests
//
//  Created by horatiu purec on 10/02/2020.
//  Copyright © 2020 Mozilla. All rights reserved.
//

let serverPort = Int.random(in: 1025..<65000)

public struct Constants {
    
    // MARK: - General constants
    public static let defaultWaitTime: Double = 2
    public static let smallWaitTime: Double = 5
    public static let mediumWaitTime: Double = 10
    public static let longWaitTime: Double = 15
    public static let pagesVisitedDB = Base.helper.iPad() ? LaunchArguments.LoadDatabasePrefix + Constants.pagesVisitediPad : LaunchArguments.LoadDatabasePrefix + Constants.pagesVisitediPhone
    
    // MARK: - Constants for ActivityStreamTests
    static let urlMozilla = "www.mozilla.org"
    static let allDefaultTopSites = ["facebook", "youtube", "amazon", "wikipedia", "twitter"]
    static let testWithDB = ["testActivityStreamPages","testTopSitesAdd", "testTopSitesOpenInNewTab", "testTopSitesOpenInNewPrivateTab", "testTopSitesBookmarkNewTopSite", "testTopSitesShareNewTopSite", "testContextMenuInLandscape"]
    
    // Using the DDDBBs created for these tests containing enough entries for the tests that used them listed above
    static let pagesVisitediPad = "browserActivityStreamPagesiPad.db"
    static let pagesVisitediPhone = "browserActivityStreamPagesiPhone.db"
    static let urlExample = "http://example.com"
    
    // MARK: - Constants for BookmarkingTests
    static let url_1 = "test-example.html"
    static let url_2 = ["url": "test-mozilla-org.html", "bookmarkLabel": "Internet for people, not profit — Mozilla"]
    static let urlLabelExample_3 = "Example Domain"
    static let url_3 = "localhost:\(serverPort)/test-fixture/test-example.html"
    static let urlLabelExample_4 = "Example Login Page 2"
    static let url_4 = "test-password-2.html"
    
    // MARK: - Constants for NavigationTest
    static let website_1 = ["url": "www.mozilla.org", "label": "Internet for people, not profit — Mozilla", "value": "mozilla.org"]
    static let website_2 = ["url": "www.example.com", "label": "Example", "value": "example", "link": "More information...", "moreLinkLongPressUrl": "http://www.iana.org/domains/example", "moreLinkLongPressInfo": "iana"]

    static let urlAddons = "addons.mozilla.org"
    static let urlGoogle = "www.google.com"
    static let popUpTestUrl = Base.helper.path(forTestPage: "test-popup-blocker.html")

    static let requestMobileSiteLabel = "Request Mobile Site"
    static let requestDesktopSiteLabel = "Request Desktop Site"

}
