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
// TODO FXIOS-12604 These global properties are not concurrency safe
@MainActor
var goToCopiedLink = springboard.buttons["Go to Copied Link"]
@MainActor
var newPrivateSearch = springboard.buttons["New Private Search"]
@MainActor
var newSearch = springboard.buttons["New Search"]
@MainActor
var clearPrivateTabs = springboard.buttons["Clear Private Tabs"]

// Widget coordinates
@MainActor
let normalized = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))

// Get the screen size
@MainActor
let screenSize = springboard.windows.element(boundBy: 0).frame.size

// Calculate the center-right coordinate (x: right edge, y: middle of the screen)
@MainActor
let centerRightX = screenSize.width * 0.95  // Adjust this value if you want slightly away from the edge
@MainActor
let centerRightY = screenSize.height / 2

// Create the coordinate using the calculated points
@MainActor
let coordinate = springboard.coordinate(withNormalizedOffset: CGVector(
    dx: centerRightX / screenSize.width, dy: centerRightY / screenSize.height))

// Functions
enum SwipeDirection {
    case swipeUp
    case swipeRight
}

@MainActor
private func widgetExist() -> Bool {
    let firefoxWidgetButton = springboard
        .buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Firefox")).element.exists
    let firefoxWidgetSecureSearchButton = springboard
        .buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Private Tab")).element.exists
    let firefoxCopiedLinkWidget = springboard.buttons
        .matching(NSPredicate(format: "label CONTAINS[c] %@", "Copied Link")).element.exists
    return firefoxWidgetButton || firefoxWidgetSecureSearchButton || firefoxCopiedLinkWidget
}

@MainActor
private func goToTodayWidgetPage() {
    // Swipe right until the "Screen Time" icon appears

    if #available(iOS 26, *) {
        springboard.swipeRight()
        springboard.swipeRight()
    } else if #unavailable(iOS 16) {
        while !springboard.textFields["SpotlightSearchField"].exists {
            springboard.swipeRight()
        }
    } else {
        while !springboard.icons["Screen Time"].exists {
            springboard.swipeRight()
        }
    }
}

@MainActor
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

@MainActor
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

@MainActor
private func skipOnboardingIfNeeded(app: XCUIApplication) {
    // Tapping a widget cold-starts the production app (not the UI-test app delegate), so the
    // SkipIntro launch argument never runs and the full production onboarding (Terms of Service
    // + tour) appears. Reuse the OnboardingScreen page object: handleTermsOfService() taps the
    // ToS primary button and re-taps if the cross-dissolve transition absorbed the first tap
    // (a single tap is what makes these tests flake), then closeTour() dismisses the tour.
    guard app.buttons["Continue"].mozWaitForElementToExist(timeout: TIMEOUT, failOnTimeout: false) else {
        return
    }
    let onboardingScreen = OnboardingScreen(app: app, flowType: .modernKit)
    onboardingScreen.handleTermsOfService()
    onboardingScreen.closeTour()
}

// swiftlint:disable:next type_body_length
class TodayWidgetTests: BaseTestCase {
    private var tabTray: TabTrayScreen!
    private var toolbarScreen: ToolbarScreen!
    private var browserScreen: BrowserScreen!

    override func setUp() async throws {
        try await super.setUp()
        if !isFennec {
            throw XCTSkip("Skipping TodayWidgetTests on Firefox or FirefoxBeta schemas")
        }
        tabTray = TabTrayScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)
        browserScreen = BrowserScreen(app: app)
    }

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

    private func removeWidgetIfExists(widgetType: String) {
        if checkPresenceFirefoxWidget() {
            removeFirefoxWidget()
        }
    }

    /// Opens the widget gallery on a clean Today page and checks the Firefox widgets it offers.
    private func openFirefoxWidgetGallery(iPadPressDuration: Double = 3) {
        goToTodayWidgetPage()
        removeWidgetIfExists(widgetType: "Firefox")
        if iPad() {
            coordinate.press(forDuration: iPadPressDuration)
        }
        addWidget(widgetName: "Fennec")
        checkFirefoxAvailablesWidgets()
    }

    private func confirmWidgetSelection() {
        springboard.buttons[" Add Widget"].waitAndTap()
        springboard.swipeDown()
        springboard.buttons["Done"].waitAndTap()
    }

    private func addQuickActionsWidget() {
        openFirefoxWidgetGallery()
        confirmWidgetSelection()
    }

    private func addFirefoxShortcutsWidget(iPadPressDuration: Double = 3) {
        openFirefoxWidgetGallery(iPadPressDuration: iPadPressDuration)
        springboard.swipeLeft()
        mozWaitForElementToExist(springboard.staticTexts["Firefox Shortcuts"])
        confirmWidgetSelection()
        checkFirefoxShortcutsOptions()
    }

    /// Opens the Quick Actions action picker and checks the options it lists.
    private func openQuickActionsPicker() {
        checkFirefoxWidgetOptions()
        springboard.buttons[editWidgetButton].waitAndTap()
        mozWaitElementHittable(element: newSearch, timeout: TIMEOUT)
        newSearch.waitAndTap()
        if #unavailable(iOS 17) {
            goToCopiedLink = springboard.staticTexts["Go to Copied Link"]
            newPrivateSearch = springboard.staticTexts["New Private Search"]
            newSearch = springboard.staticTexts["New Search"]
            clearPrivateTabs = springboard.staticTexts["Clear Private Tabs"]
        }
        mozWaitForElementToExist(goToCopiedLink, timeout: TIMEOUT)
        XCTAssertTrue(goToCopiedLink.exists, "Go to Copied Link button not found.")
        XCTAssertTrue(newPrivateSearch.exists, "New Private Search button not found.")
        XCTAssertTrue(clearPrivateTabs.exists, "Clear Private Tabs button not found.")
    }

    /// Picks an action in the Quick Actions picker, then taps outside to close the edit sheet.
    private func selectQuickAction(_ action: XCUIElement) {
        mozWaitElementHittable(element: action, timeout: TIMEOUT)
        action.waitAndTap()
        mozWaitForElementToExist(action)
        coordinate.tap()
    }

    private func openPrivateTabs(urls: [String]) {
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        for url in urls {
            navigator.createNewTab()
            navigator.openURL(url)
            waitUntilPageLoad()
        }
    }

    /// Backgrounds the app without terminating it, so the in-memory private tabs survive.
    private func sendAppToBackground() {
        XCUIDevice.shared.press(.home)
        let isInBackground = app.wait(for: .runningBackground, timeout: TIMEOUT)
            || app.state == .runningBackgroundSuspended
        XCTAssertTrue(isInBackground, "The app must stay alive in the background, state: \(app.state.rawValue)")
    }

    private func handleAllowPasteIfPresent() {
        // The paste alert can take a while to surface after the widget launches the app, so wait
        // the longer timeout before giving up rather than moving on and leaving it undismissed.
        let allowPaste = springboard.alerts.buttons["Allow Paste"]
        if allowPaste.mozWaitForElementToExist(timeout: TIMEOUT_LONG, failOnTimeout: false) {
            mozWaitElementHittable(element: allowPaste, timeout: TIMEOUT)
            allowPaste.waitAndTap()
        }
    }

    /// Verifies a copied-link widget opens the copied URL. The first widget launch cold-starts the
    /// production app, which shows onboarding and drops the deep link, leaving the app on an empty
    /// new tab. Dismissing onboarding persists `IntroSeen`, so relaunching from the widget skips
    /// onboarding and honors the deep link.
    private func openCopiedLinkAndVerify(copiedString: String, widgetLabel: String) {
        // First launch: clear the paste alert and complete onboarding so `IntroSeen` is persisted.
        handleAllowPasteIfPresent()
        skipOnboardingIfNeeded(app: app)
        // Relaunch from the widget; with onboarding gone the deep link is honored.
        UIPasteboard.general.string = copiedString
        app.terminate()
        goToTodayWidgetPage()
        tapOnWidget(widgetType: widgetLabel)
        handleAllowPasteIfPresent()
        skipOnboardingIfNeeded(app: app)
        // Verify the copied string is in the URL field
        mozWaitForElementToExist(urlBarAddress, timeout: TIMEOUT)
        mozWaitForValueContains(urlBarAddress, value: copiedString, timeout: TIMEOUT)
        guard let urlField = urlBarAddress.value as? String else {
            XCTFail("Expected value to be a String but found \(type(of: urlBarAddress.value))")
            return
        }
        XCTAssertTrue(urlField.contains(copiedString), "URL does not contain the copied string.")
    }

    // TESTS
    // https://mozilla.testrail.io/index.php?/cases/view/2769289
    // Regression
    func testNewSearchWidget() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("iOS 16 is required")
        }
        app.terminate()
        addQuickActionsWidget()
        openQuickActionsPicker()
        selectQuickAction(newSearch)
        // Check New Search action
        tapOnWidget(widgetType: "Firefox")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2769297
    // Regression
    func testNewPrivateSearchWidget() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("iOS 16 is required")
        }
        app.terminate()
        addQuickActionsWidget()
        openQuickActionsPicker()
        selectQuickAction(newPrivateSearch)
        tapOnWidget(widgetType: "Private Tab")
        skipOnboardingIfNeeded(app: app)
        // Verify the presence of Private Mode message
        mozWaitForElementToExist(app.staticTexts["Leave no traces on this device"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2769300
    func testGoToCopiedLinkWidget() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("iOS 16 is required")
        }
        let copiedString = "mozilla.org"
        app.terminate()
        addQuickActionsWidget()
        openQuickActionsPicker()
        selectQuickAction(goToCopiedLink)
        // Copy the string to the clipboard
        UIPasteboard.general.string = copiedString
        tapOnWidget(widgetType: "Copied Link")
        openCopiedLinkAndVerify(copiedString: copiedString, widgetLabel: "Copied Link")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2769301
    // Regression
    func testClosePrivateTabsWidget() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("iOS 16 is required")
        }
        let privateTabURLs = [
            path(forTestPage: TestPages.mozillaOrg),
            path(forTestPage: TestPages.mozillaBook),
            path(forTestPage: TestPages.findInPage)
        ]
        // A normal tab gives the widget a session to return to
        navigator.openURL(path(forTestPage: TestPages.exampleHTML))
        waitUntilPageLoad()
        openPrivateTabs(urls: privateTabURLs)
        toolbarScreen.assertTabsButtonValue(expectedCount: "\(privateTabURLs.count)")
        // Terminating would drop the unsaved private tabs and make the check vacuous
        sendAppToBackground()
        addQuickActionsWidget()
        openQuickActionsPicker()
        selectQuickAction(clearPrivateTabs)
        // A cold launch would restore only the normal tab and pass without clearing anything
        XCTAssertNotEqual(app.state, .notRunning, "The app was terminated in the background")
        tapOnWidget(widgetType: "Private Tabs")
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: TIMEOUT), "The widget did not bring the app back")
        // Back on the normal session, with no private tabs left
        browserScreen.assertExampleDomainTextExists()
        toolbarScreen.assertTabsButtonValue(expectedCount: "1")
        toolbarScreen.tapOnTabsButton()
        tabTray.switchToPrivateBrowsing()
        tabTray.waitForEmptyPrivateModeOpened()
        tabTray.assertNoPrivateTabs()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2783001
    func testFxShortcutSearchWidget() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("iOS 16 is required")
        }
        app.terminate()
        addFirefoxShortcutsWidget()
        springboard.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Firefox")).element.waitAndTap()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2783002
    func testFxShortcutPrivateSearchWidget() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("iOS 16 is required")
        }
        app.terminate()
        addFirefoxShortcutsWidget()
        mozWaitElementHittable(element: springboard.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Private Tab")
        ).element.firstMatch, timeout: TIMEOUT)
        springboard.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] %@", "Private Tab")
        ).element.firstMatch.waitAndTap()
        skipOnboardingIfNeeded(app: app)
        // Verify the presence of Private Mode message
        mozWaitForElementToExist(app.staticTexts["Leave no traces on this device"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2783003
    // Regression
    func testFxShortcutGoToCopiedLinkWidget() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("iOS 16 is required")
        }
        let copiedString = "mozilla.org"
        UIPasteboard.general.string = copiedString
        app.terminate()

        _ = app.wait(for: .notRunning, timeout: TIMEOUT)

        addFirefoxShortcutsWidget(iPadPressDuration: 5)
        tapOnWidget(widgetType: "Copied Link")
        openCopiedLinkAndVerify(copiedString: copiedString, widgetLabel: "Copied Link")
    }
}
