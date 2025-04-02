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
        app.buttons[creditCardsStaticTexts.ViewCreditCard.edit].waitAndTap()
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
        cancelButton.waitAndTap()
        // The prompt is dismissed, the "Edit card" page is displayed
        mozWaitForElementToNotExist(removeThisCardAlert)
        mozWaitForElementToExist(app.navigationBars[creditCardsStaticTexts.EditCreditCard.editCreditCard])
        // Tap again on the "Remove card" button
        app.buttons[creditCardsStaticTexts.EditCreditCard.removeCard].waitAndTap()
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
        app.navigationBars.buttons[creditCardsStaticTexts.ViewCreditCard.close].waitAndTap()
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
        app.buttons[manageCards].waitAndTap()
        if #available(iOS 17, *) {
            unlockLoginsView()
        } else {
            // There is a delay in iOS 16 in showing the secure text field
            sleep(2)
            unlockLoginsView()
        }
        // The user is redirected to the "Credit cards" section in Settings
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        // Tap the back button on the Credit cards page
        app.buttons["Settings"].waitAndTap()
        navigator.nowAt(SettingsScreen)
        app.buttons["Done"].waitAndTap()
        // The user is returned to the webpage
        mozWaitForElementToExist(app.staticTexts["Form Autofill Demo: Basic Credit Card @autocomplete"])
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
            saveAndFillPaymentMethodsSwitch.waitAndTap()
        }
        XCTAssertEqual(saveAndFillPaymentMethodsSwitch.value! as? String, "0")
        app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard].waitAndTap()
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
            app.buttons["KeyboardAccessory.doneButton"].waitAndTap()
        } else {
            XCTFail("Keyboard did not appear within \(timeout) seconds")
        }
        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        // Enable the "Save and Fill Payment Methods" toggle
        app.switches.element(boundBy: 1).waitAndTap()
        XCTAssertEqual(saveAndFillPaymentMethodsSwitch.value! as? String, "1")
        navigator.goto(NewTabScreen)
        cardNumber.waitAndTap()
        // The autofill option (Use saved card prompt) is displayed
        if !app.buttons[useSavedCard].waitForExistence(timeout: 3) {
            app.webViews["Web content"].staticTexts["Card Number:"].waitAndTap()
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
        // The credit card's number and name are imported correctly on the designated fields
        waitUntilPageLoad()
        if #available(iOS 18, *) {
            XCTAssertEqual(app.textFields["Card Number:"].value! as? String, "2720994326581252")
            XCTAssertEqual(app.textFields["Expiration month:"].value! as? String, "05")
            XCTAssertEqual(app.textFields["Expiration year:"].value! as? String, "2040")
            XCTAssertEqual(app.textFields["Name:"].value! as? String, "Test")
        } else {
            XCTAssertEqual(app.textFields.element(boundBy: 1).value! as? String, "2720994326581252")
            XCTAssertEqual(app.textFields.element(boundBy: 2).value! as? String, "05")
            XCTAssertEqual(app.textFields.element(boundBy: 3).value! as? String, "2040")
            // Cannot find identifier for element Name on iOS 16
            if #available(iOS 17, *) {
                XCTAssertEqual(app.textFields["Name: Test"].value! as? String, "Test")
            }
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306976
    func testVerifyThatTheEditedCreditCardIsSaved() throws {
        if #unavailable(iOS 17) {
            throw XCTSkip("testVerifyThatTheEditedCreditCardIsSaved() does not work on iOS 15 and iOS 16")
        }
        // Go to a saved credit card and change the name on card
        let updatedName = "Test2"
        addCardAndReachViewCardPage()
        app.buttons[creditCardsStaticTexts.ViewCreditCard.edit].waitAndTap()
        tapCardName()
        nameOnCard.clearText()
        typeCardName(name: updatedName)
        app.buttons["Save"].waitAndTap()
        // The name of the card is saved without issues
        mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons[updatedName])
        // Go to an saved credit card and change the credit card number
        app.tables.cells.element(boundBy: 1).waitAndTap()
        app.buttons[creditCardsStaticTexts.ViewCreditCard.edit].waitAndTap()
        tapCardNr()
        clearTextUntilEmpty(element: cardNr)
        typeCardNr(cardNo: cards[1])
        app.buttons["Save"].waitAndTap()
        // The credit card number is saved without issues
        mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons.elementContainingText("1111"))
        // Reach autofill website
        if #available(iOS 16, *) {
            reachAutofillWebsite()
            app.scrollViews.otherElements.tables.cells.firstMatch.tapOnApp()
            // The credit card's number and name are imported correctly on the designated fields
            validateAutofillCardInfo(cardNr: "4111111111111111", expYear: "2040", expMonth: "05", name: updatedName)
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
        app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard].waitAndTap()
        addCreditCard(name: "Test", cardNumber: cards[0], expirationDate: "0540")
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard].waitAndTap()
        addCreditCard(name: "Test2", cardNumber: cards[1], expirationDate: "0640")
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard].waitAndTap()
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
            app.scrollViews.otherElements.tables.cells.firstMatch.waitAndTap()
            validateAutofillCardInfo(cardNr: "2720994326581252", expYear: "2040", expMonth: "05", name: "Test")
            if #available(iOS 18, *) {
                app.textFields["Name:"].waitAndTap()
            } else {
                app.textFields.element(boundBy: 3).waitAndTap()
            }
            app.buttons[useSavedCard].waitAndTap()
            unlockLoginsView()
            mozWaitForElementToExist(app.staticTexts["Use saved card"])
            app.scrollViews.otherElements.tables.cells["creditCardCell_1"].waitAndTap()
            validateAutofillCardInfo(cardNr: "4111111111111111", expYear: "2040", expMonth: "06", name: "Test2")
            if #available(iOS 18, *) {
                app.textFields["Name:"].waitAndTap()
                if !app.buttons[useSavedCard].exists {
                    app.textFields["Card Number:"].waitAndTap()
                }
            } else {
                app.textFields.element(boundBy: 2).waitAndTap()
                if !app.buttons[useSavedCard].exists {
                    app.textFields.element(boundBy: 2).waitAndTap()
                }
            }
            app.buttons[useSavedCard].waitAndTap()
            unlockLoginsView()
            mozWaitForElementToExist(app.staticTexts["Use saved card"])
            let creditCardCell2 = app.scrollViews.otherElements.tables.cells["creditCardCell_2"]
            mozWaitForElementToExist(creditCardCell2)
            creditCardCell2.swipeUp()
            creditCardCell2.waitAndTap()
            validateAutofillCardInfo(cardNr: "5346755600299631", expYear: "2040", expMonth: "07", name: "Test3")
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306977
    func testErrorStatesCreditCards() {
        // Go to a saved credit card and delete the name
        addCardAndReachViewCardPage()
        app.buttons[creditCardsStaticTexts.ViewCreditCard.edit].waitAndTap()
        let saveButton = app.buttons[creditCardsStaticTexts.AddCreditCard.save]
        tapCardName()
        clearTextUntilEmpty(element: nameOnCard)
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
        clearTextUntilEmpty(element: cardNr)
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
        clearTextUntilEmpty(element: expiration)
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
        saveButton.waitAndTap()
        // The credit card is saved
        let cardsInfo = ["Test", "5/40"]
        mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons.elementContainingText("1252"))
        for i in cardsInfo {
            mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons[i])
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306979
    func testSaveThisCardPrompt() throws {
        if #unavailable(iOS 17) {
            throw XCTSkip("testSaveThisCardPrompt() does not work on iOS 15 and 16")
        }
        navigator.goto(NewTabScreen)
        navigator.openURL("https://mozilla.github.io/form-fill-examples/basic_cc.html")
        waitUntilPageLoad()
        // Fill in the form with the card details of a new (unsaved) credit card.
        fillCardDetailsOnWebsite(fillNewInfo: true)
        // Tap on "Submit"
        app.buttons["Submit"].waitAndTap()
        // Securely save this card prompt is displayed
        waitForElementsToExist(
            [
                app.staticTexts["Securely save this card?"],
                app.buttons["Save"],
                app.buttons[AccessibilityIdentifiers.SaveCardPrompt.Prompt.closeButton]
            ]
        )
        // Tapping 'x' will dismiss the prompt
        app.buttons[AccessibilityIdentifiers.SaveCardPrompt.Prompt.closeButton].waitAndTap()
        mozWaitForElementToNotExist(app.staticTexts["Securely save this card?"])
        // Go to the Settings --> Payment methods
        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        // The credit card is not saved
        mozWaitForElementToExist(app.staticTexts["Save Cards to Firefox"])
        mozWaitForElementToNotExist(app.tables.cells.element(boundBy: 1))
        // Repeat above steps and tap 'Save'
        navigator.goto(NewTabScreen)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.goto(NewTabScreen)
        navigator.openURL("https://mozilla.github.io/form-fill-examples/basic_cc.html")
        waitUntilPageLoad()
        // Fill in the form with the card details of a new (unsaved) credit card.
        fillCardDetailsOnWebsite(fillNewInfo: true)
        app.buttons["Submit"].waitAndTap()
        app.buttons["Save"].waitAndTap()
        // The prompt is dismissed. And a toast message is displayed: "New card saved"
        mozWaitForElementToExist(app.staticTexts["New Card Saved"])
        mozWaitForElementToNotExist(app.staticTexts["Securely save this card?"])
        // Go to the Settings --> Payment methods
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
        if #unavailable(iOS 17) {
            throw XCTSkip("addCreditCardAndReachAutofillWebsite() does not work on iOS 15 and 16")
        }
        // Fill in the form with the details of an already saved credit card
        addCreditCardAndReachAutofillWebsite()
        // Select the saved credit card
        selectCreditCardOnFormWebsite()
        // Modify the card details
        fillCardDetailsOnWebsite(fillNewInfo: false)
        // Tap on "Submit"
        let submitButton = app.buttons["Submit"]
        submitButton.waitAndTap()
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
        navigator.openURL("https://mozilla.github.io/form-fill-examples/basic_cc.html")
        waitUntilPageLoad()
        app.textFields["Card Number:"].waitAndTap()
        // Expand the saved card prompt
        app.buttons[useSavedCard].waitAndTap()
        unlockLoginsView()
        mozWaitForElementToExist(app.staticTexts["Use saved card"])
        // Select the saved credit card
        selectCreditCardOnFormWebsite()
        // Modify the card details
        fillCardDetailsOnWebsite(fillNewInfo: false)
        // Tap on "Submit"
        submitButton.waitAndTap()
        // The "Update this card?" prompt is displayed.
        // The prompt contains two buttons: "Save" and "x".
        mozWaitForElementToExist(app.staticTexts["Update card?"])
        // Tapping 'x' will dismiss the prompt
        app.buttons["Save"].waitAndTap()
        mozWaitForElementToNotExist(app.staticTexts["Update card?"])
        // Go to the Settings --> Payment methods
        navigator.goto(CreditCardsSettings)
        unlockLoginsView()
        // Credit cards details changed
        mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons.elementContainingText("1252"))
        cardDetails = ["Test2", "Expires", "5/40"]
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
        let nameOnCard = app.scrollViews.otherElements.tables.buttons.element(boundBy: 2)
        mozWaitForElementToExist(nameOnCard)
        var attempts = 4
        while nameOnCard.isHittable && attempts > 0 {
            nameOnCard.waitAndTap()
            attempts -= 1
        }
    }

    private func fillCardDetailsOnWebsite(fillNewInfo: Bool) {
        let name =  app.textFields.elementContainingText("Name:")
        let cardNumber = app.textFields.element(boundBy: 1)
        let expirationMonth = app.textFields.element(boundBy: 2)
        let expirationYear = app.textFields.element(boundBy: 3)
        if fillNewInfo {
            name.tapOnApp()
            name.typeText("Test")
            cardNumber.tapOnApp()
            cardNumber.typeText(cards[1])
            expirationYear.tapOnApp()
            expirationYear.typeText("2040")
            expirationMonth.tapOnApp()
            expirationMonth.typeText("05")
        } else {
            name.tapOnApp()
            name.typeText("2")
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
        cardNr.waitAndTap()
        mozWaitForElementToExist(cardNr)
    }

    func tapExpiration() {
        initCardFields()
        expiration.waitAndTap()
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

    private func validateAutofillCardInfo(cardNr: String, expYear: String, expMonth: String, name: String) {
        if #available(iOS 18, *) {
            XCTAssertEqual(app.textFields["Card Number:"].value! as? String, cardNr)
            XCTAssertEqual(app.textFields["Expiration month:"].value! as? String, expMonth)
            XCTAssertEqual(app.textFields["Expiration year:"].value! as? String, expYear)
            XCTAssertEqual(app.textFields["Name:"].value! as? String, name)
        } else {
            XCTAssertEqual(app.textFields.element(boundBy: 1).value! as? String, cardNr)
            XCTAssertEqual(app.textFields.element(boundBy: 2).value! as? String, expMonth)
            XCTAssertEqual(app.textFields.element(boundBy: 3).value! as? String, expYear)
            // Cannot find identifier for element Name on iOS 16
            if #available(iOS 17, *) {
                XCTAssertEqual(app.textFields["Name: \(name)"].value! as? String, name)
            }
        }
    }

    private func reachAutofillWebsite() {
        // Reach autofill website
        navigator.goto(NewTabScreen)
        navigator.openURL("https://mozilla.github.io/form-fill-examples/basic_cc.html")
        waitUntilPageLoad()
        app.textFields.element(boundBy: 1).waitAndTap()
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
            saveAndFillPaymentMethodsSwitch.waitAndTap()
        }
        app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard].waitAndTap()
        addCreditCard(name: "Test", cardNumber: cards[0], expirationDate: "0540")
        navigator.goto(NewTabScreen)
        navigator.openURL("https://mozilla.github.io/form-fill-examples/basic_cc.html")
        waitUntilPageLoad()
        var cardNumber = app.webViews["Web content"].textFields["Card Number:"]
        if #unavailable(iOS 17) {
            cardNumber = app.webViews["Web content"].staticTexts["Card Number:"]
        }
        mozWaitForElementToExist(cardNumber)
        cardNumber.waitAndTap()
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
        app.buttons[creditCardsStaticTexts.AutoFillCreditCard.addCard].waitAndTap()
        addCreditCard(name: "Test", cardNumber: cards[0], expirationDate: "0540")
        // Tap on a saved card
        mozWaitForElementToExist(app.staticTexts[creditCardsStaticTexts.AutoFillCreditCard.autoFillCreditCards])
        app.tables.cells.element(boundBy: 1).waitAndTap()
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

    private func clearTextUntilEmpty(element: XCUIElement) {
        var nrOfTries = 3
        while !element.isEmpty && nrOfTries > 0 {
            element.clearText()
            nrOfTries -= 1
        }
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

    var isEmpty: Bool {
        return (self.value as? String)?.isEmpty ?? true
    }
}
