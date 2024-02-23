// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class CreditCardsTests: BaseTestCase {
    let creditCardsStaticTexts = AccessibilityIdentifiers.Settings.CreditCards.self
    let useSavedCard = AccessibilityIdentifiers.Browser.KeyboardAccessory.creditCardAutofillButton.self
    let manageCards = AccessibilityIdentifiers.RememberCreditCard.manageCardsButton.self

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
        addCreditCard(name: "Test", cardNumber: "2720994326581252", expirationDate: "0540")
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
        let saveAndFillPaymentMethodsSwitch = app.switches[creditCardsStaticTexts.AutoFillCreditCard.saveAutofillCards]
        if saveAndFillPaymentMethodsSwitch.value! as! String == "1" {
            saveAndFillPaymentMethodsSwitch.tap()
        }
        XCTAssertEqual(saveAndFillPaymentMethodsSwitch.value! as! String, "0")
        app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard].tap()
        addCreditCard(name: "Test", cardNumber: "2720994326581252", expirationDate: "0540")
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
        addCreditCard(name: "Test", cardNumber: "2720994326581252", expirationDate: "0540")
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
        addCreditCard(name: "Test", cardNumber: "2720994326581252", expirationDate: "0540")
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
        let nameOnCard: XCUIElement
        let cardNr: XCUIElement
        let expiration: XCUIElement
        if iPad() {
            nameOnCard = app.otherElements.textFields.element(boundBy: 0)
            cardNr = app.otherElements.textFields.element(boundBy: 1)
            expiration = app.otherElements.textFields.element(boundBy: 2)
        } else {
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
        app.buttons[creditCardsStaticTexts.AddCreditCard.save].tap()
    }

    private func retryOnCardNumber(cardNr: XCUIElement, expiration: XCUIElement, cardNumber: String) {
        cardNr.tap()
        while !cardNr.placeholderValue!.isEmpty {
            app.keyboards.keys["Delete"].tap()
        }
        cardNr.typeText(cardNumber)
        expiration.tap()
    }

    private func retryExpirationNumber(expiration: XCUIElement, expirationDate: String) {
        while !expiration.placeholderValue!.isEmpty {
            app.keyboards.keys["Delete"].tap()
        }
        expiration.typeText(expirationDate)
    }
}
