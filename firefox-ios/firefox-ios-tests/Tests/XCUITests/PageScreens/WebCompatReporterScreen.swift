// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

/// Issue types of the Report Broken Site form, with their sub-options in display order.
enum WebCompatIssueType {
    case siteNotUsable
    case designBroken
    case videoOrAudio
    case other

    var title: String {
        switch self {
        case .siteNotUsable: return .WebCompatReporter.Category.SiteNotUsable
        case .designBroken: return .WebCompatReporter.Category.DesignBroken
        case .videoOrAudio: return .WebCompatReporter.Category.VideoOrAudio
        case .other: return .WebCompatReporter.Category.Other
        }
    }

    var subOptions: [(rawValue: String, title: String)] {
        switch self {
        case .siteNotUsable:
            return [
                ("browser_blocked", .WebCompatReporter.SubOption.BrowserBlocked),
                ("page_not_loading", .WebCompatReporter.SubOption.PageNotLoading),
                ("missing_items", .WebCompatReporter.SubOption.MissingItems),
                ("buttons_not_working", .WebCompatReporter.SubOption.ButtonsNotWorking)
            ]
        case .designBroken:
            return [
                ("images_not_loaded", .WebCompatReporter.SubOption.ImagesNotLoaded),
                ("items_overlapped", .WebCompatReporter.SubOption.ItemsOverlapped),
                ("items_misaligned", .WebCompatReporter.SubOption.ItemsMisaligned),
                ("items_not_visible", .WebCompatReporter.SubOption.ItemsNotVisible)
            ]
        case .videoOrAudio:
            return [
                ("no_video", .WebCompatReporter.SubOption.NoVideo),
                ("no_audio", .WebCompatReporter.SubOption.NoAudio),
                ("media_controls_broken", .WebCompatReporter.SubOption.MediaControlsBroken),
                ("playback_fails", .WebCompatReporter.SubOption.PlaybackFails),
                ("captions_missing", .WebCompatReporter.SubOption.CaptionsMissing)
            ]
        case .other:
            return []
        }
    }
}

@MainActor
final class WebCompatReporterScreen {
    private let app: XCUIApplication
    private let sel: WebCompatReporterSelectorSet

    init(app: XCUIApplication, selectors: WebCompatReporterSelectorSet = WebCompatReporterSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var navigationBar: XCUIElement { sel.NAVIGATION_BAR.element(in: app) }
    private var closeButton: XCUIElement { navigationBar.buttons[sel.CLOSE_BUTTON.value] }
    private var urlField: XCUIElement { sel.URL_FIELD.element(in: app) }
    private var urlClearButton: XCUIElement { urlField.buttons[sel.URL_CLEAR_BUTTON.value] }
    private var urlError: XCUIElement { sel.URL_ERROR.element(in: app) }
    private var categoryMenu: XCUIElement { sel.CATEGORY_MENU.element(in: app) }
    private var sendButton: XCUIElement { sel.SEND_BUTTON.element(in: app) }

    func assertIsOpen(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().waitForElementsToExist([navigationBar, urlField], timeout: timeout)
    }

    func assertIsDismissed(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToNotExist(urlField, timeout: timeout)
    }

    func tapClose() {
        closeButton.waitAndTap()
    }

    /// Drags from the navigation bar so the gesture dismisses the sheet instead of scrolling the form.
    func swipeDownToDismiss() {
        BaseTestCase().mozWaitForElementToExist(navigationBar)
        let start = navigationBar.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    func assertURLFieldValue(_ expected: String, timeout: TimeInterval = TIMEOUT) {
        let predicate = NSPredicate(format: "value == %@", expected)
        waitFor(urlField, predicate, timeout: timeout, message: "URL field value should be '\(expected)'")
    }

    func assertURLFieldIsEmpty(timeout: TimeInterval = TIMEOUT) {
        let predicate = NSPredicate(format: "value == nil OR value == ''")
        waitFor(urlField, predicate, timeout: timeout, message: "URL field should be empty")
    }

    func tapURLField() {
        urlField.waitAndTap()
    }

    func assertURLFieldIsEditing(timeout: TimeInterval = TIMEOUT) {
        let predicate = NSPredicate(format: "hasKeyboardFocus == true")
        waitFor(urlField, predicate, timeout: timeout, message: "URL field should have keyboard focus")
        BaseTestCase().mozWaitForElementToExist(urlClearButton, timeout: timeout)
    }

    /// Replaces the URL with `text` and keeps the field in edit mode.
    func replaceURL(with text: String) {
        urlClearButton.waitAndTap()
        urlField.typeText(text)
    }

    func typeURL(_ text: String) {
        urlField.typeText(text)
    }

    func assertURLErrorIsDisplayed(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(urlError, timeout: timeout)
    }

    func assertURLErrorIsNotDisplayed(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToNotExist(urlError, timeout: timeout)
    }

    func tapURLClearButton() {
        urlClearButton.waitAndTap()
    }

    /// The form only stores the URL once editing ends, so tap Done before asserting the Send button.
    func commitURLEditing() {
        urlField.typeText("\n")
        let predicate = NSPredicate(format: "hasKeyboardFocus == false")
        waitFor(urlField, predicate, timeout: TIMEOUT, message: "URL field should lose keyboard focus")
    }

    func selectIssueType(_ issueType: WebCompatIssueType) {
        categoryMenu.waitAndTap()
        sel.issueType(issueType.title).element(in: app).waitAndTap()
        let predicate = NSPredicate(format: "label == %@", issueType.title)
        waitFor(categoryMenu, predicate, timeout: TIMEOUT, message: "Issue type menu should show \(issueType.title)")
    }

    private func subOptionCells(of issueType: WebCompatIssueType) -> [XCUIElement] {
        issueType.subOptions.map { sel.subOption($0.rawValue).element(in: app) }
    }

    func assertSiteIssueSectionShowsPlaceholder(timeout: TimeInterval = TIMEOUT) {
        let header = sel.SITE_ISSUE_HEADER.element(in: app)
        BaseTestCase().waitForElementsToExist([header, categoryMenu], timeout: timeout)
        XCTAssertEqual(categoryMenu.label, .WebCompatReporter.IssueSection.CategoryPlaceholder)
        XCTAssertGreaterThanOrEqual(
            categoryMenu.frame.minY,
            header.frame.maxY,
            "The issue type menu should be below the Site Issue header"
        )
    }

    func assertSubOptionsDisplayed(for issueType: WebCompatIssueType, timeout: TimeInterval = TIMEOUT) {
        let cells = subOptionCells(of: issueType)
        BaseTestCase().waitForElementsToExist(cells, timeout: timeout)
        for (index, subOption) in issueType.subOptions.enumerated() {
            let readsTitle = cells[index].label == subOption.title || cells[index].staticTexts[subOption.title].exists
            XCTAssertTrue(readsTitle, "Sub-option should read '\(subOption.title)'")
            XCTAssertFalse(cells[index].isSelected, "'\(subOption.title)' should not be selected yet")
            if index > 0 {
                XCTAssertGreaterThan(
                    cells[index].frame.minY,
                    cells[index - 1].frame.minY,
                    "'\(subOption.title)' should be below the previous sub-option"
                )
            }
        }
    }

    /// Taps each sub-option in turn and checks it becomes the only selected one.
    func selectEachSubOption(of issueType: WebCompatIssueType) {
        let cells = subOptionCells(of: issueType)
        for (index, subOption) in issueType.subOptions.enumerated() {
            cells[index].waitAndTap()
            let predicate = NSPredicate(format: "selected == true")
            waitFor(cells[index], predicate, timeout: TIMEOUT, message: "'\(subOption.title)' should be selected")
            for (otherIndex, other) in issueType.subOptions.enumerated() where otherIndex != index {
                XCTAssertFalse(cells[otherIndex].isSelected, "'\(other.title)' should not be selected")
            }
        }
    }

    func assertSendButtonIs(enabled: Bool, timeout: TimeInterval = TIMEOUT) {
        scrollToSendButtonIfNeeded()
        let predicate = NSPredicate(format: "enabled == %@", NSNumber(value: enabled))
        let state = enabled ? "enabled" : "disabled"
        waitFor(sendButton, predicate, timeout: timeout, message: "Send Report button should be \(state)")
    }

    private func scrollToSendButtonIfNeeded() {
        var swipes = 0
        while !sendButton.exists && swipes < 3 {
            app.collectionViews.firstMatch.swipeUp()
            swipes += 1
        }
        BaseTestCase().mozWaitForElementToExist(sendButton)
    }

    private func waitFor(_ element: XCUIElement, _ predicate: NSPredicate, timeout: TimeInterval, message: String) {
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed, message)
    }
}
