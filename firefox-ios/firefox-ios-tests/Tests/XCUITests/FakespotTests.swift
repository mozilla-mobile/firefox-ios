// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import XCTest

class FakespotTests: BaseTestCase {
    override func tearDown() {
        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        super.tearDown()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307128
    func testFakespotAvailable() {
        reachReviewChecker()
        mozWaitForElementToExist(app.staticTexts[AccessibilityIdentifiers.Shopping.sheetHeaderTitle])
        XCTAssertEqual(app.staticTexts[AccessibilityIdentifiers.Shopping.sheetHeaderTitle].label, "Review Checker")

        // Close the popover
        app.otherElements.buttons[AccessibilityIdentifiers.Shopping.sheetCloseButton].tap()
        mozWaitForElementToNotExist(app.otherElements[AccessibilityIdentifiers.Shopping.sheetHeaderTitle])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2358865
    func testReviewQualityCheckBottomSheetUI() {
        reachReviewChecker()
        app.buttons[AccessibilityIdentifiers.Shopping.OptInCard.mainButton].waitAndTap()
        validateReviewQualityCheckSheet()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2358866
    func testReviewQualityCheckBottomSheetUILandscape() throws {
        if iPad() {
            throw XCTSkip("iPhone only test")
        } else {
            // Change the device orientation to be landscape
            XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
            reachReviewChecker()
            app.buttons[AccessibilityIdentifiers.Shopping.OptInCard.mainButton].waitAndTap()
            validateReviewQualityCheckSheet()
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2358902
    // Smoketest
    func testPriceTagIconAvailableOnlyOnDetailPage() {
        // Search for a product but do not open the product detail page
        loadWebsiteAndPerformSearch()

        // The Price tag icon is NOT displayed on the address bar of the search result page
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.Toolbar.shoppingButton])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2358904
    // Smoketest
    func testPriceTagNotDisplayedInPrivateMode() {
        // Open a product detail page using a private tab and check the address bar
        loadWebsiteInPrivateMode()

        // The Price tag icon is NOT displayed
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.Toolbar.shoppingButton])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2358924
    func testAcceptTheRejectedOptInNotification() {
        reachReviewChecker()
        mozWaitForElementToExist(app.staticTexts[AccessibilityIdentifiers.Shopping.sheetHeaderTitle])
        XCTAssertEqual(app.staticTexts[AccessibilityIdentifiers.Shopping.sheetHeaderTitle].label, "Review Checker")

        // Reject the Opt-in notification
        app.otherElements.buttons[AccessibilityIdentifiers.Shopping.sheetCloseButton].tap()
        // The sheet is dismissed and the user remains opted-out
        mozWaitForElementToNotExist(app.otherElements[AccessibilityIdentifiers.Shopping.sheetHeaderTitle])
        // Tap the Price tag icon again
        app.buttons[AccessibilityIdentifiers.Toolbar.shoppingButton].tap()
        // The contextual onboarding screen is displayed
        mozWaitForElementToExist(app.staticTexts[AccessibilityIdentifiers.Shopping.sheetHeaderTitle])
        XCTAssertEqual(app.staticTexts[AccessibilityIdentifiers.Shopping.sheetHeaderTitle].label, "Review Checker")
        // Tap the "Yes, Try it" button
        app.buttons[AccessibilityIdentifiers.Shopping.OptInCard.mainButton].waitAndTap()
        // The sheet is populated with product feedback data
        mozWaitForElementToExist(app.staticTexts[AccessibilityIdentifiers.Shopping.sheetHeaderTitle])
        XCTAssertEqual(app.staticTexts[AccessibilityIdentifiers.Shopping.sheetHeaderTitle].label, "Review Checker")
        XCTAssertEqual(app.buttons[AccessibilityIdentifiers.Shopping.sheetCloseButton].label, "Close Review Checker")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2358901
    func testPriceTagNotDisplayedOnSitesNotIntegratedFakespot() {
        // Navigate to ebay.com
        navigator.openURL("https://www.ebay.com")
        waitUntilPageLoad()
        // The price tag icon is not displayed
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.Toolbar.shoppingButton])
        if #available(iOS 17, *) {
            // Open a product detail page and check the address bar
            let searchField = app.webViews["contentView"].webViews.textFields["Search for anything"]
            searchField.waitAndTap()
            searchField.typeText("Shoe")
            app.webViews["contentView"].webViews.buttons["Search"].waitAndTap()
            waitUntilPageLoad()
            app.webViews["contentView"].links.element(boundBy: 7).tap()
            waitUntilPageLoad()
            // The price tag icon is not displayed
            mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.Toolbar.shoppingButton])
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2358863
    func testSettingsSectionUI() {
        // Navigate to a product detail page
        reachReviewChecker()
        app.buttons[AccessibilityIdentifiers.Shopping.OptInCard.mainButton].waitAndTap()
        // Check the 'Settings' collapsible section
        let settingsSection = app.staticTexts[AccessibilityIdentifiers.Shopping.SettingsCard.title]
        let expandButton = app.buttons[AccessibilityIdentifiers.Shopping.SettingsCard.expandButton]
        mozWaitForElementToExist(settingsSection)
        mozWaitForElementToExist(expandButton)
        // Tap to open the section
        expandButton.tap()
        mozWaitForElementToExist(settingsSection)
        // Validate expanded settings section
        validateExpandedSettingsSection()
        // Switch the theme from light to dark mode
        switchThemeToDarkOrLight()
        mozWaitForElementToExist(settingsSection)
        // Validate expanded settings section
        validateExpandedSettingsSection()
        // Switch the theme from light to dark mode
        switchThemeToDarkOrLight()
        // Validate expanded settings section
        validateExpandedSettingsSection()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2358892
    func testOptInNotificationLayout() {
        // Navigate to a product detail page on amazon.com page
        reachReviewChecker()
        validateOptInLayout("Amazon", "Walmart", "Best Buy")

        // Navigate to a product detail page on walmart.com page
        validateLayoutOnWalmartAndBestBuy("https://www.walmart.com", isWalmart: true, "Walmart", "Amazon", "Best Buy")

        // Navigate to a product detail page on bestbuy.com page
        validateLayoutOnWalmartAndBestBuy("https://www.bestbuy.com", isWalmart: false, "Best Buy", "Amazon", "Walmart")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2358878
    func testLearnMoreAboutFakespotHyperlink() {
        // Navigate to a product detail page
        reachReviewChecker()
        app.buttons[AccessibilityIdentifiers.Shopping.OptInCard.mainButton].waitAndTap()
        // Expand the "How we determine review quality" section
        app.staticTexts[AccessibilityIdentifiers.Shopping.ReviewQualityCard.title].waitAndTap()
        // Tap the "Learn more about how Fakespot determines review quality" hyperlink
        let linkText = "Learn more about how Fakespot determines review quality"
        let learnMoreLink = app.scrollViews.otherElements.staticTexts[linkText]
        mozWaitForElementToExist(learnMoreLink)
        scrollToElement(learnMoreLink)
        learnMoreLink.tap()
        // The link opens in a new tab
        waitUntilPageLoad()
        validateMozillaSupportWebpage("Review Checker for Firefox Mobile", "support.mozilla.org")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2358864
    func testTurnOffAndOnTheReviewQualityCheck() {
        // Navigate to a product detail page
        reachReviewChecker()
        app.buttons[AccessibilityIdentifiers.Shopping.OptInCard.mainButton].waitAndTap()
        // Navigate to the 'Settings' section and tap the "turn off review quality check" button
        let shoppingIdentifier = AccessibilityIdentifiers.Shopping.SettingsCard.self
        app.buttons[shoppingIdentifier.expandButton].waitAndTap()
        app.buttons[shoppingIdentifier.turnOffButton].waitAndTap()
        // The 'Review quality check' bottom sheet/sidebar closes
        mozWaitForElementToNotExist(app.staticTexts[AccessibilityIdentifiers.Shopping.sheetHeaderTitle])
        mozWaitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url], value: "www.amazon.com")
        // In a new tab, navigate to a product detail page on amazon.com
        navigator.performAction(Action.OpenNewTabFromTabTray)
        reachReviewChecker()
        // Opt-in card is displayed
        mozWaitForElementToExist(app.staticTexts[AccessibilityIdentifiers.Shopping.sheetHeaderTitle])
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Shopping.OptInCard.mainButton])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2358894
    func testLearnMoreLink() {
        // Navigate to a product detail page
        reachReviewChecker()
        // Tap Learn more link
        let learnMoreLink = app.scrollViews.otherElements.staticTexts["Learn more"]
        learnMoreLink.waitAndTap()
        // The link opens in a new tab
        waitUntilPageLoad()
        validateMozillaSupportWebpage("Review Checker for Firefox Mobile", "support.mozilla.org")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2358896
    func testTermsOfUseLink() {
        // Navigate to a product detail page
        reachReviewChecker()
        // Tap Terms of use link
        let termsOfUseLink = app.scrollViews.otherElements.staticTexts["Fakespot’s terms of use"]
        termsOfUseLink.waitAndTap()
        // The link opens in a new tab
        waitUntilPageLoad()
        validateMozillaSupportWebpage("Fakespot Terms of Use", "www.fakespot.com")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2358895
    func testPrivacyPolicyLink() {
        // Navigate to a product detail page
        reachReviewChecker()
        // Tap privacy policy link
        let privacyPolicyLink = app.scrollViews.otherElements.staticTexts["Firefox’s privacy notice"]
        privacyPolicyLink.waitAndTap()
        // The link opens in a new tab
        waitUntilPageLoad()
        validateMozillaSupportWebpage("Privacy Notice", "privacy/firefox")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2358929
    func testPriceTagIconAndReviewCheckLandscape() {
        // Change the device orientation to be landscape
        XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
        // Navigate for the first time to a product detail page on amazon.com
        loadWebsiteAndPerformSearch()
        app.webViews["contentView"].firstMatch.images.firstMatch.tap()
        waitUntilPageLoad()
        // The Price tag icon is correctly displayed
        if !app.buttons[AccessibilityIdentifiers.Toolbar.shoppingButton].exists {
            app.webViews["contentView"].firstMatch.images.firstMatch.tap()
            waitUntilPageLoad()
        }
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.shoppingButton])
    }

    private func validateReviewQualityCheckSheet() {
        mozWaitForElementToExist(app.staticTexts[AccessibilityIdentifiers.Shopping.sheetHeaderTitle])
        XCTAssertEqual(app.staticTexts[AccessibilityIdentifiers.Shopping.sheetHeaderTitle].label, "Review Checker")
        XCTAssertEqual(app.buttons[AccessibilityIdentifiers.Shopping.sheetCloseButton].label, "Close Review Checker")
        if app.staticTexts["How reliable are these reviews?"].exists {
            XCTAssertEqual(app.staticTexts[AccessibilityIdentifiers.Shopping.ReliabilityCard.title].firstMatch.label,
                           "How reliable are these reviews?")
            mozWaitForElementToExist(app.staticTexts["Adjusted rating"])
            validateHighlightsSection()
        } else {
            mozWaitForElementToExist(app.staticTexts["No info about these reviews yet"])
            mozWaitForElementToExist(app.buttons["Check Review Quality"])
        }
        mozWaitForElementToExist(app.staticTexts[AccessibilityIdentifiers.Shopping.ReviewQualityCard.title])
        XCTAssertEqual(app.staticTexts[AccessibilityIdentifiers.Shopping.ReviewQualityCard.title].label,
                       "How we determine review quality")
        XCTAssertEqual(app.staticTexts[AccessibilityIdentifiers.Shopping.SettingsCard.title].label, "Settings")
        XCTAssertTrue(app.staticTexts["Review Checker is powered by Fakespot by Mozilla"].exists)
    }

    private func validateMozillaSupportWebpage(_ webpageTitle: String, _ url: String) {
        mozWaitForElementToExist(app.staticTexts[webpageTitle])
        mozWaitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url], value: url)
        let numTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual(numTab, "2")
    }

    private func validateLayoutOnWalmartAndBestBuy(_ website: String, isWalmart: Bool, _ currentWebsite: String,
                                                   _ suggestedWebsite1: String, _ suggestedWebsite2: String) {
        app.otherElements.buttons[AccessibilityIdentifiers.Shopping.sheetCloseButton].tap()
        mozWaitForElementToNotExist(app.otherElements[AccessibilityIdentifiers.Shopping.sheetHeaderTitle])
        navigator.openURL(website)
        waitUntilPageLoad()
        if isWalmart {
            let searchWalmart = app.webViews["contentView"].searchFields["Search Walmart"]
            searchWalmart.waitAndTap()
            searchWalmart.typeText("shoe")
            app.webViews["contentView"].buttons["Search icon"].waitAndTap()
            waitUntilPageLoad()
            scrollToElement(app.links.element(boundBy: 5))
            app.links.element(boundBy: 5).tap()
        } else {
            if app.links["United States"].exists {
                app.links["United States"].tap()
                waitUntilPageLoad()
            }
            var searchBestBuy: XCUIElement
            if !iPad() {
                searchBestBuy = app.webViews["contentView"].textFields["Search"]
            } else {
                let searchText = "Type to search. Navigate forward to hear suggestions"
                searchBestBuy = app.webViews["contentView"].textFields[searchText]
            }
            searchBestBuy.waitAndTap()
            searchBestBuy.typeText("macbook air")
            app.webViews["contentView"].buttons["submit search"].waitAndTap()
            waitUntilPageLoad()
            scrollToElement(app.webViews["contentView"].links.elementContainingText("Apple").firstMatch)
            app.webViews["contentView"].links.elementContainingText("Apple").firstMatch.tap()
        }
        waitUntilPageLoad()
        app.buttons[AccessibilityIdentifiers.Toolbar.shoppingButton].tap()
        validateOptInLayout(currentWebsite, suggestedWebsite1, suggestedWebsite2)
    }

    private func validateOptInLayout(_ currentWebsite: String, _ suggestedWebsite1: String, _ suggestedWebsite2: String) {
        let optInCard = AccessibilityIdentifiers.Shopping.OptInCard.self
        let optInQueryStaticText = app.scrollViews.otherElements.staticTexts
        let optInQueryButton = app.scrollViews.otherElements.buttons
        let optInText1 = "See how reliable product reviews are on \(currentWebsite) before you buy."
        let optInText2 = "Review Checker, an experimental feature from Firefox, is built right into the browser."
        let optInText3 = "It works on \(suggestedWebsite1) and \(suggestedWebsite2), too."
        let firstParagraph = optInText1 + " " + optInText2 + " " + optInText3
        let optInText4 = "Using the power of Fakespot by Mozilla, we help you avoid biased and inauthentic reviews."
        let optInText5 = "Our AI model is always improving to protect you as you shop."
        let secondParagraph = optInText4 + " " + optInText5
        let disclaimerText = "By selecting “Yes, Try It” you agree to these items:"
        // Validate screen layout
        mozWaitForElementToExist(app.staticTexts[optInCard.headerTitle])
        XCTAssertEqual(optInQueryStaticText[optInCard.headerTitle].label, "Try our trusted guide to product reviews")
        XCTAssertTrue(optInQueryStaticText.elementContainingText(firstParagraph).exists)
        XCTAssertTrue(optInQueryStaticText.elementContainingText(secondParagraph).exists)
        XCTAssertEqual(optInQueryStaticText[optInCard.disclaimerText].label, disclaimerText)
        XCTAssertEqual(optInQueryButton[optInCard.learnMoreButton].label, "Learn more")
        XCTAssertEqual(optInQueryButton[optInCard.mainButton].label, "Yes, Try It")
        XCTAssertEqual(optInQueryButton[optInCard.secondaryButton].label, "Not now")
        XCTAssertEqual(optInQueryButton[optInCard.privacyPolicyButton].label, "Firefox’s privacy notice")
        XCTAssertEqual(optInQueryButton[optInCard.termsOfUseButton].label, "Fakespot’s terms of use")
    }

    private func switchThemeToDarkOrLight() {
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        navigator.nowAt(BrowserTab)
        navigator.goto(SettingsScreen)
        navigator.goto(DisplaySettings)
        mozWaitForElementToExist(app.switches["SystemThemeSwitchValue"])
        navigator.performAction(Action.SystemThemeSwitch)
        if app.switches["SystemThemeSwitchValue"].value! as! String == "0" {
            mozWaitForElementToExist(app.cells.staticTexts["Dark"])
            if app.cells.element(boundBy: 3).isSelected {
                app.cells.staticTexts["Dark"].tap()
            } else {
                app.cells.staticTexts["Light"].tap()
            }
        }
        app.buttons["Settings"].tap()
        navigator.nowAt(SettingsScreen)
        waitForExistence(app.buttons["Done"])
        app.buttons["Done"].tap()
        app.buttons[AccessibilityIdentifiers.Toolbar.shoppingButton].tap()
        scrollToElement(app.staticTexts[AccessibilityIdentifiers.Shopping.SettingsCard.title])
    }

    private func validateExpandedSettingsSection() {
        let shoppingIdentifier = AccessibilityIdentifiers.Shopping.SettingsCard.self
        XCTAssertEqual(app.buttons[shoppingIdentifier.expandButton].label, "Collapse Settings Card")
        XCTAssertEqual(app.buttons[shoppingIdentifier.turnOffButton].label, "Turn Off Review Checker")
        app.otherElements.buttons[AccessibilityIdentifiers.Shopping.sheetCloseButton].tap()
    }

    private func validateHighlightsSection() {
        if app.staticTexts[AccessibilityIdentifiers.Shopping.HighlightsCard.title].exists {
            let highlights = AccessibilityIdentifiers.Shopping.HighlightsCard.self
            XCTAssertEqual(app.staticTexts[highlights.title].label, "Highlights from recent reviews")
            if app.staticTexts["Show More"].exists {
                app.staticTexts["Show More"].tap()
                let isVisible = true
                switch isVisible {
                case app.staticTexts[highlights.groupPriceTitle].exists:
                    XCTAssertEqual(app.staticTexts[highlights.groupPriceTitle].label, "Price")
                case app.staticTexts[highlights.groupQualityTitle].exists:
                    XCTAssertEqual(app.staticTexts[highlights.groupQualityTitle].label, "Quality")
                case app.staticTexts[highlights.groupShippingTitle].exists:
                    XCTAssertEqual(app.staticTexts[highlights.groupQualityTitle].label, "Shipping")
                case app.staticTexts[highlights.groupPackagingTitle].exists:
                    XCTAssertEqual(app.staticTexts[highlights.groupQualityTitle].label, "Packaging")
                case app.staticTexts[highlights.groupCompetitivenessTitle].exists:
                    XCTAssertEqual(app.staticTexts[highlights.groupQualityTitle].label, "Competitiveness")
                default:
                    break
                }
                scrollToElement(app.staticTexts["Show Less"])
                app.staticTexts["Show Less"].tap()
            } else {
                XCTAssertTrue(app.staticTexts["Show Less"].exists)
                scrollToElement(app.staticTexts["Review Checker is powered by Fakespot by Mozilla"])
            }
        }
    }

    private func reachReviewChecker() {
        loadWebsiteAndPerformSearch()
        app.swipeDown()
        if app.buttons["DONE"].exists {
            app.buttons["DONE"].tap()
        }
        app.webViews["contentView"].firstMatch.images.firstMatch.tap()
        waitUntilPageLoad()
        if !app.buttons[AccessibilityIdentifiers.Toolbar.shoppingButton].exists {
            app.webViews["contentView"].firstMatch.images.firstMatch.tap()
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.shoppingButton])
        }

        // Retry loading the page if page is not loading
        while app.webViews.staticTexts["Enter the characters you see below"].exists {
            app.buttons["Reload page"].tap()
            waitUntilPageLoad()
        }
        // Tap the shopping cart icon
        let shoppingButton = app.buttons[AccessibilityIdentifiers.Toolbar.shoppingButton]
        var nrOfRetries = 4
        while !shoppingButton.exists && nrOfRetries > 0 {
            app.buttons["Reload page"].tap()
            waitUntilPageLoad()
            app.swipeDown()
            app.webViews["contentView"].firstMatch.images.firstMatch.tap(force: true)
            nrOfRetries -= 1
        }
        shoppingButton.tap()
    }

    private func loadWebsiteAndPerformSearch() {
        navigator.openURL("https://www.amazon.com")
        waitUntilPageLoad()
        let website = app.webViews["contentView"].firstMatch

        // Search for and open a shoe listing
        let searchAmazon = website.textFields["Search Amazon"]
        var nrOfRetries = 10
        if !searchAmazon.exists && nrOfRetries > 0 {
            navigator.openURL("https://www.amazon.com")
            waitUntilPageLoad()
            nrOfRetries -= 1
        }
        mozWaitForElementToExist(searchAmazon)
        XCTAssert(searchAmazon.isEnabled)
        searchAmazon.tap()
        if !app.keyboards.element.isHittable {
            searchAmazon.tap()
        }
        searchAmazon.typeText("can opener")
        website.buttons["Go"].tap()
        waitUntilPageLoad()
        while website.links.elementContainingText("Sorry! Something went wrong on our end.").exists {
            app.buttons["Reload page"].tap()
            waitUntilPageLoad()
        }
    }

    private func loadWebsiteInPrivateMode() {
        navigator.nowAt(NewTabScreen)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openURL("https://www.amazon.com")
        waitUntilPageLoad()
        let website = app.webViews["contentView"].firstMatch
        let searchAmazon = website.textFields["Search Amazon"]
        var nrOfRetries = 10
        while !searchAmazon.exists && nrOfRetries > 0 {
            app.buttons["Reload page"].tap()
            waitUntilPageLoad()
            nrOfRetries -= 1
        }
        searchAmazon.waitAndTap()
        if !app.keyboards.element.isHittable {
            searchAmazon.tap()
        }
        searchAmazon.typeText("Shoe")
        website.buttons["Go"].tap()
        waitUntilPageLoad()
        app.webViews["contentView"].firstMatch.images.firstMatch.tap()
        waitUntilPageLoad()
    }
}
