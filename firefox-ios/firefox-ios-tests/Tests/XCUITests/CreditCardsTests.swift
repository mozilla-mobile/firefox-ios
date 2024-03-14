// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class CreditCardsTests: BaseTestCase {
    let creditCardsStaticTexts = AccessibilityIdentifiers.Settings.CreditCards.self
    let useSavedCard = AccessibilityIdentifiers.Browser.KeyboardAccessory.creditCardAutofillButton.self
    let manageCards = AccessibilityIdentifiers.RememberCreditCard.manageCardsButton.self
    let cards = ["2720994326581252", "4111111111111111", "5346755600299631"]

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306967
    // SmokeTest
    func testAccessingTheCreditCardsSection() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        // Autofill Credit cards section displays
        let addCardButton = app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard]
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        XCTAssertTrue(addCardButton.exists)
        XCTAssertTrue(app.switches[creditCardsStaticTexts.AutoFillCreditCard.saveAutofillCards].exists)
        addCardButton.tap()
        // Add Credit Card page is displayed
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AddCreditCard.addCreditCard])
        XCTAssertTrue(app.staticTexts[creditCardsStaticTexts.AddCreditCard.nameOnCard].exists)
        XCTAssertTrue(app.staticTexts[creditCardsStaticTexts.AddCreditCard.cardNumber].exists)
        XCTAssertTrue(app.staticTexts[creditCardsStaticTexts.AddCreditCard.expiration].exists)
        XCTAssertTrue(app.buttons[creditCardsStaticTexts.AddCreditCard.close].exists)
        XCTAssertTrue(app.buttons[creditCardsStaticTexts.AddCreditCard.save].exists)
        // Add, and save a valid credit card
        addCreditCard(name: "Test", cardNumber: cards[0], expirationDate: "0540")
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.savedCards])
        XCTAssertTrue(app.staticTexts["New Card Saved"].exists)
        XCTAssertTrue(app.tables.cells.element(boundBy: 1).staticTexts.elementContainingText("1252").exists)
        let cardDetails = ["Test", "Expires", "5/40"]
        for i in cardDetails {
            XCTAssertTrue(app.tables.cells.element(boundBy: 1).staticTexts[i].exists, "\(i) does not exists")
        }
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306978
    // SmokeTest
    func testDeleteButtonFromEditCard() {
        addCardAndReachViewCardPage()
        // Tap on the "Remove card" button
        app.buttons[creditCardsStaticTexts.ViewCreditCard.edit].tap()
        mozWaitForElementToExist(app.navigationBars[creditCardsStaticTexts.EditCreditCard.editCreditCard])
        app.buttons[creditCardsStaticTexts.EditCreditCard.removeCard].tap()
        // Validate the pop up displayed
        let removeThisCardAlert = app.alerts[creditCardsStaticTexts.EditCreditCard.removeThisCard]
        let cancelButton = removeThisCardAlert.scrollViews.otherElements.buttons[
            creditCardsStaticTexts.EditCreditCard.cancel
        ]
        let removeButton = removeThisCardAlert.scrollViews.otherElements.buttons[
            creditCardsStaticTexts.EditCreditCard.remove
        ]
        mozWaitForElementToExist(removeThisCardAlert)
        XCTAssertTrue(cancelButton.exists)
        XCTAssertTrue(removeButton.exists)
        // Tap on "CANCEL"
        cancelButton.tap()
        // The prompt is dismissed, the "Edit card" page is displayed
        mozWaitForElementToNotExist(removeThisCardAlert)
        mozWaitForElementToExist(app.navigationBars[creditCardsStaticTexts.EditCreditCard.editCreditCard])
        // Tap again on the "Remove card" button
        app.buttons[creditCardsStaticTexts.EditCreditCard.removeCard].tap()
        // The prompt is displayed again
        mozWaitForElementToExist(removeThisCardAlert)
        // Tap "Remove" on the prompt
        removeButton.tap()
        // The credit card is deleted. The user is redirected to the "Saved cards" page
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        mozWaitForElementToNotExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.savedCards])
        XCTAssertFalse(app.tables.cells.element(boundBy: 1).exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306975
    // SmokeTest
    func testEditSavedCardsUI() {
        addCardAndReachViewCardPage()

        // Go back to saved cards section
        app.buttons[creditCardsStaticTexts.ViewCreditCard.close].tap()
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        mozWaitForElementToExist(app.switches[creditCardsStaticTexts.AutoFillCreditCard.saveAutofillCards])
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.savedCards])
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306972
    func testManageCreditCardsOption() {
        addCreditCardAndReachAutofillWebsite()
        // Tap on the "Manage credit cards" option
        app.buttons[manageCards].tap()
        unlockLoginsView()
        // The user is redirected to the "Credit cards" section in Settings
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        // Tap the back button on the Credit cards page
        app.buttons["Settings"].tap()
        navigator.nowAt(SettingsScreen)
        waitForExistence(app.buttons["Done"])
        app.buttons["Done"].tap()
        // The user is returned to the webpage
        mozWaitForElementToExist(app.webViews["contentView"].webViews.staticTexts["Explore Checkout"])
        mozWaitForElementToNotExist(app.buttons[useSavedCard])
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306969
    // Smoketest
    func testAutofillCreditCardsToggleOnOoff() {
        // Disable the "Save and Fill Payment Methods" toggle
        navigator.nowAt(NewTabScreen)
        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        let saveAndFillPaymentMethodsSwitch =
            app.switches[creditCardsStaticTexts.AutoFillCreditCard.saveAutofillCards].switches.firstMatch
        if saveAndFillPaymentMethodsSwitch.value! as! String == "1" {
            saveAndFillPaymentMethodsSwitch.tap()
        }
        XCTAssertEqual(saveAndFillPaymentMethodsSwitch.value! as! String, "0")
        app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard].tap()
        addCreditCard(name: "Test", cardNumber: cards[0], expirationDate: "0540")
        navigator.goto(NewTabScreen)
        navigator.openURL("https://checkout.stripe.dev/preview")
        waitUntilPageLoad()
        app.swipeUp()
        let cardNumber = app.webViews["contentView"].webViews.textFields["Card number"]
        mozWaitForElementToExist(cardNumber)
        cardNumber.tapOnApp()
        // The autofill option (Use saved card prompt) is not displayed
        mozWaitForElementToNotExist(app.buttons[useSavedCard])
        if app.staticTexts["TEST CARDS"].exists {
            app.staticTexts["TEST CARDS"].tap()
        }
        app.swipeUp()
        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        // Enable the "Save and Fill Payment Methods" toggle
        app.switches.element(boundBy: 1).tap()
        XCTAssertEqual(saveAndFillPaymentMethodsSwitch.value! as! String, "1")
        app.buttons["Settings"].tap()
        navigator.nowAt(SettingsScreen)
        waitForExistence(app.buttons["Done"])
        app.buttons["Done"].tap()
        if app.staticTexts["TEST CARDS"].exists {
            app.staticTexts["TEST CARDS"].tap()
        }
        mozWaitForElementToExist(app.webViews["contentView"].webViews.staticTexts["Explore Checkout"])
        mozWaitForElementToExist(cardNumber)
        cardNumber.tapOnApp()
        // The autofill option (Use saved card prompt) is displayed
        mozWaitForElementToExist(app.buttons[useSavedCard])
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306971
    func testCreditCardsAutofill() {
        addCreditCardAndReachAutofillWebsite()
        // Select the saved credit card
        mozWaitForElementToExist(app.scrollViews.otherElements.tables.staticTexts["Test"])
        var attempts = 4
        while app.scrollViews.otherElements.tables.staticTexts["Test"].isHittable && attempts > 0 {
            app.scrollViews.otherElements.tables.cells.firstMatch.tapOnApp()
            attempts -= 1
        }
        if app.staticTexts["TEST CARDS"].exists {
            app.staticTexts["TEST CARDS"].tap()
        }
        // The credit card's number and name are imported correctly on the designated fields
        let contentView = app.webViews["contentView"].webViews.textFields
        XCTAssertEqual(contentView["Card number"].value! as! String, "2720 9943 2658 1252")
        XCTAssertEqual(contentView["Expiration"].value! as! String, "05 / 40")
        XCTAssertEqual(contentView["Full name on card"].value! as! String, "Test")
        XCTAssertEqual(contentView["CVC"].value! as! String, "CVC")
        XCTAssertEqual(contentView["ZIP"].value! as! String, "ZIP")
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306976
    func testVerifyThatTheEditedCreditCardIsSaved() {
        // Go to a saved credit card and change the name on card
        let updatedName = "Firefox"
        addCardAndReachViewCardPage()
        app.buttons[creditCardsStaticTexts.ViewCreditCard.edit].tap()
        var nameOnCard = app.otherElements.textFields.element(boundBy: 0)
        if !iPad() {
            nameOnCard = app.otherElements.textFields.element(boundBy: 1)
        }
        nameOnCard.tap()
        app.keyboards.keys["delete"].press(forDuration: 1.5)
        nameOnCard.typeText(updatedName)
        app.buttons["Save"].tap()
        // The name of the card is saved without issues
        XCTAssertTrue(app.tables.cells.element(boundBy: 1).staticTexts[updatedName].exists, "\(updatedName) does not exists")
        // Go to an saved credit card and change the credit card number
        app.tables.cells.element(boundBy: 1).tap()
        app.buttons[creditCardsStaticTexts.ViewCreditCard.edit].tap()
        var cardNr = app.otherElements.textFields.element(boundBy: 1)
        if !iPad() {
            cardNr = app.otherElements.textFields.element(boundBy: 2)
        }
        cardNr.tap()
        pressDelete()
        cardNr.typeText(cards[1])
        app.buttons["Save"].tap()
        // The credit card number is saved without issues
        XCTAssertTrue(app.tables.cells.element(boundBy: 1).staticTexts.elementContainingText("1111").exists)
        // Reach autofill website
        reachAutofillWebsite()
        app.scrollViews.otherElements.tables.cells.firstMatch.tap()
        // The credit card's number and name are imported correctly on the designated fields
        validateAutofillCardInfo(cardNr: "4111 1111 1111 1111", expirationNr: "05 / 40", name: updatedName)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306974
    func testVerifyThatMultipleCardsCanBeAdded() {
        // Add multiple credit cards
        let expectedCards = 3
        navigator.nowAt(NewTabScreen)
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
        for i in 1...3 {
            XCTAssertTrue(app.tables.cells.element(boundBy: i).staticTexts.elementContainingText(cardsInfo[i-1][0]).exists,
                          "\(cardsInfo[i-1][0]) info is not displayed")
            XCTAssertTrue(app.tables.cells.element(boundBy: i).staticTexts[cardsInfo[i-1][1]].exists,
                          "\(cardsInfo[i-1][1]) info is not displayed")
            XCTAssertTrue(app.tables.cells.element(boundBy: i).staticTexts[cardsInfo[i-1][2]].exists,
                          "\(cardsInfo[i-1][2]) info is not displayed")
        }
        // Reach used saved cards autofill website
        reachAutofillWebsite()
        // Any saved card can be selected/used from the autofill menu
        app.scrollViews.otherElements.tables.cells.firstMatch.tap()
        validateAutofillCardInfo(cardNr: "2720 9943 2658 1252", expirationNr: "05 / 40", name: "Test")
        if app.staticTexts["TEST CARDS"].exists {
            app.staticTexts["TEST CARDS"].tap()
        }
        app.swipeUp()
        app.webViews["contentView"].webViews.textFields["Full name on card"].tapOnApp()
        if !app.buttons[useSavedCard].exists {
            app.webViews["contentView"].webViews.textFields["Card number"].tapOnApp()
        }
        app.buttons[useSavedCard].tap()
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts["Use saved card"])
        app.scrollViews.otherElements.tables.cells.element(boundBy: 1).tap()
        validateAutofillCardInfo(cardNr: "4111 1111 1111 1111", expirationNr: "06 / 40", name: "Test2")
        if app.staticTexts["TEST CARDS"].exists {
            app.staticTexts["TEST CARDS"].tap()
        }
        app.swipeUp()
        app.webViews["contentView"].webViews.textFields["Card number"].tapOnApp()
        if !app.buttons[useSavedCard].exists {
            app.webViews["contentView"].webViews.textFields["Full name on card"].tapOnApp()
        }
        app.buttons[useSavedCard].tap()
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts["Use saved card"])
        app.scrollViews.otherElements.tables.cells.element(boundBy: 2).tap()
        validateAutofillCardInfo(cardNr: "5346 7556 0029 9631", expirationNr: "07 / 40", name: "Test3")
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306977
    func testErrorStatesCreditCards() {
        // Go to a saved credit card and delete the name
        addCardAndReachViewCardPage()
        app.buttons[creditCardsStaticTexts.ViewCreditCard.edit].tap()
        let saveButton = app.buttons[creditCardsStaticTexts.AddCreditCard.save]
        var nameOnCard = app.otherElements.textFields.element(boundBy: 0)
        var cardNr = app.otherElements.textFields.element(boundBy: 1)
        var expiration = app.otherElements.textFields.element(boundBy: 2)
        if !iPad() {
            nameOnCard = app.otherElements.textFields.element(boundBy: 1)
            cardNr = app.otherElements.textFields.element(boundBy: 2)
            expiration = app.otherElements.textFields.element(boundBy: 3)
        }
        nameOnCard.tap()
        app.keyboards.keys["delete"].press(forDuration: 1.5)
        cardNr.tap()
        // Error message is displayed
        mozWaitForElementToExist(app.otherElements.staticTexts["Add a name"])
        XCTAssertFalse(saveButton.isEnabled)
        // Fill in the name on card, and delete the credit card number
        nameOnCard.tap()
        nameOnCard.typeText("Test")
        cardNr.tap()
        mozWaitForElementToNotExist(app.otherElements.staticTexts["Add a name"])
        XCTAssertTrue(saveButton.isEnabled)
        pressDelete()
        nameOnCard.tap()
        // Error message is displayed
        mozWaitForElementToExist(app.otherElements.staticTexts["Enter a valid card number"])
        XCTAssertFalse(saveButton.isEnabled)
        // Fill in the name on the card and the credit card number, delete the Expiration date
        cardNr.tap()
        cardNr.typeText(cards[0])
        expiration.tap()
        mozWaitForElementToNotExist(app.otherElements.staticTexts["Enter a valid card number"])
        XCTAssertTrue(saveButton.isEnabled)
        pressDelete()
        cardNr.tap()
        // Error message is displayed
        mozWaitForElementToExist(app.otherElements.staticTexts["Enter a valid expiration date"])
        XCTAssertFalse(saveButton.isEnabled)
        // Add the credit card number back and save it
        expiration.tap()
        expiration.typeText("0540")
        cardNr.tap()
        mozWaitForElementToNotExist(app.otherElements.staticTexts["Enter a valid expiration date"])
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()
        // The credit card is saved
        let cardsInfo = ["Test", "5/40"]
        XCTAssertTrue(app.tables.cells.element(boundBy: 1).staticTexts.elementContainingText("1252").exists,
                      "1252 info is not displayed")
        for i in cardsInfo {
            XCTAssertTrue(app.tables.cells.element(boundBy: 1).staticTexts[i].exists,
                          "\(i) info is not displayed")
        }
    }

    private func pressDelete() {
        if iPad() {
            app.keyboards.keys["delete"].press(forDuration: 2.2)
        } else {
            app.keyboards.keys["Delete"].press(forDuration: 2.2)
        }
    }

    private func validateAutofillCardInfo(cardNr: String, expirationNr: String, name: String) {
        let contentView = app.webViews["contentView"].webViews.textFields
        XCTAssertEqual(contentView["Card number"].value! as! String, cardNr)
        XCTAssertEqual(contentView["Expiration"].value! as! String, expirationNr)
        XCTAssertEqual(contentView["Full name on card"].value! as! String, name)
        XCTAssertEqual(contentView["CVC"].value! as! String, "CVC")
        XCTAssertEqual(contentView["ZIP"].value! as! String, "ZIP")
    }

    private func reachAutofillWebsite() {
        // Reach autofill website
        navigator.goto(NewTabScreen)
        navigator.openURL("https://checkout.stripe.dev/preview")
        waitUntilPageLoad()
        app.swipeUp()
        let cardNumber = app.webViews["contentView"].webViews.textFields["Card number"]
        mozWaitForElementToExist(cardNumber)
        cardNumber.tapOnApp()
        if !app.buttons[useSavedCard].exists {
            cardNumber.tapOnApp()
        }
        mozWaitForElementToExist(app.buttons[useSavedCard])
        app.buttons[useSavedCard].tap()
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts["Use saved card"])
    }

    private func addCreditCardAndReachAutofillWebsite() {
        // Access any website with a credit card form and tap on the credit card number/ credit card name
        navigator.nowAt(NewTabScreen)
        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        let saveAndFillPaymentMethodsSwitch = app.switches[creditCardsStaticTexts.AutoFillCreditCard.saveAutofillCards]
        if saveAndFillPaymentMethodsSwitch.value! as! String == "0" {
            saveAndFillPaymentMethodsSwitch.tap()
        }
        app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard].tap()
        addCreditCard(name: "Test", cardNumber: cards[0], expirationDate: "0540")
        navigator.goto(NewTabScreen)
        navigator.openURL("https://checkout.stripe.dev/preview")
        waitUntilPageLoad()
        app.swipeUp()
        let cardNumber = app.webViews["contentView"].webViews.textFields["Card number"]
        mozWaitForElementToExist(cardNumber)
        cardNumber.tapOnApp()
        // Use saved card prompt is displayed
        mozWaitForElementToExist(app.buttons[useSavedCard])
        // Expand the prompt
        app.buttons[useSavedCard].tap()
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts["Use saved card"])
        mozWaitForElementToExist(app.buttons[manageCards])
    }

    private func addCardAndReachViewCardPage() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard].tap()
        addCreditCard(name: "Test", cardNumber: cards[0], expirationDate: "0540")
        // Tap on a saved card
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        app.tables.cells.element(boundBy: 1).tap()
        // The "View card" page is displayed with all the details of the card
        mozWaitForElementToExist(app.navigationBars[creditCardsStaticTexts.ViewCreditCard.viewCard])
        XCTAssertTrue(app.tables.cells.element(boundBy: 1).staticTexts.elementContainingText("1252").exists)
        let cardDetails = ["Test", "05 / 40"]
        for i in cardDetails {
            XCTAssertTrue(app.textFields[i].exists, "\(i) does not exists")
        }
    }

    private func addCreditCard(name: String, cardNumber: String, expirationDate: String) {
        var nameOnCard = app.otherElements.textFields.element(boundBy: 0)
        var cardNr = app.otherElements.textFields.element(boundBy: 1)
        var expiration = app.otherElements.textFields.element(boundBy: 2)
        if !iPad() {
            nameOnCard = app.otherElements.textFields.element(boundBy: 1)
            cardNr = app.otherElements.textFields.element(boundBy: 2)
            expiration = app.otherElements.textFields.element(boundBy: 3)
        }
        nameOnCard.tap()
        mozWaitForElementToExist(nameOnCard)
        nameOnCard.typeText(name)
        cardNr.tap()
        mozWaitForElementToExist(cardNr)
        cardNr.typeText(cardNumber)
        expiration.tap()
        // Retry adding card number if first attempt failed
        if app.staticTexts["Enter a valid card number"].exists {
            retryOnCardNumber(cardNr: cardNr, expiration: expiration, cardNumber: cardNumber)
        }
        mozWaitForElementToExist(expiration)
        expiration.typeText(expirationDate)
        // Retry adding expiration date if first attempt failed
        if app.staticTexts["Enter a valid expiration date"].exists {
            retryExpirationNumber(expiration: expiration, expirationDate: expirationDate)
        }
        let saveButton = app.buttons[creditCardsStaticTexts.AddCreditCard.save]
        mozWaitForElementToExist(saveButton)
        if !saveButton.isEnabled {
            retryOnCardNumber(cardNr: cardNr, expiration: expiration, cardNumber: cardNumber)
            mozWaitForElementToExist(expiration)
            expiration.typeText(expirationDate)
            retryExpirationNumber(expiration: expiration, expirationDate: expirationDate)
            mozWaitForElementToExist(saveButton)
        }
        XCTAssertTrue(saveButton.isEnabled, "Save button is disabled")
        saveButton.tap()
    }

    private func retryOnCardNumber(cardNr: XCUIElement, expiration: XCUIElement, cardNumber: String) {
        cardNr.tap()
        app.keyboards.keys["Delete"].press(forDuration: 2.2)
        cardNr.typeText(cardNumber)
        expiration.tap()
    }

    private func retryExpirationNumber(expiration: XCUIElement, expirationDate: String) {
        app.keyboards.keys["Delete"].press(forDuration: 1.5)
        expiration.typeText(expirationDate)
    }
}
