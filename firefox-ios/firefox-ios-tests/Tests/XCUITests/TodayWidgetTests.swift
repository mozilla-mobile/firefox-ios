// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

// Selectors
// Widget buttons
let editWidgetButton = "com.apple.springboardhome.application-shortcut-item.configure-widget"
let editHomeScreenButton = "com.apple.springboardhome.application-shortcut-item.rearrange-icons"
let removeWidgetButton = "com.apple.springboardhome.application-shortcut-item.remove-widget"

// Widget Buttons Identifier
var goToCopiedLink = springboard.buttons["Go to Copied Link"]
var newPrivateSearch = springboard.buttons["New Private Search"]
var newSearch = springboard.buttons["New Search"]
var clearPrivateTabs = springboard.buttons["Clear Private Tabs"]

// Widget coordinates
let normalized = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))

// Get the screen size
let screenSize = springboard.windows.element(boundBy: 0).frame.size

// Calculate the center-right coordinate (x: right edge, y: middle of the screen)
let centerRightX = screenSize.width * 0.95  // Adjust this value if you want slightly away from the edge
let centerRightY = screenSize.height / 2

// Create the coordinate using the calculated points
let coordinate = springboard.coordinate(withNormalizedOffset: CGVector(
    dx: centerRightX / screenSize.width, dy: centerRightY / screenSize.height))

// Functions
enum SwipeDirection {
    case swipeUp
    case swipeRight
}

private func widgetExist() -> Bool {
    let firefoxWidgetButton = springboard
        .buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Firefox")).element.exists
    let firefoxWidgetSecureSearchButton = springboard
        .buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Private Tab")).element.exists
    let firefoxCopiedLinkWidget = springboard.buttons
        .matching(NSPredicate(format: "label CONTAINS[c] %@", "Copied Link")).element.exists
    return firefoxWidgetButton || firefoxWidgetSecureSearchButton || firefoxCopiedLinkWidget
}

private func goToTodayWidgetPage() {
    // Swipe right until the "Screen Time" icon appears
    if #unavailable(iOS 16) {
        while !springboard.textFields["SpotlightSearchField"].exists {
            springboard.swipeRight()
        }
    } else {
        while !springboard.icons["Screen Time"].exists {
            springboard.swipeRight()
        }
    }
}

private func checkPresenceFirefoxWidget() -> Bool {
    let maxSwipes = 3
    var firefoxWidgetExists = false
    var numberOfSwipes = 0

    // Initial check for widget presence
    if widgetExist() {
        firefoxWidgetExists = true
    } else {
        // Perform swipe up until the widget is found or maxSwipes reached
        while !springboard.buttons["Edit"].exists && numberOfSwipes < maxSwipes {
            springboard.swipeUp()
            if widgetExist() {
                firefoxWidgetExists = true
                break
            }
            numberOfSwipes += 1
        }
    }

    return firefoxWidgetExists
}

private func checkFirefoxShortcutsOptions() {
    let maxSwipes = 3
    var swipeCount = 0
    while !springboard.buttons["Edit"].exists && swipeCount < maxSwipes {
        springboard.swipeUp()
        swipeCount += 1
    }
    XCTAssertTrue(springboard.buttons.matching(
        NSPredicate(format: "label CONTAINS[c] %@", "Firefox")).element.exists,
                  "Search in Firefox Option doesn't exist"
    )
    XCTAssertTrue(springboard.buttons.matching(
        NSPredicate(format: "label CONTAINS[c] %@", "Private Tab")).element.exists,
                  "Search in Private Tab Option doesn't exist"
    )
    XCTAssertTrue(springboard.buttons.matching(
        NSPredicate(format: "label CONTAINS[c] %@", "Private Tabs")).element.exists,
                  "Close Private Tabs option doesn't exist"
    )
    XCTAssertTrue(springboard.buttons.matching(
        NSPredicate(format: "label CONTAINS[c] %@", "Copied Link")).element.exists,
                  "Go to copied link option doesn't exist"
    )
}

// swiftlint:disable:next type_body_length
class TodayWidgetTests: BaseTestCase {
    private func removeFirefoxWidget() {
        let maxSwipes = 3
        var numberOfSwipes = 0
        let widgetLabels = ["Firefox", "Private Tab", "Copied Link"]
        // Function to press and hold on a widget if it exists
        func pressAndHoldWidget(matching label: String) -> Bool {
            let widget = springboard.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", label)).element
            if widget.exists {
                widget.press(forDuration: 1)
                return true
            }
            return false
        }
        // Swipe up until the "Edit" button is visible or maxSwipes is reached
        while !springboard.buttons["Edit"].exists && numberOfSwipes < maxSwipes {
            springboard.swipeUp()
            numberOfSwipes += 1
        }
        // Attempt to press and hold on any of the Firefox widget elements
        var widgetFound = false
        for label in widgetLabels where pressAndHoldWidget(matching: label) {
                widgetFound = true
                break
        }

        guard widgetFound else {
                XCTFail("Firefox widget not found")
                return
        }
        if #unavailable(iOS 16) {
            mozWaitElementHittable(element: springboard.buttons["Remove Widget"], timeout: TIMEOUT)
            springboard.buttons["Remove Widget"].waitAndTap()
        } else {
            mozWaitElementHittable(element: springboard.buttons[removeWidgetButton], timeout: TIMEOUT)
            springboard.buttons[removeWidgetButton].waitAndTap()
        }

        waitForElementsToExist(
            [
                springboard.alerts.buttons["Remove"],
                springboard.alerts.buttons["Cancel"]
            ]
        )

        mozWaitElementHittable(element: springboard.alerts.buttons["Remove"], timeout: TIMEOUT)
        springboard.alerts.buttons["Remove"].waitAndTap()
    }

    private func checkFirefoxAvailablesWidgets() {
        let maxWidgetCount = 5
        var widgetCount = maxWidgetCount
        // Check existence of widgets by swiping left through the widget list
        mozWaitForElementToExist(springboard.staticTexts["Quick Actions"])
        springboard.swipeLeft()
        mozWaitForElementToExist(springboard.staticTexts["Firefox Shortcuts"])
        springboard.swipeLeft()
        mozWaitForElementToExist(springboard.staticTexts["Quick View"])
        springboard.swipeLeft()
        mozWaitForElementToExist(springboard.staticTexts["Quick View"])
        springboard.swipeLeft()
        mozWaitForElementToExist(springboard.staticTexts["Website Shortcuts"])
        // Reset swipes and navigate back to "Quick Actions" if needed
        var quickActionExists = springboard.staticTexts["Quick Actions"].exists
        while !quickActionExists && widgetCount > 0 {
            springboard.swipeRight()
            quickActionExists = springboard.staticTexts["Quick Actions"].exists
            widgetCount -= 1
        }
        XCTAssertTrue(quickActionExists, "Failed to find 'Quick Actions' after swiping back.")
    }

    private func removeFirefoxShortcutWidget() {
        let maxSwipes = 3
        var numberOfSwipes = 0
        // Function to press and hold on a widget if it exists
        func pressAndHoldWidget(matching label: String) {
            let widget = springboard.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", label)).element
            if widget.exists {
                widget.press(forDuration: 1)
            }
        }
        // Swipe up until the "Edit" button is visible or maxSwipes is reached
        while !springboard.buttons["Edit"].exists && numberOfSwipes < maxSwipes {
            springboard.swipeUp()
            numberOfSwipes += 1
        }

        let firefoxSearchOption = springboard.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Firefox")).element.exists
        let firefoxPrivateSearchOption = springboard.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Private Tab")).element.exists
        let firefoxClearPrivateTabsOption = springboard.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Private Tabs")).element.exists
        let firefoxCopiedLinkOptions = springboard.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Copied Link")).element.exists
        if firefoxSearchOption && firefoxPrivateSearchOption &&
            firefoxClearPrivateTabsOption && firefoxCopiedLinkOptions {
            pressAndHoldWidget(matching: "Firefox")
        }

        mozWaitElementHittable(element: springboard.buttons[removeWidgetButton], timeout: TIMEOUT)
        springboard.buttons[removeWidgetButton].waitAndTap()

        mozWaitForElementToExist(springboard.alerts.buttons["Remove"])
        mozWaitForElementToExist(springboard.alerts.buttons["Cancel"])

        mozWaitElementHittable(element: springboard.alerts.buttons["Remove"], timeout: TIMEOUT)
        springboard.alerts.buttons["Remove"].waitAndTap()
    }

    private func checkFirefoxWidgetOptions() {
        let maxSwipes = 3
        var swipeCount = 0
        // Swipe up until the "Edit" button is visible or maxSwipes is reached
        while !springboard.buttons["Edit"].exists && swipeCount < maxSwipes {
            springboard.swipeUp()
            swipeCount += 1
        }
        // Long press on the Firefox widget
        longPressOnWidget(widgetType: "Firefox", duration: 1)
        // Assert the presence of widget options
        if #unavailable(iOS 16) {
            XCTAssertTrue(springboard.buttons["Edit Widget"].exists, "Edit Widget option not found.")
            XCTAssertTrue(springboard.buttons["Edit Home Screen"].exists, "Edit Home Screen option not found.")
            XCTAssertTrue(springboard.buttons["Remove Widget"].exists, "Remove Widget option not found.")
        } else {
            XCTAssertTrue(springboard.buttons[removeWidgetButton].exists, "Remove Widget option not found.")
            XCTAssertTrue(springboard.buttons[editHomeScreenButton].exists, "Edit Home Screen option not found.")
            XCTAssertTrue(springboard.buttons[editWidgetButton].exists, "Edit Widget option not found.")
        }
    }

    private func clickEditWidget() {
        mozWaitForElementToExist(springboard
            .buttons[editWidgetButton])
        springboard
            .buttons[editWidgetButton].waitAndTap()
    }

    private func longPressOnWidget(widgetType: String, duration: Double) {
        let widget = springboard.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", widgetType)).element
        mozWaitForElementToExist(widget)
        widget.press(forDuration: duration)
    }

    private func tapOnWidget(widgetType: String) {
        let widget = springboard.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", widgetType)).element
        mozWaitElementHittable(element: widget, timeout: TIMEOUT)
        widget.waitAndTap()
    }

    private func allowCopyFromOtherApps() {
        iOS_Settings.launch()
        // Wait for "General" to appear and swipe up until "org.mozilla.Fennes is found
        while !iOS_Settings.staticTexts["org.mozill.ios.Fennec"].exists {
            iOS_Settings.swipeUp()
        }
        // Tap the first Firefox entry
        iOS_Settings.staticTexts["org.mozilla.ios.Fennec"].waitAndTap()
        // Wait for "Paste from Other Apps" button, tap it, then allow copying
        iOS_Settings.buttons["Paste from Other Apps"].waitAndTap()
        iOS_Settings.staticTexts["Allow"].waitAndTap()
    }

    private func addWidget(widgetName: String) {
        if iPad() {
            springboard.buttons["Add Widget"].waitAndTap()
        } else {
            if #available(iOS 18, *) {
                springboard.icons["Screen Time"].press(forDuration: 3)
                if springboard.buttons["Edit Home Screen"].exists {
                    springboard.buttons["Edit Home Screen"].waitAndTap()
                }
            }
            springboard.buttons["Edit"].waitAndTap()
            springboard.buttons["Add Widget"].waitAndTap()
        }
        mozWaitElementHittable(element: springboard.searchFields["Search Widgets"], timeout: TIMEOUT)
        springboard.searchFields["Search Widgets"].waitAndTap()
        springboard.searchFields["Search Widgets"].typeText(widgetName)
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", widgetName+" (")
        let cells = springboard.cells.matching(predicate)
        cells.element.waitAndTap()
    }

    private func findAndTapWidget(widgetType: String) {
        let widget = springboard.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", widgetType)).element
        widget.waitAndTap()
    }

    private func removeWidgetIfExists(widgetType: String) {
        if checkPresenceFirefoxWidget() {
            removeFirefoxWidget()
        }
    }

    private func addAndSearchForWidget(widgetName: String) {
        addWidget(widgetName: widgetName)
        mozWaitElementHittable(element: springboard.searchFields["Search Widgets"], timeout: TIMEOUT)
        springboard.searchFields["Search Widgets"].waitAndTap()
        springboard.searchFields["Search Widgets"].typeText(widgetName)
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", widgetName + " (")
        let cells = springboard.cells.matching(predicate)
        cells.element.waitAndTap()
    }

    // TESTS
    // https://mozilla.testrail.io/index.php?/cases/view/2769289
    func testNewSearchWidget() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("iOS 16 is required")
        }
        XCUIDevice.shared.press(.home)
        // Go to Today Widget Page
        goToTodayWidgetPage()
        // Remove Firefox Widget if present
        removeWidgetIfExists(widgetType: "Firefox")
        // Add Firefox Widget
        if iPad() {
            coordinate.press(forDuration: 3)
        }
        addWidget(widgetName: "Fennec")
        // Check available widgets
        checkFirefoxAvailablesWidgets()
        // Add Quick Action Widget
        springboard.buttons[" Add Widget"].waitAndTap()
        springboard.swipeDown()
        springboard.buttons["Done"].waitAndTap()
        // Check Quick Action widget options
        checkFirefoxWidgetOptions()
        // Edit Widget and check the options
        springboard.buttons[editWidgetButton].waitAndTap()
        mozWaitElementHittable(element: newSearch, timeout: TIMEOUT)
        newSearch.waitAndTap()
        // Verify widget actions
        if #unavailable(iOS 17) {
            goToCopiedLink = springboard.staticTexts["Go to Copied Link"]
            newPrivateSearch = springboard.staticTexts["New Private Search"]
            newSearch = springboard.staticTexts["New Search"]
            clearPrivateTabs = springboard.staticTexts["Clear Private Tabs"]
        }
        mozWaitForElementToExist(goToCopiedLink)
        XCTAssertTrue(goToCopiedLink.exists)
        XCTAssertTrue(newPrivateSearch.exists)
        XCTAssertTrue(clearPrivateTabs.exists)
        newSearch.waitAndTap()
        // Tap outside alert to close it
        mozWaitForElementToExist(newSearch)
        coordinate.tap()
        // Check New Search action
        tapOnWidget(widgetType: "Firefox")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2769297
    func testNewPrivateSearchWidget() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("iOS 16 is required")
        }
        // Return to the Home screen
        XCUIDevice.shared.press(.home)
        // Navigate to the Today Widget Page
        goToTodayWidgetPage()
        // Remove Firefox Widget if it exists
        if checkPresenceFirefoxWidget() {
            removeFirefoxWidget()
        }
        // Add Firefox Widget
        if iPad() {
            coordinate.press(forDuration: 3)
        }
        addWidget(widgetName: "Fennec")
        // Check available widgets
        checkFirefoxAvailablesWidgets()
        // Add Quick Action Widget
        springboard.buttons[" Add Widget"].waitAndTap()
        springboard.swipeDown()
        springboard.buttons["Done"].waitAndTap()
        // Verify options available in the Quick Action Widget
        checkFirefoxWidgetOptions()
        // Edit widget and interact with options
        if #unavailable(iOS 16) {
            springboard.buttons["Edit Widget"].waitAndTap()
        } else {
            springboard.buttons[editWidgetButton].waitAndTap()
        }
        mozWaitElementHittable(element: newSearch, timeout: TIMEOUT)
        newSearch.waitAndTap()
        if #unavailable(iOS 17) {
            goToCopiedLink = springboard.staticTexts["Go to Copied Link"]
            newPrivateSearch = springboard.staticTexts["New Private Search"]
            newSearch = springboard.staticTexts["New Search"]
            clearPrivateTabs = springboard.staticTexts["Clear Private Tabs"]
        }
        // Verify the existence of New Search-related buttons
        mozWaitForElementToExist(goToCopiedLink, timeout: TIMEOUT)
        XCTAssertTrue(goToCopiedLink.exists, "Go to Copied Link button not found.")
        XCTAssertTrue(newPrivateSearch.exists, "New Private Search button not found.")
        XCTAssertTrue(clearPrivateTabs.exists, "Clear Private Tabs button not found.")
        // Start a new private search
        mozWaitElementHittable(element: newPrivateSearch, timeout: TIMEOUT)
        newPrivateSearch.waitAndTap()
        // Tap outside the alert to dismiss it
        mozWaitForElementToExist(newPrivateSearch)
        coordinate.tap()
        tapOnWidget(widgetType: "Private Tab")
        // Verify the presence of Private Mode message
        mozWaitForElementToExist(app.staticTexts["Leave no traces on this device"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2769300
    func testGoToCopiedLinkWidget() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("iOS 16 is required")
        }
        let copiedString = "mozilla.org"
        // Press Home and navigate to Today Widget Page
        XCUIDevice.shared.press(.home)
        goToTodayWidgetPage()
        // Remove Firefox Widget if it already exists
        if checkPresenceFirefoxWidget() {
            removeFirefoxWidget()
        }
        // Add Firefox Widget
        if iPad() {
            coordinate.press(forDuration: 3)
        }
        addWidget(widgetName: "Fennec")
        checkFirefoxAvailablesWidgets()
        // Add Quick Action Widget
        springboard.buttons[" Add Widget"].waitAndTap()
        springboard.swipeDown()
        springboard.buttons["Done"].waitAndTap()
        // Check available options in Quick Action Widget
        checkFirefoxWidgetOptions()
        // Tap on Edit Widget and check the available options
        if #unavailable(iOS 16) {
            springboard.buttons["Edit Widget"].waitAndTap()
        } else {
            springboard.buttons[editWidgetButton].waitAndTap()
        }
        mozWaitElementHittable(element: newSearch, timeout: TIMEOUT)
        newSearch.waitAndTap()
        if #unavailable(iOS 17) {
            goToCopiedLink = springboard.staticTexts["Go to Copied Link"]
            newPrivateSearch = springboard.staticTexts["New Private Search"]
            newSearch = springboard.staticTexts["New Search"]
            clearPrivateTabs = springboard.staticTexts["Clear Private Tabs"]
        }
        // Ensure the Go To Copied Link option exists
        mozWaitForElementToExist(goToCopiedLink, timeout: TIMEOUT)
        XCTAssertTrue(goToCopiedLink.exists, "Go To Copied Link button not found.")
        XCTAssertTrue(newPrivateSearch.exists, "New Private Search button not found.")
        XCTAssertTrue(clearPrivateTabs.exists, "Clear Private Tabs button not found.")
        // Tap Go To Copied Link
        mozWaitElementHittable(element: goToCopiedLink, timeout: TIMEOUT)
        goToCopiedLink.waitAndTap()
        // Tap outside the alert to close it
        coordinate.tap()
        // Copy the string to the clipboard
        UIPasteboard.general.string = copiedString
        tapOnWidget(widgetType: "Copied Link")
        // Handle paste alert
        if #available(iOS 16, *) {
            mozWaitElementHittable(element: springboard.alerts.buttons["Allow Paste"], timeout: TIMEOUT)
            springboard.alerts.buttons["Allow Paste"].waitAndTap()
        }

        // Verify the copied string is in the URL field
        mozWaitForElementToExist(urlBarAddress, timeout: TIMEOUT)
        mozWaitForValueContains(urlBarAddress, value: copiedString, timeout: TIMEOUT)
        guard let urlField = urlBarAddress.value as? String else {
            XCTFail("Expected value to be a String but found \(type(of: urlBarAddress.value))")
            return
        }
        XCTAssertTrue(urlField.contains(copiedString),
                      "URL does not contain the copied string.")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2783001
    func testFxShortcutSearchWidget() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("iOS 16 is required")
        }
        XCUIDevice.shared.press(.home)
        goToTodayWidgetPage()
        // Remove Firefox Widget if it already exists
        if checkPresenceFirefoxWidget() {
            removeFirefoxWidget()
        }
        // Add Firefox Widget
        if iPad() {
            coordinate.press(forDuration: 3)
        }
        addWidget(widgetName: "Fennec")
        checkFirefoxAvailablesWidgets()
        // Add Firefox Shortcut Widget
        springboard.swipeLeft()
        mozWaitForElementToExist(springboard.staticTexts["Firefox Shortcuts"])
        springboard.buttons[" Add Widget"].waitAndTap()
        springboard.swipeDown()
        springboard.buttons["Done"].waitAndTap()
        checkFirefoxShortcutsOptions()
        springboard.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Firefox")).element.waitAndTap()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2783002
    func testFxShortcutPrivateSearchWidget() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("iOS 16 is required")
        }
        XCUIDevice.shared.press(.home)
        goToTodayWidgetPage()
        // Remove Firefox Widget if it already exists
        if checkPresenceFirefoxWidget() {
            removeFirefoxWidget()
        }
        // Add Firefox Widget
        if iPad() {
            coordinate.press(forDuration: 3)
        }
        addWidget(widgetName: "Fennec")
        checkFirefoxAvailablesWidgets()
        // Add Firefox Shortcut Widget
        springboard.swipeLeft()
        mozWaitForElementToExist(springboard.staticTexts["Firefox Shortcuts"])
        springboard.buttons[" Add Widget"].waitAndTap()
        springboard.swipeDown()
        springboard.buttons["Done"].waitAndTap()
        checkFirefoxShortcutsOptions()
        mozWaitElementHittable(element: springboard.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Private Tab")
        ).element.firstMatch, timeout: TIMEOUT)
        springboard.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] %@", "Private Tab")
        ).element.firstMatch.waitAndTap()

        // Verify the presence of Private Mode message
        mozWaitForElementToExist(app.staticTexts["Leave no traces on this device"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2783003
    func testFxShortcutGoToCopiedLinkWidget() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("iOS 16 is required")
        }
        let copiedString = "mozilla.org"
        UIPasteboard.general.string = copiedString
        XCUIDevice.shared.press(.home)

        goToTodayWidgetPage()
        // Remove Firefox Widget if it already exists
        if checkPresenceFirefoxWidget() {
            removeFirefoxWidget()
        }
        // Add Firefox Widget
        if iPad() {
            coordinate.press(forDuration: 3)
        }
        addWidget(widgetName: "Fennec")
        checkFirefoxAvailablesWidgets()
        // Add Firefox Shortcut Widget
        springboard.swipeLeft()
        mozWaitForElementToExist(springboard.staticTexts["Firefox Shortcuts"])
        springboard.buttons[" Add Widget"].waitAndTap()
        springboard.swipeDown()
        springboard.buttons["Done"].waitAndTap()
        checkFirefoxShortcutsOptions()
        mozWaitElementHittable(element: springboard.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Copied Link")
        ).element, timeout: TIMEOUT)
        springboard.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] %@", "Copied Link")
        ).element.waitAndTap()
        mozWaitElementHittable(element: springboard.alerts.buttons["Allow Paste"], timeout: TIMEOUT)
        springboard.alerts.buttons["Allow Paste"].waitAndTap()
        // Verify the copied string is in the URL field
        mozWaitForElementToExist(urlBarAddress, timeout: TIMEOUT)
        mozWaitForValueContains(urlBarAddress, value: copiedString, timeout: TIMEOUT)
        guard let urlField = urlBarAddress.value as? String else {
            XCTFail("Expected value to be a String but found \(type(of: urlBarAddress.value))")
            return
        }
        XCTAssertTrue(urlField.contains(copiedString),
                      "URL does not contain the copied string.")
    }
}
