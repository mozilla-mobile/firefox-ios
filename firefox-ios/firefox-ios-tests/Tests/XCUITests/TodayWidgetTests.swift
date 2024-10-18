// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

// Selectors

// Widget buttons
let editWidgetButton = "com.apple.springboardhome.application-shortcut-item.configure-widget"
let editHomeScreenButton = "com.apple.springboardhome.application-shortcut-item.rearrange-icons"
let removeWidgetButton = "com.apple.springboardhome.application-shortcut-item.remove-widget"

// Buttons Identifier
let goToCopiedLink = "Go to Copied Link"
let privateModeButtonToggle = "FirefoxHomepage.OtherButtons.PrivateModeToggle"
let privateModeButtonToggleiPad = "TopTabsViewController.privateModeButton"

// Widget coordinates
let normalized = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))

// Get the screen size
let screenSize = springboard.windows.element(boundBy: 0).frame.size

// Calculate the center-right coordinate (x: right edge, y: middle of the screen)
let centerRightX = screenSize.width * 0.95  // Adjust this value if you want slightly away from the edge
let centerRightY = screenSize.height / 2

// Create the coordinate using the calculated points
let coordinate = springboard.coordinate(withNormalizedOffset: CGVector(dx: centerRightX / screenSize.width, dy: centerRightY / screenSize.height))

class TodayWidgetTests: BaseTestCase {
    enum SwipeDirection {
        case up
        case right
    }

    private func widgertExist() -> Bool {
        let firefoxWidgetButton = springboard
            .buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Firefox")).element.exists
        let firefoxWidgetSecureSearchButton = springboard
            .buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Private Tab")).element.exists
        let firefoxCopiedLinkWidget = springboard.buttons
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Copied Link")).element.exists
        return firefoxWidgetButton || firefoxWidgetSecureSearchButton || firefoxCopiedLinkWidget
    }

    private func checkPresenceFifefoxWidget() -> Bool {
        let maxSwipes = 3
        var firefoxWidgetExists = false
        var numberOfSwipes = 0

        // Initial check for widget presence
        if widgertExist() {
            firefoxWidgetExists = true
        } else {
            // Perform swipe up until the widget is found or maxSwipes reached
            while !springboard.buttons["Edit"].exists && numberOfSwipes < maxSwipes {
                springboard.swipeUp()
                if widgertExist() {
                    firefoxWidgetExists = true
                    break
                }
                numberOfSwipes += 1
            }
        }

        return firefoxWidgetExists
    }

    private func removeFirefoxWidget() {
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

        // Attempt to press and hold on any of the Firefox widget elements
        pressAndHoldWidget(matching: "Firefox")
        pressAndHoldWidget(matching: "Private Tab")
        pressAndHoldWidget(matching: "Copied Link")

        // Wait for and tap the remove button
        mozWaitElementHittable(element: springboard.buttons[removeWidgetButton], timeout: 5)
        springboard.buttons[removeWidgetButton].tap()

        // Wait for the removal alert buttons to appear
        mozWaitForElementToExist(springboard.alerts.buttons["Remove"])
        mozWaitForElementToExist(springboard.alerts.buttons["Cancel"])

        // Confirm widget removal
        mozWaitElementHittable(element: springboard.alerts.buttons["Remove"], timeout: 5)
        springboard.alerts.buttons["Remove"].tap()
    }

    private func checkFirefoxAvailablesWidgets() {
        let maxWidgetCount = 5
        var widgetCount = maxWidgetCount

        // Check existence of widgets by swiping left through the widget list
        XCTAssertTrue(springboard.staticTexts["Quick Actions"].exists, "Quick Actions widget not found.")
        springboard.swipeLeft()

        XCTAssertTrue(springboard.staticTexts["Firefox Shortcuts"].exists, "Firefox Shortcuts widget not found.")
        springboard.swipeLeft()

        XCTAssertTrue(springboard.staticTexts["Quick View"].exists, "Quick View widget not found (first check).")
        springboard.swipeLeft()

        XCTAssertTrue(springboard.staticTexts["Quick View"].exists, "Quick View widget not found (second check).")
        springboard.swipeLeft()

        XCTAssertTrue(springboard.staticTexts["Website Shortcuts"].exists, "Website Shortcuts widget not found.")

        // Reset swipes and navigate back to "Quick Actions" if needed
        var quickActionExists = springboard.staticTexts["Quick Actions"].exists
        while !quickActionExists && widgetCount > 0 {
            springboard.swipeRight()
            quickActionExists = springboard.staticTexts["Quick Actions"].exists
            widgetCount -= 1
        }

        XCTAssertTrue(quickActionExists, "Failed to find 'Quick Actions' after swiping back.")
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
        XCTAssertTrue(springboard.buttons[removeWidgetButton].exists, "Remove Widget option not found.")
        XCTAssertTrue(springboard.buttons[editHomeScreenButton].exists, "Edit Home Screen option not found.")
        XCTAssertTrue(springboard.buttons[editWidgetButton].exists, "Edit Widget option not found.")
    }

    private func goToTodayWidgetPage() {
        // Swipe right until the "Screen Time" icon appears
        while !springboard.icons["Screen Time"].exists {
            springboard.swipeRight()
        }
    }

    private func clickEditWidget() {
        mozWaitForElementToExist(springboard
            .buttons[editWidgetButton])
        springboard
            .buttons[editWidgetButton].tap()
    }

    private func longPressOnWidget(widgetType: String, duration: Double) {
        let widget = springboard.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", widgetType)).element
        mozWaitForElementToExist(widget)
        widget.press(forDuration: duration)
    }

    private func tapOnWidget(widgetType: String) {
        let widget = springboard.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", widgetType)).element
        mozWaitElementHittable(element: widget, timeout: 5)
        widget.tap()
    }

    private func allowCopyFromOtherApps() {
        iOS_Settings.launch()

        // Wait for "General" to appear and swipe up until "org.mozilla.Fennes is found
        while !iOS_Settings.staticTexts["org.mozill.ios.Fennec"].exists {
            iOS_Settings.swipeUp()
        }

        // Tap the first Firefox entry
        iOS_Settings.staticTexts["org.mozilla.ios.Fennec"].tap()

        // Wait for "Paste from Other Apps" button, tap it, then allow copying
        mozWaitForElementToExist(iOS_Settings.buttons["Paste from Other Apps"])
        iOS_Settings.buttons["Paste from Other Apps"].tap()

        mozWaitForElementToExist(iOS_Settings.staticTexts["Allow"])
        iOS_Settings.staticTexts["Allow"].tap()
    }

    private func addWidget(widgetName: String) {
        if iPad() {
            mozWaitForElementToExist(springboard.buttons["Add Widget"])
            springboard.buttons["Add Widget"].tap()
        } else {
            springboard.buttons["Edit"].tap()
            mozWaitForElementToExist(springboard.buttons["Add Widget"])
            springboard.buttons["Add Widget"].tap()
        }

        mozWaitElementHittable(element: springboard.searchFields["Search Widgets"], timeout: 5)
        springboard.searchFields["Search Widgets"].tap()
        springboard.searchFields["Search Widgets"].typeText(widgetName)
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", widgetName+" (")
        let cells = springboard.cells.matching(predicate)
        cells.element.tap()
    }

    private func findAndTapWidget(widgetType: String) {
        let widget = springboard.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", widgetType)).element
        mozWaitForElementToExist(widget)
        widget.tap()
    }

    private func swipeUntilExists(element: XCUIElement, maxSwipes: Int = 3, direction: SwipeDirection = .up) {
        var swipes = 0
        while !element.exists && swipes < maxSwipes {
            if direction == .up {
                springboard.swipeUp()
            } else {
                springboard.swipeRight()
            }
            swipes += 1
        }
    }

    private func removeWidgetIfExists(widgetType: String) {
        if checkPresenceFifefoxWidget() {
            removeFirefoxWidget()
        }
    }

    private func addAndSearchForWidget(widgetName: String) {
        addWidget(widgetName: widgetName)
        mozWaitElementHittable(element: springboard.searchFields["Search Widgets"], timeout: 5)
        springboard.searchFields["Search Widgets"].tap()
        springboard.searchFields["Search Widgets"].typeText(widgetName)
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", widgetName + " (")
        let cells = springboard.cells.matching(predicate)
        cells.element.tap()
    }

    // TESTS
    // https://mozilla.testrail.io/index.php?/cases/view/2769289
    func testNewSearchWidget() {
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
        springboard.buttons[" Add Widget"].tap()
        springboard.swipeDown()
        springboard.buttons["Done"].tap()

        // Check Quick Action widget options
        checkFirefoxWidgetOptions()

        // Edit Widget and check the options
        springboard.buttons[editWidgetButton].tap()
        mozWaitElementHittable(element: springboard.buttons["New Search"], timeout: 5)
        springboard.buttons["New Search"].tap()

        // Verify widget actions
        mozWaitForElementToExist(springboard.buttons[goToCopiedLink])
        XCTAssertTrue(springboard.buttons[goToCopiedLink].exists)
        XCTAssertTrue(springboard.buttons["New Private Search"].exists)
        XCTAssertTrue(springboard.buttons["Clear Private Tabs"].exists)
        springboard.buttons["New Search"].tap()

        // Tap outside alert to close it
        coordinate.tap()

        // Check New Search action
        tapOnWidget(widgetType: "Firefox")

        // Verify private mode toggle based on device type
        let elementToAssert = iPad() ? privateModeButtonToggleiPad : privateModeButtonToggle
        XCTAssertTrue(app.buttons[elementToAssert].value as! String == "Off")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2769297
    func testNewPrivateSearchWidget() {
        // Return to the Home screen
        XCUIDevice.shared.press(.home)

        // Navigate to the Today Widget Page
        goToTodayWidgetPage()

        // Remove Firefox Widget if it exists
        if checkPresenceFifefoxWidget() {
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
        springboard.buttons[" Add Widget"].tap()
        springboard.swipeDown()
        springboard.buttons["Done"].tap()

        // Verify options available in the Quick Action Widget
        checkFirefoxWidgetOptions()

        // Edit widget and interact with options
        springboard.buttons[editWidgetButton].tap()
        mozWaitElementHittable(element: springboard.buttons["New Search"], timeout: 5)
        springboard.buttons["New Search"].tap()

        // Verify the existence of New Search-related buttons
        mozWaitForElementToExist(springboard.buttons[goToCopiedLink], timeout: 5)
        XCTAssertTrue(springboard.buttons[goToCopiedLink].exists, "Go to Copied Link button not found.")
        XCTAssertTrue(springboard.buttons["New Private Search"].exists, "New Private Search button not found.")
        XCTAssertTrue(springboard.buttons["Clear Private Tabs"].exists, "Clear Private Tabs button not found.")

        // Start a new private search
        mozWaitElementHittable(element: springboard.buttons["New Private Search"], timeout: 5)
        springboard.buttons["New Private Search"].tap()

        // Tap outside the alert to dismiss it
        coordinate.tap()

        // Terminate the app to start a fresh session
        app.terminate()

        // Reopen and check the Private Tab widget
        tapOnWidget(widgetType: "Private Tab")

        // Handle different UI behavior on iPad and iPhone
        if !iPad() {
            mozWaitElementHittable(element: app.buttons["CloseButton"], timeout: 10)
            app.buttons["CloseButton"].tap()
        }

        // Verify the presence of Private Mode message
        mozWaitForElementToExist(app.staticTexts["Leave no traces on this device"])

        // Verify private mode toggle is on
        let elementToAssert = iPad() ? privateModeButtonToggleiPad : privateModeButtonToggle
        XCTAssertTrue(app.buttons[elementToAssert].value as! String == "On", "Private Mode toggle is not set to 'On'.")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2769300
    func testGoToCopiedLinkWidget() {
        let copiedString = "www.mozilla.org"

        // Press Home and navigate to Today Widget Page
        XCUIDevice.shared.press(.home)
        goToTodayWidgetPage()

        // Remove Firefox Widget if it already exists
        if checkPresenceFifefoxWidget() {
            removeFirefoxWidget()
        }

        // Add Firefox Widget
        if iPad() {
            coordinate.press(forDuration: 3)
        }
        addWidget(widgetName: "Fennec")
        checkFirefoxAvailablesWidgets()

        // Add Quick Action Widget
        springboard.buttons[" Add Widget"].tap()
        springboard.swipeDown()
        springboard.buttons["Done"].tap()

        // Check available options in Quick Action Widget
        checkFirefoxWidgetOptions()

        // Tap on Edit Widget and check the available options
        springboard.buttons[editWidgetButton].tap()
        mozWaitElementHittable(element: springboard.buttons["New Search"], timeout: 3)
        springboard.buttons["New Search"].tap()

        // Ensure the Go To Copied Link option exists
        mozWaitForElementToExist(springboard.buttons[goToCopiedLink], timeout: 3)
        XCTAssertTrue(springboard.buttons[goToCopiedLink].exists, "Go To Copied Link button not found.")
        XCTAssertTrue(springboard.buttons["New Private Search"].exists, "New Private Search button not found.")
        XCTAssertTrue(springboard.buttons["Clear Private Tabs"].exists, "Clear Private Tabs button not found.")

        // Tap Go To Copied Link
        mozWaitElementHittable(element: springboard.buttons[goToCopiedLink], timeout: 3)
        springboard.buttons[goToCopiedLink].tap()

        // Tap outside the alert to close it
        coordinate.tap()

        // Copy the string to the clipboard
        UIPasteboard.general.string = copiedString
        app.terminate()

        // Reopen and interact with the Copied Link widget
        tapOnWidget(widgetType: "Copied Link")

        // Handle paste alert
        mozWaitElementHittable(element: springboard.alerts.buttons["Allow Paste"], timeout: 3)
        springboard.alerts.buttons["Allow Paste"].tap()

        // Handle iPad/iPhone UI differences
        if !iPad() {
            mozWaitElementHittable(element: app.buttons["CloseButton"], timeout: 10)
            app.buttons["CloseButton"].tap()
        }

        // Verify the copied string is in the URL field
        mozWaitForElementToExist(app.textFields["url"], timeout: 10)
        mozWaitForValueContains(app.textFields["url"], value: copiedString, timeout: 5)
        XCTAssertTrue((app.textFields["url"].value as! String).contains(copiedString),
                      "URL does not contain the copied string.")
    }
}

