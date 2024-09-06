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
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        mozWaitForElementToExist(addCardButton)
        mozWaitForElementToExist(app.switches[creditCardsStaticTexts.AutoFillCreditCard.saveAutofillCards])
        addCardButton.tap()
        // Add Credit Card page is displayed
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AddCreditCard.addCreditCard])
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AddCreditCard.nameOnCard])
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AddCreditCard.cardNumber])
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AddCreditCard.expiration])
        mozWaitForElementToExist(app.buttons[creditCardsStaticTexts.AddCreditCard.close])
        mozWaitForElementToExist(app.buttons[creditCardsStaticTexts.AddCreditCard.save])
        // Add, and save a valid credit card
        addCreditCard(name: "Test", cardNumber: cards[0], expirationDate: "0540")
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.savedCards])
        mozWaitForElementToExist(app.staticTexts.containingText("New").element)
        mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons.elementContainingText("1252"))
        let cardDetails = ["Test", "Expires", "5/40"]
        for i in cardDetails {
            mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons[i])
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306978
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
        mozWaitForElementToExist(cancelButton)
        mozWaitForElementToExist(removeButton)
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
        mozWaitForElementToNotExist(app.tables.cells.element(boundBy: 1))
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306975
    // SmokeTest
    func testEditSavedCardsUI() {
        addCardAndReachViewCardPage()

        // Go back to saved cards section
        app.navigationBars.buttons[creditCardsStaticTexts.ViewCreditCard.close].tap()
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        mozWaitForElementToExist(app.switches[creditCardsStaticTexts.AutoFillCreditCard.saveAutofillCards])
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.savedCards])
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
        waitForExistence(app.buttons["Done"])
        app.buttons["Done"].tap()
        // The user is returned to the webpage
        mozWaitForElementToExist(app.webViews["contentView"].webViews.staticTexts["Explore Checkout"])
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
        if saveAndFillPaymentMethodsSwitch.value! as! String == "1" {
            saveAndFillPaymentMethodsSwitch.tap()
        }
        XCTAssertEqual(saveAndFillPaymentMethodsSwitch.value! as! String, "0")
        app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard].tap()
        addCreditCard(name: "Test", cardNumber: cards[0], expirationDate: "0540")
        if #available(iOS 16, *) {
            navigator.goto(NewTabScreen) // Not working on iOS 15
            navigator.openURL("https://checkout.stripe.dev/preview")
            waitUntilPageLoad()
            // The autofill option (Use saved card prompt) is not displayed
            let cardNumber = app.webViews["contentView"].webViews.textFields["Card number"]
            app.swipeUp()
            app.swipeUp()
            mozWaitForElementToExist(cardNumber)
            if !cardNumber.isHittable {
                swipeUp(nrOfSwipes: 2)
            }
            cardNumber.tapOnApp()
            let menuButton = AccessibilityIdentifiers.Toolbar.settingsMenuButton
            if !app.buttons[menuButton].isHittable {
                cardNumber.tapOnApp()
            }
            mozWaitForElementToNotExist(app.buttons[useSavedCard])
            dismissSavedCardsPrompt()
            swipeDown(nrOfSwipes: 3)
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
            app.swipeUp()
            mozWaitForElementToExist(app.webViews["contentView"].webViews.staticTexts["Explore Checkout"], timeout: TIMEOUT)
            mozWaitForElementToExist(cardNumber)
            cardNumber.tapOnApp()
            // The autofill option (Use saved card prompt) is displayed
            if !app.buttons[useSavedCard].exists {
                app.webViews["contentView"].webViews.textFields["Full name on card"].tapOnApp()
            }
            mozWaitForElementToExist(app.buttons[useSavedCard])
        }
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
        let contentView = app.webViews["contentView"].webViews.textFields
        mozWaitForElementToExist(contentView["Card number"])
        XCTAssertEqual(contentView["Card number"].value! as! String, "2720 9943 2658 1252")
        XCTAssertEqual(contentView["Expiration"].value! as! String, "05 / 40")
        XCTAssertEqual(contentView["Full name on card"].value! as! String, "Test")
        XCTAssertEqual(contentView["CVC"].value! as! String, "CVC")
        XCTAssertEqual(contentView["ZIP"].value! as! String, "ZIP")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306976
    func testVerifyThatTheEditedCreditCardIsSaved() {
        // Go to a saved credit card and change the name on card
        let updatedName = "Firefox"
        addCardAndReachViewCardPage()
        app.buttons[creditCardsStaticTexts.ViewCreditCard.edit].tap()
        tapCardName()
        app.keyboards.keys["delete"].press(forDuration: 1.5)
        typeCardName(name: updatedName)
        app.buttons["Save"].tap()
        // The name of the card is saved without issues
        mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons[updatedName])
        // Go to an saved credit card and change the credit card number
        app.tables.cells.element(boundBy: 1).tap()
        app.buttons[creditCardsStaticTexts.ViewCreditCard.edit].tap()
        tapCardNr()
        pressDelete()
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
        for i in 1...3 {
            mozWaitForElementToExist(app.tables.cells.element(boundBy: i).buttons.firstMatch)
            XCTAssertTrue(app.tables.cells.element(boundBy: i).buttons.elementContainingText(cardsInfo[i-1][0]).exists,
                          "\(cardsInfo[i-1][0]) info is not displayed")
            XCTAssertTrue(app.tables.cells.element(boundBy: i).buttons[cardsInfo[i-1][1]].exists,
                          "\(cardsInfo[i-1][1]) info is not displayed")
            XCTAssertTrue(app.tables.cells.element(boundBy: i).buttons[cardsInfo[i-1][2]].exists,
                          "\(cardsInfo[i-1][2]) info is not displayed")
        }
        // reachAutofillWebsite() not working on iOS 15
        if #available(iOS 16, *) {
            // Reach used saved cards autofill website
            reachAutofillWebsite()
            // Any saved card can be selected/used from the autofill menu
            app.scrollViews.otherElements.tables.cells.firstMatch.tap()
            validateAutofillCardInfo(cardNr: "2720 9943 2658 1252", expirationNr: "05 / 40", name: "Test")
            dismissSavedCardsPrompt()
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
            dismissSavedCardsPrompt()
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
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306977
    func testErrorStatesCreditCards() {
        // Go to a saved credit card and delete the name
        addCardAndReachViewCardPage()
        app.buttons[creditCardsStaticTexts.ViewCreditCard.edit].tap()
        let saveButton = app.buttons[creditCardsStaticTexts.AddCreditCard.save]
        tapCardName()
        app.keyboards.keys["delete"].press(forDuration: 1.5)
        tapCardNr()
        // Error message is displayed
        mozWaitForElementToExist(app.otherElements.staticTexts["Add a name"])
        mozWaitForElementToExist(saveButton)
        XCTAssertFalse(saveButton.isEnabled)
        // Fill in the name on card, and delete the credit card number
        tapCardName()
        typeCardName(name: "Test")
        tapCardNr()
        mozWaitForElementToNotExist(app.otherElements.staticTexts["Add a name"])
        mozWaitForElementToExist(saveButton)
        XCTAssertTrue(saveButton.isEnabled)
        pressDelete()
        tapCardName()
        // Error message is displayed
        mozWaitForElementToExist(app.otherElements.staticTexts["Enter a valid card number"])
        mozWaitForElementToExist(saveButton)
        XCTAssertFalse(saveButton.isEnabled)
        // Fill in the name on the card and the credit card number, delete the Expiration date
        tapCardNr()
        typeCardNr(cardNo: cards[0])
        tapExpiration()
        mozWaitForElementToNotExist(app.otherElements.staticTexts["Enter a valid card number"])
        mozWaitForElementToExist(saveButton)
        XCTAssertTrue(saveButton.isEnabled)
        pressDelete()
        tapCardNr()
        // Error message is displayed
        mozWaitForElementToExist(app.otherElements.staticTexts["Enter a valid expiration date"])
        mozWaitForElementToExist(saveButton)
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
    func testSaveThisCardPrompt() {
        navigator.goto(NewTabScreen)
        navigator.openURL("https://checkout.stripe.dev/preview")
        waitUntilPageLoad()
        app.swipeUp()
        // Fill in the form with the card details of a new (unsaved) credit card.
        fillCardDetailsOnWebsite(cardNr: cards[1], expirationDate: "0540", nameOnCard: "Test")
        // Tap on "Pay"
        let payButton = app.webViews["contentView"].webViews.buttons["Pay"]
        if iPad() {
            app.swipeUp()
        }
        payButton.tapOnApp()
        // Securely save this card prompt is displayed
        mozWaitForElementToExist(app.staticTexts["Securely save this card?"])
        mozWaitForElementToExist(app.buttons["Save"])
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.SaveCardPrompt.Prompt.closeButton])
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
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.savedCards])
        mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons.elementContainingText("1111"))
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
        let payButton = app.webViews["contentView"].webViews.buttons["Pay"]
        if iPad() {
            app.swipeUp()
        }
        payButton.tapOnApp()
        // The "Update this card?" prompt is displayed.
        // The prompt contains two buttons: "Save" and "x".
        mozWaitForElementToExist(app.staticTexts["Update card?"])
        mozWaitForElementToExist(app.buttons["Save"])
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.SaveCardPrompt.Prompt.closeButton])
        // Tapping 'x' will dismiss the prompt
        app.buttons[AccessibilityIdentifiers.SaveCardPrompt.Prompt.closeButton].tap()
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
        for i in cardDetails {
            mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons[i])
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
        mozWaitForElementToExist(addCardButton)
        addCardButton.tap()
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
        let cardNumber = app.webViews["contentView"].webViews.textFields["Card number"]
        let expiration = app.webViews["contentView"].webViews.textFields["Expiration"]
        let name = app.webViews["contentView"].webViews.textFields["Full name on card"]
        let email = app.webViews["contentView"].webViews.textFields.element(boundBy: 0)
        let cvc = app.webViews["contentView"].webViews.textFields["CVC"]
        let zip = app.webViews["contentView"].webViews.textFields["ZIP"]
        mozWaitForElementToExist(email)
        email.tapOnApp()
        var nrOfRetries = 3
        while email.value(forKey: "hasKeyboardFocus") as? Bool == false && nrOfRetries > 0 {
            swipeUp(nrOfSwipes: 1)
            email.tapOnApp()
            nrOfRetries -= 1
        }
        email.typeText("foo@mozilla.org")
        mozWaitForElementToExist(cardNumber)
        if skipFillInfo == false {
            cardNumber.tapOnApp()
            cardNumber.typeText(cardNr)
            mozWaitForElementToExist(expiration)
            dismissSavedCardsPrompt()
            expiration.tapOnApp()
            expiration.typeText(expirationDate)
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
            app.keyboards.keys["delete"].press(forDuration: 2.2)
        } else {
            app.keyboards.keys["Delete"].press(forDuration: 2.2)
        }
    }

    func tapCardName() {
        initCardFields()
        nameOnCard.tap()
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
        cardNr.typeText(cardNo)
    }

    func typeExpirationDate(exprDate: String) {
        initCardFields()
        expiration.typeText(exprDate)
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
        waitForTabsButton()
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
        mozWaitForElementToExist(app.navigationBars[creditCardsStaticTexts.ViewCreditCard.viewCard])
        mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons.elementContainingText("1252"))
        let cardDetails = ["Test", "05 / 40"]
        for i in cardDetails {
            if #available(iOS 16, *) {
                XCTAssertTrue(app.buttons[i].exists, "\(i) does not exists")
            } else {
                mozWaitForElementToExist(app.staticTexts[i])
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
        mozWaitForElementToExist(saveButton)
        if !saveButton.isEnabled {
            retryOnCardNumber(cardNumber: cardNumber)
            mozWaitForElementToExist(expiration)
            expiration.typeText(expirationDate)
            retryExpirationNumber(expirationDate: expirationDate)
            mozWaitForElementToExist(saveButton)
        }
        XCTAssertTrue(saveButton.isEnabled, "Save button is disabled")
        saveButton.tap()
    }

    private func retryOnCardNumber(cardNumber: String) {
        tapCardNr()
        app.keyboards.keys["Delete"].press(forDuration: 2.2)
        typeCardNr(cardNo: cardNumber)
        tapExpiration()
    }

    private func retryExpirationNumber(expirationDate: String) {
        app.keyboards.keys["Delete"].press(forDuration: 1.5)
        typeExpirationDate(exprDate: expirationDate)
    }
}
