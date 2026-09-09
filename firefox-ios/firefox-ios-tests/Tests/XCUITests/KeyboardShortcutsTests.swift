// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class KeyboardShortcutsTests: BaseTestCase {
    // Up to 2 presses have been observed being dropped, so this leaves margin on top of that
    // without masking a shortcut that only works after several presses.
    private let shortcutAttempts = 4
    private let shortcutAttemptTimeout: TimeInterval = 5
    // Samples the current state instead of waiting for a change
    private let noWait: TimeInterval = 0

    private var toolbarScreen: ToolbarScreen!
    private var homePageScreen: HomePageScreen!
    private var browserScreen: BrowserScreen!
    private var libraryScreen: LibraryScreen!
    private var tabTrayScreen: TabTrayScreen!

    override func setUp() async throws {
        // Every shortcut fails all its attempts on the iOS 16 simulator, where `typeKey` does not
        // deliver key events to the app. The same build passes on 17.5, 18.6 and 26.5.
        if #unavailable(iOS 17) {
            throw XCTSkip("typeKey does not deliver key events to the app on the iOS 16 simulator")
        }
        try await super.setUp()
        toolbarScreen = ToolbarScreen(app: app)
        homePageScreen = HomePageScreen(app: app)
        browserScreen = BrowserScreen(app: app)
        libraryScreen = LibraryScreen(app: app)
        tabTrayScreen = TabTrayScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307079
    // Regression
    func testOpenAndCloseTabWithKeyboardShortcut() {
        toolbarScreen.assertTabsButtonValue(expectedCount: "1")

        // A new tab is opened by pressing Command+T
        pressShortcut("t",
                      until: { toolbarScreen.tabsButtonHasValue("2", timeout: shortcutAttemptTimeout) },
                      failureMessage: "Command+T did not open a new tab")

        // The tab is closed by pressing Command+W
        pressShortcut("w",
                      until: { toolbarScreen.tabsButtonHasValue("1", timeout: shortcutAttemptTimeout) },
                      failureMessage: "Command+W did not close the tab")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307080
    // Regression
    func testOpenPrivateTabWithKeyboardShortcut() {
        // A new private tab is opened by pressing Command+Shift+P
        pressShortcut("p",
                      modifierFlags: [.command, .shift],
                      until: { homePageScreen.privateHomeTitleExists(timeout: shortcutAttemptTimeout) },
                      failureMessage: "Command+Shift+P did not open a private tab")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307083
    // Regression
    func testBookmarkPageWithKeyboardShortcut() {
        visitPageAndBookmarkItWithKeyboardShortcut()

        // The bookmark is saved, and saved only once even if the shortcut had to be retried
        navigator.goto(LibraryPanel_Bookmarks)
        libraryScreen.assertBookmarkExists(named: TestLabels.exampleDomain)
        libraryScreen.assertBookmarkListCount(numberOfEntries: 1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307090
    // Regression
    func testShowBookmarksPanelWithKeyboardShortcut() {
        visitPageAndBookmarkItWithKeyboardShortcut()

        // The bookmark panel is displayed by pressing Command+Shift+O
        pressShortcut("o",
                      modifierFlags: [.command, .shift],
                      until: { libraryScreen.bookmarkListExists(timeout: shortcutAttemptTimeout) },
                      failureMessage: "Command+Shift+O did not display the bookmark panel")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307092
    // Regression
    func testSwitchTabWithKeyboardShortcut() {
        openThreeTabsAndSelectTheFirstOne()

        // The next tab is selected by pressing Control+Tab. Both tab shortcuts cycle, so retrying a
        // press that landed would step past the expected tab; only a dropped press leaves this tab up.
        pressShortcut(
            XCUIKeyboardKey.tab.rawValue,
            modifierFlags: .control,
            until: { browserScreen.bookOfMozillaPageContentExists(timeout: shortcutAttemptTimeout) },
            retryOnlyWhile: { browserScreen.exampleDomainTextExists(timeout: noWait) },
            failureMessage: "Control+Tab did not select the next tab"
        )

        // The previous tab is selected by pressing Control+Shift+Tab
        pressShortcut(
            XCUIKeyboardKey.tab.rawValue,
            modifierFlags: [.control, .shift],
            until: { browserScreen.exampleDomainTextExists(timeout: shortcutAttemptTimeout) },
            retryOnlyWhile: { browserScreen.bookOfMozillaPageContentExists(timeout: noWait) },
            failureMessage: "Control+Shift+Tab did not select the previous tab"
        )
    }

    // Both shortcuts wrap around, so with fewer tabs, or starting on the last one, next and previous
    // land on the same tab and the test would pass even with the two commands swapped.
    private func openThreeTabsAndSelectTheFirstOne() {
        navigator.openURL(path(forTestPage: TestPages.exampleHTML))
        waitUntilPageLoad()
        waitForTabsButton()

        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openURL(path(forTestPage: TestPages.mozillaBook))
        waitUntilPageLoad()
        waitForTabsButton()

        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForTabsButton()

        navigator.goto(TabTray)
        tabTrayScreen.tapOnCell(named: TestLabels.exampleDomain)
        navigator.nowAt(BrowserTab)
        XCTAssertTrue(browserScreen.exampleDomainTextExists(), "The first tab was not selected")
    }

    // The simulator drops a varying number of keyboard events, so the shortcut is sent again whenever
    // nothing happened. Retries re-activate the app: keys the app never saw would just be lost again.
    private func pressShortcut(
        _ key: String,
        modifierFlags: XCUIElement.KeyModifierFlags = .command,
        until isSatisfied: () -> Bool,
        retryOnlyWhile shouldRetry: () -> Bool = { true },
        failureMessage: String
    ) {
        waitUntilAppAcceptsKeyboardShortcuts()

        for attempt in 0..<shortcutAttempts {
            if attempt > 0 { app.activate() }
            app.typeKey(key, modifierFlags: modifierFlags)
            if isSatisfied() { return }
            if !shouldRetry() {
                XCTFail("\(failureMessage), and the app moved to an unexpected state instead")
                return
            }
        }
        XCTFail("\(failureMessage) in \(shortcutAttempts) attempts")
    }

    // Key commands need the browser on screen and owning the responder chain, which setUpApp() does not
    // wait for. Best effort: a timeout is not worth failing on, the shortcut attempts report that.
    private func waitUntilAppAcceptsKeyboardShortcuts() {
        let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        let isInteractive = NSPredicate(format: "exists == true && hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: isInteractive, object: tabsButton)
        _ = XCTWaiter().wait(for: [expectation], timeout: TIMEOUT)
    }

    // Command+D only bookmarks an actual page, it is a no-op on the homepage, hence visiting one first.
    private func visitPageAndBookmarkItWithKeyboardShortcut() {
        navigator.openURL(path(forTestPage: TestPages.exampleHTML))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)

        pressShortcut("d",
                      until: { browserScreen.bookmarkSavedToastExists(timeout: shortcutAttemptTimeout) },
                      failureMessage: "Command+D did not save the page")
    }
}
