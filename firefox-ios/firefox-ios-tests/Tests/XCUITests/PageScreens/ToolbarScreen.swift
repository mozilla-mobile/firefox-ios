// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class ToolbarScreen {
    private let app: XCUIApplication
    private let sel: ToolbarSelectorsSet

    init(app: XCUIApplication, selectors: ToolbarSelectorsSet = ToolbarSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var tabsButton: XCUIElement { sel.TABS_BUTTON.element(in: app) }
    private var newTabButton: XCUIElement { sel.NEW_TAB_BUTTON.element(in: app)}
    private var forwardButton: XCUIElement { sel.FORWARD_BUTTON.element(in: app)}
    private var backButton: XCUIElement { sel.BACK_BUTTON.element(in: app)}
    private var tabToolbarMenuButton: XCUIElement { sel.TABTOOLBAR_MENUBUTTON.element(in: app) }
    private var shareButton: XCUIElement { sel.SHARE_BUTTON.element(in: app) }
    private var homeButton: XCUIElement { sel.HOME_BUTTON.element(in: app) }
    private var translateButton: XCUIElement { sel.TRANSLATE_BUTTON.element(in: app) }
    private var translateLoadingButton: XCUIElement { sel.TRANSLATE_LOADING_BUTTON.element(in: app) }
    private var translateActiveButton: XCUIElement { sel.TRANSLATE_ACTIVE_BUTTON.element(in: app) }
    private var translateLanguageEnglishOption: XCUIElement { sel.TRANSLATE_LANGUAGE_ENGLISH_OPTION.element(in: app) }
    private var summarizeButton: XCUIElement { sel.SUMMARIZE_BUTTON.element(in: app) }
    private var summarizeContextualHint: XCUIElement { sel.SUMMARIZE_CONTEXTUAL_HINT.element(in: app) }
    private var googleLensTipTitle: XCUIElement { sel.GOOGLE_LENS_TIP_TITLE.element(in: app) }

    func assertSettingsButtonExists(timeout: TimeInterval = TIMEOUT) {
        let settingsButton = sel.SETTINGS_MENU_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(settingsButton, timeout: timeout)
    }

    func tapSettingsMenuButton() {
        let settingsButton = sel.SETTINGS_MENU_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(settingsButton)
        settingsButton.waitAndTap()
    }

    func assertTabsButtonExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(tabsButton)
    }

    func assertToolbarIsVisible(timeout: TimeInterval = TIMEOUT) {
        let settingsButton = sel.SETTINGS_MENU_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(settingsButton, timeout: timeout)
        XCTAssertTrue(settingsButton.isHittable, "The toolbar is not visible")
        BaseTestCase().mozWaitForElementToExist(tabsButton, timeout: timeout)
        XCTAssertTrue(tabsButton.isHittable, "The toolbar is not visible")
    }

    func pressTabsButton(duration: TimeInterval) {
        tabsButton.press(forDuration: duration)
    }

    func assertTabsOpened(expectedCount: Int) {
        BaseTestCase().mozWaitForElementToExist(tabsButton)

        guard let tabsOpen = tabsButton.value as? String, tabsOpen == "\(expectedCount)" else {
            XCTFail("Tabs button counter is not showing the correct count. Expected: \(expectedCount)")
            return
        }
    }

    func tapOnTabsButton() {
        tabsButton.waitAndTap()
    }

    func openNewTabFromTabTray() {
        tabsButton.waitAndTap()
        let newTabInTray = app.buttons[AccessibilityIdentifiers.TabTray.newTabButton]
        BaseTestCase().mozWaitForElementToExist(newTabInTray)
        newTabInTray.waitAndTap()
    }

    func assertNewTabButtonExists() {
        BaseTestCase().mozWaitForElementToExist(newTabButton)
    }

    /// Polls before failing, as the counter settles asynchronously after a tab is added or restored.
    func assertTabsButtonValue(expectedCount: String, message: String? = nil) {
        BaseTestCase().mozWaitForElementToExist(tabsButton)
        guard !tabsButtonHasValue(expectedCount) else { return }
        let actual = tabsButton.value as? String ?? "none"
        XCTFail("\(message ?? "Unexpected number of open tabs"). Expected \(expectedCount), found \(actual)")
    }

    func tabsButtonHasValue(_ expectedCount: String, timeout: TimeInterval = TIMEOUT) -> Bool {
        guard BaseTestCase().mozWaitForElementToExist(tabsButton, timeout: timeout, failOnTimeout: false)
        else { return false }
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", expectedCount),
            object: tabsButton
        )
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    func pressBackButton(duration: TimeInterval) {
        BaseTestCase().mozWaitForElementToExist(backButton)
        backButton.press(forDuration: duration)
    }

    func pressForwardButton(duration: TimeInterval) {
        let forward = sel.FORWARD_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(forward)
        forward.press(forDuration: duration)
    }

    func waitUntilBackButtonHittable(timeout: TimeInterval = 2.0) {
        BaseTestCase().mozWaitElementHittable(element: backButton, timeout: timeout)
    }

    func assertBackButtonExists() {
        BaseTestCase().mozWaitForElementToExist(backButton)
    }

	func assertForwardButtonExists() {
		BaseTestCase().mozWaitForElementToExist(forwardButton)
	}

    func tapBackButton() {
        backButton.waitAndTap()
    }

    func assertBackButtonIsDisabled() {
        XCTAssertFalse(backButton.isEnabled, "Expected Back button to be disabled")
    }

    func assertTabToolbarMenuButtonExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(tabToolbarMenuButton, timeout: timeout)
    }

    func assertMultipleTabsOpen() {
        BaseTestCase().mozWaitForElementToExist(tabsButton)
        let value = tabsButton.value as? String
        XCTAssertNotEqual(
            value,
            "1",
            "Expected several tabs to be open, but found only one."
        )
    }

    func openBrowserMenu() {
        tabToolbarMenuButton.waitAndTap()
    }

    func assertTabToolbarMenuExists() {
        BaseTestCase().mozWaitForElementToExist(tabToolbarMenuButton)
    }

    func tapReloadButton() {
        sel.RELOAD_BUTTON.element(in: app).waitAndTap()
    }

    /// Long-presses Reload and taps the first menu row (Request Desktop/Mobile Site), retrying once.
    /// Content blocker reloads swap Reload for Stop mid-press: https://github.com/mozilla-mobile/firefox-ios/issues/35933
    func toggleRequestDesktopSiteFromReloadMenu() {
        let requestDesktopSiteMenuItem = ContextMenuSelectors().REQUEST_DESKTOP_SITE.element(in: app)
        let reloadButton = sel.RELOAD_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(reloadButton)
        reloadButton.press(forDuration: 1)
        requestDesktopSiteMenuItem.waitAndTap()
    }

    func getToolbarSettingsMenuButtonElement() -> XCUIElement {
        let settingMenuButton = sel.SETTINGS_MENU_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(settingMenuButton, timeout: TIMEOUT)
        return settingMenuButton
    }

    func getTabsButtonElement() -> XCUIElement {
        BaseTestCase().mozWaitForElementToExist(tabsButton)
        return tabsButton
    }

    func getForwardButtonElement() -> XCUIElement {
        BaseTestCase().mozWaitForElementToExist(forwardButton)
        return forwardButton
    }

    func tapShareButton() {
        shareButton.waitAndTap()
    }

    func tapOnNewTabButton() {
        newTabButton.waitAndTap()
    }

    func tapHomeButton() {
        homeButton.waitAndTap()
    }

    // MARK: - Summarize Button

    /// The button appears only once the page has been checked for summarization, which happens
    /// asynchronously after load, hence the long default timeout.
    func assertSummarizeButtonExists(timeout: TimeInterval = TIMEOUT_LONG) {
        BaseTestCase().mozWaitForElementToExist(summarizeButton, timeout: timeout)
    }

    func longPressSummarizeButton() {
        BaseTestCase().mozWaitForElementToExist(summarizeButton)
        summarizeButton.press(forDuration: 1.5)
    }

    func assertSummarizeContextualHintIsDisplayed(timeout: TimeInterval = TIMEOUT_LONG) {
        BaseTestCase().mozWaitForElementToExist(summarizeContextualHint, timeout: timeout)
        XCTAssertNotNil(closeButton(nextTo: summarizeContextualHint), "The contextual hint has no \"x\" button")
    }

    /// TipKit shows this tip once per simulator, the first time the address bar is focused, and it stays
    /// up after the page loads, which keeps other contextual hints from being presented.
    /// Returns whether the tip was dismissed.
    @discardableResult
    func dismissGoogleLensTipIfPresented() -> Bool {
        guard googleLensTipTitle.mozWaitForElementToExist(timeout: TIMEOUT_PICKER_PROBE, failOnTimeout: false) else {
            return false
        }
        // The iPad popover ignores taps on its "x", so fall back to tapping outside the tip
        closeButton(nextTo: googleLensTipTitle)?.tap()
        if !BaseTestCase().mozWaitForElementToNotExist(googleLensTipTitle,
                                                       timeout: TIMEOUT_PICKER_PROBE,
                                                       failOnTimeout: false) {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5)).tap()
            BaseTestCase().mozWaitForElementToNotExist(googleLensTipTitle)
        }
        return true
    }

    /// Tapping the hint's text leaves it open, so it is closed with its "x" button.
    func closeSummarizeContextualHint() {
        BaseTestCase().mozWaitForElementToExist(summarizeContextualHint)
        closeButton(nextTo: summarizeContextualHint)?.tap()
    }

    /// iPad tabs and the address bar also have "Close" buttons, so pick the nearest one on the
    /// hint's text rows, to the right of the text.
    private func closeButton(nextTo text: XCUIElement) -> XCUIElement? {
        let textFrame = text.frame
        return sel.CONTEXTUAL_HINT_CLOSE_BUTTON.query(in: app).allElementsBoundByIndex
            .filter { button in
                let center = CGPoint(x: button.frame.midX, y: button.frame.midY)
                return center.x > textFrame.minX && (textFrame.minY...textFrame.maxY).contains(center.y)
            }
            .min { abs($0.frame.midX - textFrame.maxX) < abs($1.frame.midX - textFrame.maxX) }
    }

    func assertSummarizeContextualHintIsDismissed() {
        BaseTestCase().mozWaitForElementToNotExist(summarizeContextualHint)
    }

    // MARK: - Translate Button
    enum TranslationButtonType {
        case inactive
        case loading
        case active
    }

    func tapTranslateButton(with mode: TranslationButtonType) {
        switch mode {
        case .inactive:
            translateButton.waitAndTap()
        case .loading:
            translateLoadingButton.waitAndTap()
        case .active:
            translateActiveButton.waitAndTap()
        }
    }

    /// Selects English in the translation language picker action sheet when it is shown.
    /// The picker only appears when the language picker feature is enabled and multiple
    /// target languages are available, so this is a no-op when the sheet doesn't show.
    /// The probe is short on purpose: waiting the full TIMEOUT lets the translation finish before the
    /// caller can observe the spinner.
    func selectTranslationLanguageIfPresented(timeout: TimeInterval = TIMEOUT_PICKER_PROBE) {
        if translateLanguageEnglishOption.mozWaitForElementToExist(timeout: timeout, failOnTimeout: false) {
            translateLanguageEnglishOption.waitAndTap()
        }
    }

    /// The spinner is transient and a fast translation can pass through it between UI samples, so the
    /// active button counts too.
    func assertTranslationInProgressOrCompleted(timeout: TimeInterval = TIMEOUT) {
        guard !translateLoadingButton.mozWaitForElementToExist(timeout: timeout, failOnTimeout: false) else {
            return
        }
        BaseTestCase().mozWaitForElementToExist(translateActiveButton, timeout: timeout)
    }

    func assertTranslateButtonExists(with mode: TranslationButtonType, timeout: TimeInterval = TIMEOUT) {
        switch mode {
        case .inactive:
            BaseTestCase().mozWaitForElementToExist(translateButton, timeout: timeout)
        case .loading:
            BaseTestCase().mozWaitForElementToExist(translateLoadingButton, timeout: timeout)
        case .active:
            BaseTestCase().mozWaitForElementToExist(translateActiveButton, timeout: timeout)
        }
    }

    /// Gates on the loading spinner disappearing (translation done) before asserting the active
    /// button, since translation is network-bound and can take much longer than a normal UI wait.
    func waitForTranslateButtonToBecomeActive() {
        let base = BaseTestCase()
        base.mozWaitForElementToNotExist(translateLoadingButton, timeout: TRANSLATION_TIMEOUT)
        base.mozWaitForElementToExist(translateActiveButton)
    }

    func assertTranslateButtonDoesNotExist(with mode: TranslationButtonType) {
        switch mode {
        case .inactive:
            BaseTestCase().mozWaitForElementToNotExist(translateButton)
        case .loading:
            BaseTestCase().mozWaitForElementToNotExist(translateLoadingButton)
        case .active:
            BaseTestCase().mozWaitForElementToNotExist(translateActiveButton)
        }
    }
}
