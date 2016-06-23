//
//  MenuTests.swift
//  Client
//
//  Created by Emily Toop on 13/04/2016.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit

class MenuTests: KIFTestCase {

    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
    }

    override func tearDown() {
        BrowserUtils.clearHistoryItems(tester())
    }

    func testOpenMenuFromHomePanel() {
        XCTFail("Test not yet implemented")
    }

    func testOpenMenuFromWebPage() {
        tester().tapViewWithAccessibilityIdentifier("url")
        let url1 = "\(webRoot)/noTitle.html"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("This page has no title")

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().waitForViewWithAccessibilityLabel("Close Menu")
        tester().tapViewWithAccessibilityLabel("Close Menu")
    }

    func testOpenMenuFromTabTray() {
        XCTFail("Test not yet implemented")
    }

    func testOpenSettingsFromMenu() {
        // open a page as the menu isn't available from home panels just yet
        tester().tapViewWithAccessibilityIdentifier("url")
        let url1 = "\(webRoot)/noTitle.html"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("This page has no title")
        
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Settings")
        // this is the done button on the settings panel
        tester().waitForViewWithAccessibilityLabel("Done")
        tester().waitForViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Done")
        tester().waitForWebViewElementWithAccessibilityLabel("This page has no title")

        // TODO: add test to open settings from home panels
        // TODO: add test to open settings from tab tray
    }

    func testOpenNewTabFromMenu() {
        tester().tapViewWithAccessibilityIdentifier("url")
        let url1 = "\(webRoot)/noTitle.html"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("This page has no title")

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("New Tab")
        // this is the done button on the settings panel
        tester().waitForAbsenceOfViewWithAccessibilityLabel("New Tab")
        tester().waitForViewWithAccessibilityLabel("Top sites")

        // TODO: add test to open new tab from home panels
        // TODO: add test to open new tab from tab tray
    }

    func testOpenNewPrivateTabFromMenu() {
        tester().tapViewWithAccessibilityIdentifier("url")
        let url1 = "\(webRoot)/noTitle.html"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("This page has no title")

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("New Private Tab")
        // this is the done button on the settings panel
        tester().waitForAbsenceOfViewWithAccessibilityLabel("New Private Tab")
        tester().waitForViewWithAccessibilityLabel("Top sites")

        // ensure that we have switched mode to private
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        let privateMode = tester().waitForViewWithAccessibilityLabel("Private Mode")
        XCTAssertEqual(privateMode.accessibilityValue, "On")
        tester().tapViewWithAccessibilityLabel("Private Mode")

        tester().tapViewWithAccessibilityLabel(url1)
        // TODO: add test to open new private tab from home panels
        // TODO: add test to open private tab from tab tray
    }

    func testOpenTopSitesFromMenu() {
        tester().tapViewWithAccessibilityIdentifier("url")
        let url1 = "\(webRoot)/noTitle.html"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("This page has no title")

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Top Sites")
        // this is the done button on the settings panel
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Top Sites")
        tester().waitForViewWithAccessibilityIdentifier("Top Sites View")
        // TODO: add test to open top sites from tab tray
    }

    func testOpenBookmarksFromMenu() {
        tester().tapViewWithAccessibilityIdentifier("url")
        let url1 = "\(webRoot)/noTitle.html"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("This page has no title")

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Bookmarks")
        // this is the done button on the settings panel
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Close Menu")
        tester().waitForViewWithAccessibilityLabel("Empty list")
        // TODO: add test to open bookmarks from tab tray
    }

    func testOpenHistoryFromMenu() {
        tester().tapViewWithAccessibilityIdentifier("url")
        let url1 = "\(webRoot)/noTitle.html"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("This page has no title")

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("History")
        // this is the done button on the settings panel
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Close Menu")
        tester().waitForViewWithAccessibilityIdentifier("History List")
        // TODO: add test to open history from tab tray
    }

    func testOpenReadingListFromMenu() {
        tester().tapViewWithAccessibilityIdentifier("url")
        let url1 = "\(webRoot)/noTitle.html"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("This page has no title")

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Reading List")
        // this is the done button on the settings panel
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Close Menu")
        tester().waitForViewWithAccessibilityIdentifier("ReadingTable")
        // TODO: add test to open reading list from tab tray
    }

    func testCloseAllTabsFromMenu() {
        XCTFail("Test not yet implemented")
    }

}
