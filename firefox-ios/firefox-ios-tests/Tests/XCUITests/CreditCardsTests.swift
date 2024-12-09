// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class CreditCardsTests: BaseTestCase {
    let creditCardsStaticTexts = AccessibilityIdentifiers.Settings.CreditCards.self
    let useSavedCard = AccessibilityIdentifiers.Browser.KeyboardAccessory.creditCardAutofillButton.self
    let manageCards = AccessibilityIdentifiers.RememberCreditCard.manageCardsButton.self
    let cards = ["2720994326581252", "4111111111111111", "5346755600299631"]
    var nameOnCard: XCUIElement!
    var cardNr: XCUIElement!
    var expiration: XCUIElement!

    func initCardFields() {
        nameOnCard = app.buttons["name"]
        cardNr = app.buttons["number"]
        expiration = app.buttons["expiration"]
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306967
    // SmokeTest
    func testAccessingTheCreditCardsSection() {
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        // Autofill Credit cards section displays
        let addCardButton = app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard]
        waitForElementsToExist(
            [
                addCardButton,
                app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards],
                app.switches[creditCardsStaticTexts.AutoFillCreditCard.saveAutofillCards]
            ]
        )
        addCardButton.waitAndTap()
        // Add Credit Card page is displayed
        waitForElementsToExist(
            [
                app.staticTexts[creditCardsStaticTexts.AddCreditCard.addCreditCard],
                app.staticTexts[creditCardsStaticTexts.AddCreditCard.nameOnCard],
                app.staticTexts[creditCardsStaticTexts.AddCreditCard.cardNumber],
                app.staticTexts[creditCardsStaticTexts.AddCreditCard.expiration],
                app.buttons[creditCardsStaticTexts.AddCreditCard.close],
                app.buttons[creditCardsStaticTexts.AddCreditCard.save]
            ]
        )
        // Add, and save a valid credit card
        addCreditCard(name: "Test", cardNumber: cards[0], expirationDate: "0540")
        waitForElementsToExist(
            [
                app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.savedCards],
                app.staticTexts.containingText(
                    "New"
                ).element,
                app.tables.cells.element(
                    boundBy: 1
                ).buttons.elementContainingText(
                    "1252"
                )
            ]
        )
        let cardDetails = ["Test", "Expires", "5/40"]
        for index in cardDetails {
            mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons[index])
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306978
    // SmokeTest
    func testDeleteButtonFromEditCard() {
        addCardAndReachViewCardPage()
        // Tap on the "Remove card" button
        app.buttons[creditCardsStaticTexts.ViewCreditCard.edit].tap()
        app.buttons[creditCardsStaticTexts.EditCreditCard.removeCard].waitAndTap()
        // Validate the pop up displayed
        let removeThisCardAlert = app.alerts[creditCardsStaticTexts.EditCreditCard.removeThisCard]
        let cancelButton = removeThisCardAlert.scrollViews.otherElements.buttons[
            creditCardsStaticTexts.EditCreditCard.cancel
        ]
        let removeButton = removeThisCardAlert.scrollViews.otherElements.buttons[
            creditCardsStaticTexts.EditCreditCard.remove
        ]
        waitForElementsToExist(
            [
                removeThisCardAlert,
                cancelButton,
                removeButton
            ]
        )
        // Tap on "CANCEL"
        cancelButton.tap()
        // The prompt is dismissed, the "Edit card" page is displayed
        mozWaitForElementToNotExist(removeThisCardAlert)
        mozWaitForElementToExist(app.navigationBars[creditCardsStaticTexts.EditCreditCard.editCreditCard])
        // Tap again on the "Remove card" button
        app.buttons[creditCardsStaticTexts.EditCreditCard.removeCard].tap()
        // The prompt is displayed again
        // Tap "Remove" on the prompt
        removeButton.waitAndTap()
        // The credit card is deleted. The user is redirected to the "Saved cards" page
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        mozWaitForElementToNotExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.savedCards])
        mozWaitForElementToNotExist(app.tables.cells.element(boundBy: 1))
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306975
    // SmokeTest
    func testEditSavedCardsUI() {
        addCardAndReachViewCardPage()

        // Go back to saved cards section
        app.navigationBars.buttons[creditCardsStaticTexts.ViewCreditCard.close].tap()
        waitForElementsToExist(
            [
                app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards],
                app.switches[creditCardsStaticTexts.AutoFillCreditCard.saveAutofillCards],
                app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.savedCards]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306972
    func testManageCreditCardsOption() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("addCreditCardAndReachAutofillWebsite() does not work on iOS 15")
        }
        addCreditCardAndReachAutofillWebsite()
        // Tap on the "Manage credit cards" option
        app.buttons[manageCards].tap()
        unlockLoginsView()
        // The user is redirected to the "Credit cards" section in Settings
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        // Tap the back button on the Credit cards page
        app.buttons["Settings"].tap()
        navigator.nowAt(SettingsScreen)
        app.buttons["Done"].waitAndTap()
        // The user is returned to the webpage
        mozWaitForElementToExist(app.webViews["Web content"].staticTexts["Explore Checkout"])
        mozWaitForElementToNotExist(app.buttons[useSavedCard])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306969
    // Smoketest
    func testAutofillCreditCardsToggleOnOff() {
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        let saveAndFillPaymentMethodsSwitch =
            app.switches[creditCardsStaticTexts.AutoFillCreditCard.saveAutofillCards].switches.firstMatch
        if saveAndFillPaymentMethodsSwitch.value! as? String == "1" {
            saveAndFillPaymentMethodsSwitch.tap()
        }
        XCTAssertEqual(saveAndFillPaymentMethodsSwitch.value! as? String, "0")
        app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard].tap()
        let dateFiveYearsFromNow = Calendar.current.date(byAdding: .year, value: 5, to: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "MMyy"
        let futureExpiryMonthYear = formatter.string(from: dateFiveYearsFromNow!)
        addCreditCard(name: "Test", cardNumber: cards[0], expirationDate: futureExpiryMonthYear)
        navigator.goto(NewTabScreen)
        navigator.openURL("https://mozilla.github.io/form-fill-examples/basic_cc.html")
        waitUntilPageLoad()
        // The autofill option (Use saved card prompt) is not displayed
        var cardNumber = app.webViews["Web content"].textFields["Card Number:"]
        if #unavailable(iOS 17) {
            cardNumber = app.webViews["Web content"].staticTexts["Card Number:"]
        }
        cardNumber.waitAndTap()
        mozWaitForElementToNotExist(app.buttons[useSavedCard])
        // If Keyboard is open, hit return button
        let keyboard = app.keyboards.firstMatch
        let timeout: TimeInterval = 5.0 // Set the timeout duration

        if keyboard.waitForExistence(timeout: timeout) {
            app.buttons["KeyboardAccessory.doneButton"].tap()
        } else {
            XCTFail("Keyboard did not appear within \(timeout) seconds")
        }

        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        // Enable the "Save and Fill Payment Methods" toggle
        app.switches.element(boundBy: 1).tap()
        XCTAssertEqual(saveAndFillPaymentMethodsSwitch.value! as? String, "1")
        app.buttons["Settings"].tap()
        navigator.nowAt(SettingsScreen)
        app.buttons["Done"].waitAndTap()
        cardNumber.waitAndTap()
        // The autofill option (Use saved card prompt) is displayed
        if !app.buttons[useSavedCard].waitForExistence(timeout: 3) {
            app.webViews["Web content"].staticTexts["Card Number:"].tap()
        }
        mozWaitForElementToExist(app.buttons[useSavedCard])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306971
    func testCreditCardsAutofill() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("addCreditCardAndReachAutofillWebsite() does not work on iOS 15")
        }
        addCreditCardAndReachAutofillWebsite()
        // Select the saved credit card
        selectCreditCardOnFormWebsite()
        dismissSavedCardsPrompt()
        // The credit card's number and name are imported correctly on the designated fields
        let contentView = app.webViews["Web content"].textFields
        mozWaitForElementToExist(contentView["Card number"])
        XCTAssertEqual(contentView["Card number"].value! as? String, "2720 9943 2658 1252")
        XCTAssertEqual(contentView["Expiration"].value! as? String, "05 / 40")
        XCTAssertEqual(contentView["Full name on card"].value! as? String, "Test")
        XCTAssertEqual(contentView["CVC"].value! as? String, "CVC")
        XCTAssertEqual(contentView["ZIP"].value! as? String, "ZIP")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306976
    func testVerifyThatTheEditedCreditCardIsSaved() throws {
        if #unavailable(iOS 17) {
            throw XCTSkip("testVerifyThatTheEditedCreditCardIsSaved() does not work on iOS 15 and iOS 16")
        }
        // Go to a saved credit card and change the name on card
        let updatedName = "Firefox"
        addCardAndReachViewCardPage()
        app.buttons[creditCardsStaticTexts.ViewCreditCard.edit].waitAndTap()
        tapCardName()
        nameOnCard.clearText()
        typeCardName(name: updatedName)
        app.buttons["Save"].tap()
        // The name of the card is saved without issues
        mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons[updatedName])
        // Go to an saved credit card and change the credit card number
        app.tables.cells.element(boundBy: 1).tap()
        app.buttons[creditCardsStaticTexts.ViewCreditCard.edit].tap()
        tapCardNr()
        cardNr.clearText()
        typeCardNr(cardNo: cards[1])
        app.buttons["Save"].tap()
        // The credit card number is saved without issues
        mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons.elementContainingText("1111"))
        // Reach autofill website
        // reachAutofillWebsite() does not work on iOS 15
        if #available(iOS 16, *) {
            reachAutofillWebsite()
            app.scrollViews.otherElements.tables.cells.firstMatch.tap()
            // The credit card's number and name are imported correctly on the designated fields
            validateAutofillCardInfo(cardNr: "4111 1111 1111 1111", expirationNr: "05 / 40", name: updatedName)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306974
    func testVerifyThatMultipleCardsCanBeAdded() {
        // Add multiple credit cards
        let expectedCards = 3
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard].tap()
        addCreditCard(name: "Test", cardNumber: cards[0], expirationDate: "0540")
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard].tap()
        addCreditCard(name: "Test2", cardNumber: cards[1], expirationDate: "0640")
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard].tap()
        addCreditCard(name: "Test3", cardNumber: cards[2], expirationDate: "0740")
        // The cards are saved and displayed in Saved cards
        XCTAssertEqual(app.tables.cells.count - 1, expectedCards)
        let cardsInfo = [["1252", "Test", "5/40"],
                         ["1111", "Test2", "6/40"],
                         ["9631", "Test3", "7/40"]]
        for index in 1...3 {
            mozWaitForElementToExist(app.tables.cells.element(boundBy: index).buttons.firstMatch)
            XCTAssertTrue(app.tables.cells.element(boundBy: index).buttons
                .elementContainingText(cardsInfo[index-1][0]).exists,
                          "\(cardsInfo[index-1][0]) info is not displayed")
            XCTAssertTrue(app.tables.cells.element(boundBy: index).buttons[cardsInfo[index-1][1]].exists,
                          "\(cardsInfo[index-1][1]) info is not displayed")
            XCTAssertTrue(app.tables.cells.element(boundBy: index).buttons[cardsInfo[index-1][2]].exists,
                          "\(cardsInfo[index-1][2]) info is not displayed")
        }
        // reachAutofillWebsite() not working on iOS 15
        if #available(iOS 16, *) {
            // Reach used saved cards autofill website
            reachAutofillWebsite()
            // Any saved card can be selected/used from the autofill menu
            app.scrollViews.otherElements.tables.cells.firstMatch.tap()
            validateAutofillCardInfo(cardNr: "2720 9943 2658 1252", expirationNr: "05 / 40", name: "Test")
            dismissSavedCardsPrompt()
            swipeUp(nrOfSwipes: 2)
            swipeDown(nrOfSwipes: 1)
            app.webViews["Web content"].textFields["Full name on card"].tapOnApp()
            swipeUp(nrOfSwipes: 2)
            swipeDown(nrOfSwipes: 1)
            if !app.buttons[useSavedCard].exists {
                app.webViews["Web content"].textFields["CVC"].tapOnApp()
            }
            app.buttons[useSavedCard].waitAndTap()
            unlockLoginsView()
            mozWaitForElementToExist(app.staticTexts["Use saved card"])
            app.scrollViews.otherElements.tables.cells["creditCardCell_1"].tap()
            validateAutofillCardInfo(cardNr: "4111 1111 1111 1111", expirationNr: "06 / 40", name: "Test2")
            app.webViews["Web content"].textFields["Email"].tapOnApp()
            app.webViews["Web content"].textFields["Card number"].tapOnApp()
            if !app.buttons[useSavedCard].exists {
                app.webViews["Web content"].textFields["Full name on card"].tapOnApp()
            }
            app.buttons[useSavedCard].waitAndTap()
            unlockLoginsView()
            mozWaitForElementToExist(app.staticTexts["Use saved card"])
            app.scrollViews.element.swipeUp()
            mozWaitForElementToExist(app.scrollViews.otherElements.tables.cells["creditCardCell_2"])
            app.scrollViews.otherElements.tables.cells["creditCardCell_2"].tap()
            validateAutofillCardInfo(cardNr: "5346 7556 0029 9631", expirationNr: "07 / 40", name: "Test3")
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306977
    func testErrorStatesCreditCards() {
        // Go to a saved credit card and delete the name
        addCardAndReachViewCardPage()
        app.buttons[creditCardsStaticTexts.ViewCreditCard.edit].tap()
        let saveButton = app.buttons[creditCardsStaticTexts.AddCreditCard.save]
        tapCardName()
        nameOnCard.clearText()
        tapCardNr()

        // Error message is displayed
        waitForElementsToExist(
            [
                app.otherElements.staticTexts["Add a name"],
                saveButton
            ]
        )
        XCTAssertFalse(saveButton.isEnabled)
        // Fill in the name on card, and delete the credit card number
        tapCardName()
        typeCardName(name: "Test")
        tapCardNr()
        mozWaitForElementToNotExist(app.otherElements.staticTexts["Add a name"])
        mozWaitForElementToExist(saveButton)
        XCTAssertTrue(saveButton.isEnabled)
        cardNr.clearText()
        tapCardName()
        // Error message is displayed
        waitForElementsToExist([app.otherElements.staticTexts["Enter a valid card number"], saveButton])
        XCTAssertFalse(saveButton.isEnabled)
        // Fill in the name on the card and the credit card number, delete the Expiration date
        tapCardNr()
        typeCardNr(cardNo: cards[0])
        tapExpiration()
        mozWaitForElementToNotExist(app.otherElements.staticTexts["Enter a valid card number"])
        mozWaitForElementToExist(saveButton)
        XCTAssertTrue(saveButton.isEnabled)
        expiration.clearText()
        tapCardNr()
        // Error message is displayed
        waitForElementsToExist(
            [
                app.otherElements.staticTexts["Enter a valid expiration date"],
                saveButton
            ]
        )
        XCTAssertFalse(saveButton.isEnabled)
        // Add the credit card number back and save it
        tapExpiration()
        typeExpirationDate(exprDate: "0540")
        tapCardNr()
        mozWaitForElementToNotExist(app.otherElements.staticTexts["Enter a valid expiration date"])
        mozWaitForElementToExist(saveButton)
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()
        // The credit card is saved
        let cardsInfo = ["Test", "5/40"]
        mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons.elementContainingText("1252"))
        for i in cardsInfo {
            mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons[i])
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306979
    func testSaveThisCardPrompt() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("testSaveThisCardPrompt() does not work on iOS 15")
        }
        navigator.goto(NewTabScreen)
        navigator.openURL("https://checkout.stripe.dev/preview")
        waitUntilPageLoad()
        app.swipeUp()
        // Fill in the form with the card details of a new (unsaved) credit card.
        fillCardDetailsOnWebsite(cardNr: cards[1], expirationDate: "0540", nameOnCard: "Test")
        // Tap on "Pay"
        let payButton = app.webViews["Web content"].buttons["Pay"]
        if iPad() {
            app.swipeUp()
        }
        payButton.tapOnApp()
        // Securely save this card prompt is displayed
        waitForElementsToExist(
            [
                app.staticTexts["Securely save this card?"],
                app.buttons["Save"],
                app.buttons[AccessibilityIdentifiers.SaveCardPrompt.Prompt.closeButton]
            ]
        )
        // Tapping 'x' will dismiss the prompt
        app.buttons[AccessibilityIdentifiers.SaveCardPrompt.Prompt.closeButton].tap()
        mozWaitForElementToNotExist(app.staticTexts["Securely save this card?"])
        // Go to the Settings --> Payment methods
        swipeDown(nrOfSwipes: 2)
        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        // The credit card is not saved
        mozWaitForElementToExist(app.staticTexts["Save Cards to Firefox"])
        mozWaitForElementToNotExist(app.tables.cells.element(boundBy: 1))
        // Repeat above steps and tap 'Save'
        if #unavailable(iOS 16) {
            app.terminate()
            app.launch()
            navigator.nowAt(NewTabScreen)
        } else {
            navigator.goto(NewTabScreen)
        }
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.goto(NewTabScreen)
        navigator.openURL("https://checkout.stripe.dev/preview")
        waitUntilPageLoad()
        app.swipeUp()
        // Fill in the form with the card details of a new (unsaved) credit card.
        fillCardDetailsOnWebsite(cardNr: cards[1], expirationDate: "0540", nameOnCard: "Test")
        payButton.tapOnApp()
        app.buttons["Save"].tap()
        // The prompt is dismissed. And a toast message is displayed: "New card saved"
        mozWaitForElementToExist(app.staticTexts["New Card Saved"])
        mozWaitForElementToNotExist(app.staticTexts["Securely save this card?"])
        // Go to the Settings --> Payment methods
        swipeDown(nrOfSwipes: 2)
        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        // The credit card is saved and displayed in the Credit cards section
        waitForElementsToExist(
            [
                app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.savedCards],
                app.tables.cells.element(
                    boundBy: 1
                ).buttons.elementContainingText(
                    "1111"
                )
            ]
        )
        let cardDetails = ["Test", "Expires", "5/40"]
        for i in cardDetails {
            XCTAssertTrue(app.tables.cells.element(boundBy: 1).buttons[i].exists, "\(i) does not exists")
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306980
    func testUpdatePrompt() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("addCreditCardAndReachAutofillWebsite() does not work on iOS 15")
        }
        // Fill in the form with the details of an already saved credit card
        addCreditCardAndReachAutofillWebsite()
        // Select the saved credit card
        selectCreditCardOnFormWebsite()
        dismissSavedCardsPrompt()
        // Modify the card details
        fillCardDetailsOnWebsite(cardNr: cards[1], expirationDate: "0640", nameOnCard: "Test2", skipFillInfo: true)
        // Tap on "Pay"
        let payButton = app.webViews["Web content"].buttons["Pay"]
        if iPad() {
            app.swipeUp()
        }
        payButton.tapOnApp()
        // The "Update this card?" prompt is displayed.
        // The prompt contains two buttons: "Save" and "x".
        waitForElementsToExist(
            [
                app.staticTexts["Update card?"],
                app.buttons["Save"]
            ]
        )
        // Tapping 'x' will dismiss the prompt
        app.buttons["Done"].tapIfExists()
        app.buttons[AccessibilityIdentifiers.SaveCardPrompt.Prompt.closeButton].waitAndTap()
        mozWaitForElementToNotExist(app.staticTexts["Update card?"])
        // Go to the Settings --> Payment methods
        swipeDown(nrOfSwipes: 3)
        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        // Credit cards details did not change
        mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons.elementContainingText("1252"))
        var cardDetails = ["Test", "Expires", "5/40"]
        for i in cardDetails {
            mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons[i])
        }
        // Repeat above steps and tap on "Save"
        navigator.goto(NewTabScreen)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.goto(NewTabScreen)
        navigator.openURL("https://checkout.stripe.dev/preview")
        waitUntilPageLoad()
        swipeUp(nrOfSwipes: 2)
        swipeDown(nrOfSwipes: 1)
        let cardNumber = app.webViews["Web content"].textFields["Card number"]
        mozWaitForElementToExist(cardNumber)
        cardNumber.tapOnApp()
        // Expand the saved card prompt
        app.buttons[useSavedCard].waitAndTap()
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts["Use saved card"])
        // Select the saved credit card
        selectCreditCardOnFormWebsite()
        dismissSavedCardsPrompt()
        // Modify the card details
        fillCardDetailsOnWebsite(cardNr: cards[1], expirationDate: "0640", nameOnCard: "Test2", skipFillInfo: true)
        // Tap on "Pay"
        if iPad() {
            app.swipeUp()
        }
        payButton.tapOnApp()
        // The "Update this card?" prompt is displayed.
        // The prompt contains two buttons: "Save" and "x".
        mozWaitForElementToExist(app.staticTexts["Update card?"])
        // Tapping 'x' will dismiss the prompt
        app.buttons["Save"].tap()
        mozWaitForElementToNotExist(app.staticTexts["Update card?"])
        // Go to the Settings --> Payment methods
        swipeDown(nrOfSwipes: 2)
        swipeUp(nrOfSwipes: 1)
        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        // Credit cards details changed
        mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons.elementContainingText("1252"))
        cardDetails = ["TestTest2", "Expires", "5/40"]
        for index in cardDetails {
            mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons[index])
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306970
    func testRedirectionToCreditCardsSection() {
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        restartInBackground()
        unlockLoginsView()
        let addCardButton = app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard]
        addCardButton.waitAndTap()
        addCreditCard(name: "Test", cardNumber: cards[0], expirationDate: "0540")
        restartInBackground()
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
    }

    private func selectCreditCardOnFormWebsite() {
        mozWaitForElementToExist(app.scrollViews.otherElements.tables.buttons["Test"])
        var attempts = 4
        while app.scrollViews.otherElements.tables.buttons["Test"].isHittable && attempts > 0 {
            app.scrollViews.otherElements.tables.cells.firstMatch.tapOnApp()
            attempts -= 1
        }
    }

    private func fillCardDetailsOnWebsite(cardNr: String, expirationDate: String, nameOnCard: String,
                                          skipFillInfo: Bool = false) {
        let cardNumber = app.webViews["Web content"].textFields["Card number"]
        let expiration = app.webViews["Web content"].textFields["Expiration"]
        let name = app.webViews["Web content"].textFields["Full name on card"]
        let email = app.webViews["Web content"].textFields.element(boundBy: 0)
        let cvc = app.webViews["Web content"].textFields["CVC"]
        let zip = app.webViews["Web content"].textFields["ZIP"]
        mozWaitForElementToExist(email)
        if !email.isHittable {
            swipeUp(nrOfSwipes: 2)
            swipeDown(nrOfSwipes: 1)
        }
        email.tapOnApp()
        var nrOfRetries = 3
        if iPad() {
            while email.value(forKey: "hasKeyboardFocus") as? Bool == false && nrOfRetries > 0 {
                app.buttons[AccessibilityIdentifiers.SaveCardPrompt.Prompt.closeButton].waitAndTap()
                email.tapOnApp()
            }
        }
        email.typeText("foo1@mozilla.org")

        mozWaitForElementToExist(cardNumber)
        if skipFillInfo == false {
            cardNumber.waitAndTap()
            dismissSavedCardsPrompt()
            cardNumber.waitAndTap()
            cardNumber.typeText(cardNr)
            mozWaitForElementToExist(expiration)
            dismissSavedCardsPrompt()
            expiration.waitAndTap()
            expiration.typeText(expirationDate)
        }
        sleep(1)
        if app.keyboards.firstMatch.exists {
            app.buttons["KeyboardAccessory.doneButton"].tap()
        }
        cvc.tapOnApp()
        cvc.typeText("123")
        zip.tapOnApp()
        while zip.value(forKey: "hasKeyboardFocus") as? Bool == false && nrOfRetries > 0 {
            // Series of swipes are required to reach the bottom part of the webview
            swipeDown(nrOfSwipes: 1)
            dismissSavedCardsPrompt()
            swipeUp(nrOfSwipes: 2)
            zip.tapOnApp()
            nrOfRetries -= 1
        }
        zip.typeText("12345")
        app.buttons["KeyboardAccessory.doneButton"].tap()

        if app.webViews["Web content"].switches.element(boundBy: 0).value as? String == "1" {
            app.webViews["Web content"].switches.element(boundBy: 0).tapOnApp()
        }
        name.tapOnApp()
        name.typeText(nameOnCard)
        swipeDown(nrOfSwipes: 2)
        swipeUp(nrOfSwipes: 2)
    }

    private func swipeUp(nrOfSwipes: Int) {
        for _ in 1...nrOfSwipes {
            app.webViews["Web content"].swipeUp()
        }
    }

    private func swipeDown(nrOfSwipes: Int) {
        for _ in 1...nrOfSwipes {
            app.webViews["Web content"].swipeDown()
        }
    }

    private func dismissSavedCardsPrompt() {
        if app.buttons.elementContainingText("Decline").isVisible() &&
            app.buttons.elementContainingText("Decline").isHittable {
            app.staticTexts["TEST CARDS"].tap()
        }
    }

    private func pressDelete() {
        if iPad() {
            mozWaitForElementToExist(app.keyboards.keys["delete"])
            app.keyboards.keys["delete"].press(forDuration: 2.2)
        } else {
            mozWaitForElementToExist(app.keyboards.keys["Delete"])
            app.keyboards.keys["Delete"].press(forDuration: 2.2)
        }
    }

    func tapCardName() {
        initCardFields()
        nameOnCard.waitAndTap()
        mozWaitForElementToExist(nameOnCard)
    }

    func tapCardNr() {
        initCardFields()
        cardNr.tap()
        mozWaitForElementToExist(cardNr)
    }

    func tapExpiration() {
        initCardFields()
        expiration.tap()
        mozWaitForElementToExist(expiration)
    }

    func typeCardName(name: String) {
        initCardFields()
        nameOnCard.typeText(name)
    }

    func typeCardNr(cardNo: String) {
        initCardFields()
        cardNr.typeTextWithDelay(cardNo, delay: 0.1)
    }

    func typeExpirationDate(exprDate: String) {
        initCardFields()
        expiration.typeText(exprDate)
    }

    private func validateAutofillCardInfo(cardNr: String, expirationNr: String, name: String) {
        let contentView = app.webViews["Web content"].textFields
        XCTAssertEqual(contentView["Card number"].value! as? String, cardNr)
        XCTAssertEqual(contentView["Expiration"].value! as? String, expirationNr)
        XCTAssertEqual(contentView["Full name on card"].value! as? String, name)
        XCTAssertEqual(contentView["CVC"].value! as? String, "CVC")
        XCTAssertEqual(contentView["ZIP"].value! as? String, "ZIP")
    }

    private func reachAutofillWebsite() {
        // Reach autofill website
        navigator.goto(NewTabScreen)
        navigator.openURL("https://checkout.stripe.dev/preview")
        waitUntilPageLoad()
        app.swipeUp()
        let cardNumber = app.webViews["Web content"].textFields["Card number"]
        mozWaitForElementToExist(cardNumber)
        swipeUp(nrOfSwipes: 2)
        swipeDown(nrOfSwipes: 1)
        cardNumber.tapOnApp()
        dismissSavedCardsPrompt()
        if !app.buttons[useSavedCard].exists {
            cardNumber.tapOnApp()
        }
        app.buttons[useSavedCard].waitAndTap()
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts["Use saved card"])
    }

    private func addCreditCardAndReachAutofillWebsite() {
        // Access any website with a credit card form and tap on the credit card number/ credit card name
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        let saveAndFillPaymentMethodsSwitch = app.switches[creditCardsStaticTexts.AutoFillCreditCard.saveAutofillCards]
        if saveAndFillPaymentMethodsSwitch.value! as? String == "0" {
            saveAndFillPaymentMethodsSwitch.tap()
        }
        app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard].tap()
        addCreditCard(name: "Test", cardNumber: cards[0], expirationDate: "0540")
        navigator.goto(NewTabScreen)
        navigator.openURL("https://checkout.stripe.dev/preview")
        waitUntilPageLoad()
        swipeUp(nrOfSwipes: 2)
        swipeDown(nrOfSwipes: 1)
        let cardNumber = app.webViews["Web content"].textFields["Card number"]
        mozWaitForElementToExist(cardNumber)
        cardNumber.tapOnApp()
        if !app.buttons[useSavedCard].isHittable {
            cardNumber.waitAndTap()
        }
        // Use saved card prompt is displayed
        app.buttons[useSavedCard].waitAndTap(timeout: TIMEOUT)
        unlockLoginsView()
        waitForElementsToExist(
            [
                app.staticTexts["Use saved card"],
                app.buttons[manageCards]
            ]
        )
    }

    private func addCardAndReachViewCardPage() {
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard].tap()
        addCreditCard(name: "Test", cardNumber: cards[0], expirationDate: "0540")
        // Tap on a saved card
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        app.tables.cells.element(boundBy: 1).tap()
        // The "View card" page is displayed with all the details of the card
        waitForElementsToExist(
            [
                app.navigationBars[creditCardsStaticTexts.ViewCreditCard.viewCard],
                app.tables.cells.element(
                    boundBy: 1
                ).buttons.elementContainingText(
                    "1252"
                )
            ]
        )
        let cardDetails = ["Test", "05 / 40"]
        for index in cardDetails {
            if #available(iOS 16, *) {
                mozWaitForElementToExist(app.buttons[index])
                XCTAssertTrue(app.buttons[index].exists, "\(index) does not exists")
            } else {
                mozWaitForElementToExist(app.staticTexts[index])
            }
        }
    }

    private func addCreditCard(name: String, cardNumber: String, expirationDate: String) {
        tapCardName()
        typeCardName(name: name)
        tapCardNr()
        typeCardNr(cardNo: cardNumber)
        tapExpiration()
        // Retry adding card number if first attempt failed
        if app.staticTexts["Enter a valid card number"].exists {
            retryOnCardNumber(cardNumber: cardNumber)
        }
        typeExpirationDate(exprDate: expirationDate)
        // Retry adding expiration date if first attempt failed
        if app.staticTexts["Enter a valid expiration date"].exists {
            retryExpirationNumber(expirationDate: expirationDate)
        }
        let saveButton = app.buttons[creditCardsStaticTexts.AddCreditCard.save]
        if !saveButton.isEnabled {
            retryOnCardNumber(cardNumber: cardNumber)
            mozWaitForElementToExist(expiration)
            expiration.typeText(expirationDate)
            retryExpirationNumber(expirationDate: expirationDate)
            mozWaitForElementToExist(saveButton)
        }
        saveButton.waitAndTap()
    }

    private func retryOnCardNumber(cardNumber: String) {
        tapCardNr()
        pressDelete()
        typeCardNr(cardNo: cardNumber)
        tapExpiration()
    }

    private func retryExpirationNumber(expirationDate: String) {
        pressDelete()
        typeExpirationDate(exprDate: expirationDate)
    }
}

extension XCUIElement {
    func clearText() {
        tap()
        if let stringValue = value as? String, !stringValue.isEmpty {
            let deleteString = stringValue.map { _ in "\u{8}" }.joined()
            typeText(deleteString)
        }
    }
}
