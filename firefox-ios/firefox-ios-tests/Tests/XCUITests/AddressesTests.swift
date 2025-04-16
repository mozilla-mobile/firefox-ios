// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class AddressesTests: BaseTestCase {
    let addressSavedTxt = "Address Saved"
    let savedAddressesTxt = "SAVED ADDRESSES"
    let removedAddressTxt = "Address Removed"

    override func setUp() {
        super.setUp()
        if #available(iOS 16, *) {
            if !name.contains("testAddressOptionIsAvailableInSettingsMenu") {
                navigator.nowAt(NewTabScreen)
                waitForTabsButton()
                navigator.goto(AddressesSettings)
                // Making sure "Save and Fill Addresses" toggle is on
                if (app.switches.element(boundBy: 1).value as? String) == "0" {
                    app.switches.element(boundBy: 1).waitAndTap()
                }
                navigator.goto(NewTabScreen)
            }
        }
    }

    override func tearDown() {
        if name.contains("testAddressOptionIsAvailableInSettingsMenu") {
            switchThemeToDarkOrLight(theme: "Light")
            XCUIDevice.shared.orientation = .portrait
        }
        app.terminate()
        super.tearDown()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618637
    // Smoketest
    func testAddNewAddressAllFieldsFilled() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        reachAddNewAddressScreen()
        // Enter valid date for all fields
        addNewAddress()
        tapSave()
        // The "Address saved" toast message is displayed
        mozWaitForElementToExist(app.staticTexts[addressSavedTxt])
        // The address is saved
        mozWaitForElementToExist(app.staticTexts[savedAddressesTxt])
        let addressInfo = ["Test", "test address", "city test, AL, 123456"]
        for i in addressInfo {
            mozWaitForElementToExist(app.staticTexts[i])
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618638
    func testAddNewAddressNameFilled() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        reachAddNewAddressScreen()
        // Enter a valid date for Full Name and press save
        typeName(name: "Test")
        tapSave()
        // The "Address saved" toast message is displayed
        mozWaitForElementToExist(app.staticTexts[addressSavedTxt])
        // The address is saved
        mozWaitForElementToExist(app.staticTexts[savedAddressesTxt])
        mozWaitForElementToExist(app.staticTexts["Test"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618639
    func testAddNewAddressOrganizationFilled()  throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        reachAddNewAddressScreen()
        // Enter a valid date for Full Name and press save
        typeOrganization(organization: "organization test")
        tapSave()
        // The "Address saved" toast message is displayed
        mozWaitForElementToExist(app.staticTexts[addressSavedTxt])
        // The address is saved
        mozWaitForElementToExist(app.staticTexts[savedAddressesTxt])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618640
    func testAddNewAddressStreetAddressFilled() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        reachAddNewAddressScreen()
        // Enter a valid date for Full Name and press save
        typeStreetAddress(street: "test address")
        tapSave()
        // The "Address saved" toast message is displayed
        mozWaitForElementToExist(app.staticTexts[addressSavedTxt])
        // The address is saved
        mozWaitForElementToExist(app.staticTexts[savedAddressesTxt])
        mozWaitForElementToExist(app.staticTexts["test address"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618641
    func testAddNewAddressCityFilled() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        reachAddNewAddressScreen()
        // Enter a valid date for Full Name and press save
        typeCity(city: "city test")
        tapSave()
        // The "Address saved" toast message is displayed
        mozWaitForElementToExist(app.staticTexts[addressSavedTxt])
        // The address is saved
        mozWaitForElementToExist(app.staticTexts[savedAddressesTxt])
        mozWaitForElementToExist(app.staticTexts["city test, AL"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618642
    func testAddNewAddressPostalCodeFilled() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        reachAddNewAddressScreen()
        // Enter a valid date for Full Name and press save
        typeZIP(zip: "123456")
        tapSave()
        // The "Address saved" toast message is displayed
        mozWaitForElementToExist(app.staticTexts[addressSavedTxt])
        // The address is saved
        mozWaitForElementToExist(app.staticTexts[savedAddressesTxt])
        mozWaitForElementToExist(app.staticTexts["AL, 123456"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618644
    func testAddNewAddressPhoneFilled() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        reachAddNewAddressScreen()
        // Enter a valid date for Full Name and press save
        typePhone(phone: "01234567")
        tapSave()
        // The "Address saved" toast message is displayed
        mozWaitForElementToExist(app.staticTexts[addressSavedTxt])
        // The address is saved
        mozWaitForElementToExist(app.staticTexts[savedAddressesTxt])
        mozWaitForElementToExist(app.staticTexts["AL"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618645
    func testAddNewAddressEmailFilled()  throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        reachAddNewAddressScreen()
        // Enter a valid date for Full Name and press save
        typeEmail(email: "test@mozilla.com")
        tapSave()
        // The "Address saved" toast message is displayed
        mozWaitForElementToExist(app.staticTexts[addressSavedTxt])
        // The address is saved
        mozWaitForElementToExist(app.staticTexts[savedAddressesTxt])
        mozWaitForElementToExist(app.staticTexts["AL"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618643
    func testAddNewAddressCountry() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        reachAddNewAddressScreen()
        // Enter a valid date for Country and press save
        selectCountry(country: "United Kingdom")
        tapSave()
        // The "Address saved" toast message is displayed
        mozWaitForElementToExist(app.staticTexts[addressSavedTxt])
        // The address is saved
        mozWaitForElementToExist(app.staticTexts[savedAddressesTxt])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618654
    func testUpdateAllAddressFields() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        reachAddNewAddressScreen()
        addNewAddress()
        tapSave()
        updateFieldsWithWithoutState(updateCountry: false, isPostalCode: false)
        updateFieldsWithWithoutState(updateCountry: true, isPostalCode: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618646
    func testUpdateAddressFieldName() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        updateFieldAndValidate(field: "Name", newValue: "Test2", isInfoDisplayed: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618647
    func testUpdateAddressFieldOrganization() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        updateFieldAndValidate(field: "Organization", newValue: "organization test2")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618648
    func testUpdateAddressFieldStreet() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        updateFieldAndValidate(field: "Street Address", newValue: "test address2", isInfoDisplayed: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618649
    func testUpdateAddressFieldCity() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        updateFieldAndValidate(field: "City", newValue: "test city2", isInfoDisplayed: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618650
    func testUpdateAddressFieldZIP() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        updateFieldAndValidate(field: "ZIP Code", newValue: "345678", isInfoDisplayed: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618652
    func testUpdateAddressFieldPhone() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        updateFieldAndValidate(field: "Phone", newValue: "34567890", isPhoneField: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618653
    func testUpdateAddressFieldEmail() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        updateFieldAndValidate(field: "Email", newValue: "test2@mozilla.com")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618651
    func testUpdateAddressFieldCountry() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        reachAddNewAddressScreen()
        addNewAddress()
        tapSave()
        // Choose to update an address
        app.collectionViews.cells.buttons.staticTexts.firstMatch.tapWithRetry()
        // Update field
        tapEdit()
        // Enter a valid date for Country and press save
        selectCountry(country: "United Kingdom")
        tapSave()
        // The "Address saved" toast message is displayed
        mozWaitForElementToExist(app.staticTexts[addressSavedTxt])
        // The address is saved
        mozWaitForElementToExist(app.staticTexts[savedAddressesTxt])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618655
    // Smoketest
    func testDeleteAddress() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        reachAddNewAddressScreen()
        addNewAddress()
        tapSave()
        reachEditAndRemoveAddress()
        let addressInfo = ["Test2", "test address2", "city test2, AL, 100000"]
        for i in addressInfo {
            mozWaitForElementToNotExist(app.staticTexts[i])
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2618656
    func testDeleteAllAddresses() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        reachAddNewAddressScreen()
        addNewAddress()
        tapSave()
        let addresses = AccessibilityIdentifiers.Settings.Address.Addresses.self
        app.buttons[addresses.addAddress].waitAndTap()
        addNewAddress()
        tapSave()
        reachEditAndRemoveAddress()
        reachEditAndRemoveAddress()
        let addressInfo = ["Test2", "test address2", "city test2, AL, 100000"]
        for i in addressInfo {
            mozWaitForElementToNotExist(app.staticTexts[i])
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2548204
    func testAutofillAddressesByTapingOrganizationField() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        addAddressAndReachAutofillForm(indexField: 1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2549847
    func testAutofillAddressesByTapingStateField() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        addAddressAndReachAutofillForm(indexField: 4)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2549849
    func testAutofillAddressesByTapingCountryField() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        addAddressAndReachAutofillForm(indexField: 6)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2549850
    func testAutofillAddressesByTapingEmailField() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        addAddressAndReachAutofillForm(indexField: 7)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2549852
    func testAutofillAddressesByTapingPhoneField() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        addAddressAndReachAutofillForm(indexField: 8)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2548189
    // Smoketest
    func testAutofillAddressesByTapingNameField() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        addAddressAndReachAutofillForm(indexField: 0)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2549845
    func testAutofillAddressesByTapingAddressField() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        addAddressAndReachAutofillForm(indexField: 2)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2549846
    func testAutofillAddressesByTapingCityField() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        addAddressAndReachAutofillForm(indexField: 3)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2549848
    func testAutofillAddressesByTapingPostalCodeField() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        addAddressAndReachAutofillForm(indexField: 5)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2546298
    func testToggleAddressOnOff() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        let toggleLabel = "Save and Fill Addresses, Includes phone numbers and email addresses"
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(AddressesSettings)
        // Switch the "Save and Fill Addresses" toggle OFF
        if #available(iOS 17, *) {
            mozWaitForElementToExist(app.switches[toggleLabel])
        } else {
            mozWaitForElementToExist(app.staticTexts["Save and Fill Addresses"])
        }
        app.switches.element(boundBy: 1).waitAndTap()
        // The toggle successfully turns OFF
        XCTAssertEqual(app.switches.element(boundBy: 1).value! as? String, "0")
        // Switch the "Save and Fill Addresses" toggle ON
        app.switches.element(boundBy: 1).waitAndTap()
        // The toggle successfully turns ON
        XCTAssertEqual(app.switches.element(boundBy: 1).value! as? String, "1")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2546293
    // Smoketest
    func testAddressOptionIsAvailableInSettingsMenu() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        // While in Portrait mode check for the options
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        validatePrivacyOptions()
        navigator.goto(AutofillPasswordSettings)
        validateAutofillPasswordOptions()
        // While in landscape mode check for the options
        XCUIDevice.shared.orientation = .landscapeLeft
        validateAutofillPasswordOptions()
        XCUIDevice.shared.orientation = .portrait
        // While in dark mode check for the options
        sleep(1)
        navigator.nowAt(AutofillPasswordSettings)
        navigator.goto(SettingsScreen)
        app.buttons["Done"].waitAndTap()
        // Adding sleep to avoid loading screen on bitrise
        sleep(3)
        switchThemeToDarkOrLight(theme: "Dark")
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        navigator.goto(AutofillPasswordSettings)
        validateAutofillPasswordOptions()
        // While in light mode check for the options
        navigator.nowAt(AutofillPasswordSettings)
        navigator.goto(SettingsScreen)
        app.buttons["Done"].waitAndTap()
        // Adding sleep to avoid loading screen on bitrise
        sleep(3)
        switchThemeToDarkOrLight(theme: "Light")
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        navigator.goto(AutofillPasswordSettings)
        validateAutofillPasswordOptions()
        navigator.nowAt(AutofillPasswordSettings)
        navigator.goto(SettingsScreen)
        navigator.nowAt(SettingsScreen)
        navigator.goto(NewTabScreen)
        // Go to a webpage, and select night mode on and off, check options
        navigator.openURL(path(forTestPage: "test-example.html"))
        waitUntilPageLoad()
        validateNightModeOnOff()
        navigator.nowAt(SettingsScreen)
        navigator.goto(BrowserTab)
        validateNightModeOnOff()
        navigator.nowAt(SettingsScreen)
        navigator.goto(BrowserTab)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2549853
    // Smoketest
    func testAutofillOptionNotAvailableToggleOFF() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        reachAddNewAddressScreen()
        addNewAddress()
        tapSave()
        app.switches.element(boundBy: 1).waitAndTap()
        navigator.goto(NewTabScreen)
        navigator.openURL("https://mozilla.github.io/form-fill-examples/basic.html")
        // Using indexes to tap on text fields to comodate with iOS 16 OS
        for index in 0...8 {
            app.webViews.textFields.element(boundBy: index).waitAndTap()
            // The option to open saved Addresses is not available
            let addressAutofillButton = AccessibilityIdentifiers.Browser.KeyboardAccessory.addressAutofillButton
            mozWaitForElementToNotExist(app.buttons[addressAutofillButton])
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2667453
    // Smoketest
    func testRedirectToSettingsByTappingManageAddresses() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        reachAddNewAddressScreen()
        addNewAddress()
        tapSave()
        navigator.goto(NewTabScreen)
        navigator.openURL("https://mozilla.github.io/form-fill-examples/basic.html")
        app.webViews.textFields.element(boundBy: 1).waitAndTap()
        let addressAutofillButton = AccessibilityIdentifiers.Browser.KeyboardAccessory.addressAutofillButton
        let manageAddresses = AccessibilityIdentifiers.Autofill.footerPrimaryAction
        app.buttons[addressAutofillButton].waitAndTap()
        // Tap the "Manage addresses" link
        app.otherElements.buttons[manageAddresses].waitAndTap()
        // User is redirected to the Settings -> addresses menu
        let addresses = AccessibilityIdentifiers.Settings.Address.Addresses.self
        mozWaitForElementToExist(app.navigationBars[addresses.title])
    }

    private func validateNightModeOnOff() {
        navigator.performAction(Action.ToggleNightMode)
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        navigator.goto(SettingsScreen)
        validatePrivacyOptions()
    }

    private func validatePrivacyOptions() {
        let table = app.tables.element(boundBy: 0)
        let settingsQuery = AccessibilityIdentifiers.Settings.self
        waitForElementsToExist(
            [
                table.cells[settingsQuery.AutofillsPasswords.title],
                table.cells[settingsQuery.ClearData.title],
                app.switches[settingsQuery.ClosePrivateTabs.title],
                table.cells[settingsQuery.ContentBlocker.title],
                table.cells[settingsQuery.Notifications.title],
                table.cells[settingsQuery.PrivacyPolicy.title]
            ]
        )
    }

    private func validateAutofillPasswordOptions() {
        let table = app.tables.element(boundBy: 0)
        let settingsQuery = AccessibilityIdentifiers.Settings.self
        waitForElementsToExist(
            [
                table.cells[settingsQuery.Logins.title],
                table.cells[settingsQuery.CreditCards.title],
                table.cells[settingsQuery.Address.title]
            ]
        )
    }

    private func addAddressAndReachAutofillForm(indexField: Int) {
        reachAddNewAddressScreen()
        addNewAddress()
        tapSave()
        navigator.goto(NewTabScreen)
        navigator.openURL("https://mozilla.github.io/form-fill-examples/basic.html")
        // Using indexes to tap on text fields to comodate with iOS 16 OS
        app.webViews.textFields.element(boundBy: indexField).waitAndTap()
        // The option to open saved Addresses is available
        let addressAutofillButton = AccessibilityIdentifiers.Browser.KeyboardAccessory.addressAutofillButton
        mozWaitForElementToExist(app.buttons[addressAutofillButton])
        app.buttons[addressAutofillButton].waitAndTap()
        // Choose the address added
        app.otherElements.buttons.elementContainingText("Address").waitAndTap()
        // All fields are correctly autofilled
        validateAutofillAddressInfo()
    }

    private func validateAutofillAddressInfo() {
        // Using indexes on text fields to comodate with iOS 16 OS
        let addressInfo = ["Test", "organization test", "test address", "city test", "AL",
                           "123456", "US", "test@mozilla.com", "01234567"]
        for index in 0...addressInfo.count - 1 {
            XCTAssertEqual(app.webViews.textFields.element(boundBy: index).value! as? String, addressInfo[index])
        }
    }

    private func reachEditAndRemoveAddress() {
        app.collectionViews.cells.buttons.staticTexts.firstMatch.tapWithRetry()
        // Update the all addresses fields
        tapEdit()
        // Remove address
        removeAddress()
        // The "Address Removed" toast message is displayed
        mozWaitForElementToExist(app.staticTexts[removedAddressTxt])
    }

    private func updateFieldsWithWithoutState(updateCountry: Bool, isPostalCode: Bool) {
        // Choose to update an address
        app.collectionViews.cells.buttons.staticTexts.firstMatch.tapWithRetry()
        // Update the all addresses fields
        tapEdit()
        updateAddress(updateCountry: updateCountry, isPostalCode: isPostalCode)
        tapSave()
        // The "Address saved" toast message is displayed
        mozWaitForElementToExist(app.staticTexts[addressSavedTxt])
        // The address is saved
        mozWaitForElementToExist(app.staticTexts[savedAddressesTxt])
        if updateCountry {
            let addressInfo = ["Test2", "test address2", "city test2, 100000"]
            for index in addressInfo {
                mozWaitForElementToExist(app.staticTexts[index])
            }
        } else {
            let addressInfo = ["Test2", "test address2", "city test2, AL, 100000"]
            for index in addressInfo {
                mozWaitForElementToExist(app.staticTexts[index])
            }
        }
    }

    private func reachAddNewAddressScreen() {
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(AddressesSettings)
        let addresses = AccessibilityIdentifiers.Settings.Address.Addresses.self
        sleep(4)
        if !app.navigationBars[addresses.title].exists {
            navigator.goto(AddressesSettings)
        }
        mozWaitElementHittable(element: app.navigationBars[addresses.title], timeout: TIMEOUT)
        app.buttons[addresses.addAddress].waitAndTap()
        mozWaitForElementToExist(app.navigationBars[addresses.addAddress])
        var attempts = 3
        while !app.staticTexts["Name"].exists && attempts > 0 {
            app.buttons["Close"].tapIfExists()
            app.buttons[addresses.addAddress].tapIfExists()
            attempts -= 1
        }
        mozWaitForElementToExist(app.staticTexts["Name"])
    }

    private func addNewAddress() {
        typeName(name: "Test")
        typeOrganization(organization: "organization test")
        typeStreetAddress(street: "test address")
        typeCity(city: "city test")
        typeZIP(zip: "123456")
        typePhone(phone: "01234567")
        typeEmail(email: "test@mozilla.com")
    }

    private func updateAddress(updateCountry: Bool, isPostalCode: Bool) {
        typeName(name: "Test2", updateText: true)
        typeOrganization(organization: "organization test2", updateText: true)
        typeStreetAddress(street: "test address2", updateText: true)
        typeCity(city: "city test2", updateText: true)
        if updateCountry {
            selectCountry(country: "United Kingdom")
        }
        typeZIP(zip: "100000", updateText: true, isPostalCode: isPostalCode)
        typePhone(phone: "1111111", updateText: true)
        typeEmail(email: "test2@mozilla.com", updateText: true)
    }

    private func updateFieldAndValidate(field: String, newValue: String, isInfoDisplayed: Bool = false,
                                        isPhoneField: Bool = false) {
        reachAddNewAddressScreen()
        addNewAddress()
        tapSave()
        // Choose to update an address
        app.collectionViews.cells.buttons.staticTexts.firstMatch.tapWithRetry()
        // Update field
        tapEdit()
        app.staticTexts[field].waitAndTap()
        if isPhoneField {
            clearText(isPhoneNumber: true)
        } else {
            clearText()
        }
        app.typeText(newValue)
        tapSave()
        // The "Address saved" toast message is displayed
        mozWaitForElementToExist(app.staticTexts[addressSavedTxt])
        // The address is saved
        mozWaitForElementToExist(app.staticTexts[savedAddressesTxt])
        if isInfoDisplayed {
            XCTAssertTrue(app.staticTexts.elementContainingText(newValue).exists, "\(newValue) is not displayed")
        }
        app.collectionViews.cells.buttons.staticTexts.firstMatch.tapWithRetry()
        // Update field
        tapEdit()
        app.staticTexts[field].waitAndTap()
        if isPhoneField {
            clearText(isPhoneNumber: true)
        } else {
            clearText()
        }
        tapSave()
        // The "Address saved" toast message is displayed
        mozWaitForElementToExist(app.staticTexts[addressSavedTxt])
        // The address is saved
        mozWaitForElementToExist(app.staticTexts[savedAddressesTxt])
        XCTAssertFalse(app.staticTexts.elementContainingText(newValue).exists, "\(newValue) is displayed")
        app.collectionViews.cells.buttons.staticTexts.firstMatch.tapWithRetry()
        tapEdit()
        app.staticTexts[field].waitAndTap()
        app.typeText(newValue)
        tapSave()
        // The "Address saved" toast message is displayed
        mozWaitForElementToExist(app.staticTexts[addressSavedTxt])
        // The address is saved
        mozWaitForElementToExist(app.staticTexts[savedAddressesTxt])
        if isInfoDisplayed {
            XCTAssertTrue(app.staticTexts.elementContainingText(newValue).exists, "\(newValue) is not displayed")
        }
    }

    private func typeName(name: String, updateText: Bool = false) {
        let nameField = app.staticTexts["Name"]
        app.staticTexts["Name"].waitAndTap()
        if updateText {
            clearText()
        }
        retryTypingText(element: nameField, textField: name)
    }

    private func typeOrganization(organization: String, updateText: Bool = false) {
        let organizationField = app.staticTexts["Organization"]
        organizationField.waitAndTap()
        if updateText {
            clearText()
        }
        retryTypingText(element: organizationField, textField: organization)
    }

    private func typeStreetAddress(street: String, updateText: Bool = false) {
        let addressField = app.staticTexts["Street Address"]
        addressField.waitAndTap()
        if updateText {
            clearText()
        }
        retryTypingText(element: addressField, textField: street)
    }

    private func typeCity(city: String, updateText: Bool = false) {
        let cityField = app.staticTexts["City"]
        cityField.waitAndTap()
        if updateText {
            clearText()
        }
        retryTypingText(element: cityField, textField: city)
    }

    private func selectCountry(country: String) {
        app.staticTexts["Country or Region"].waitAndTap()
        app.buttons[country].waitAndTap()
    }

    private func typeZIP(zip: String, updateText: Bool = false, isPostalCode: Bool = false) {
        if isPostalCode {
            let postalCodeField = app.staticTexts["Postal Code"]
            scrollToElement(postalCodeField)
            postalCodeField.waitAndTap()
            if updateText {
                clearText()
            }
            retryTypingText(element: postalCodeField, textField: zip)
        } else {
            let zipCodeField = app.staticTexts["ZIP Code"]
            scrollToElement(zipCodeField)
            zipCodeField.waitAndTap()
            if updateText {
                clearText()
            }
            retryTypingText(element: zipCodeField, textField: zip)
        }
    }

    private func typePhone(phone: String, updateText: Bool = false) {
        let phoneField = app.staticTexts["Phone"]
        phoneField.waitAndTap()
        if updateText {
            clearText(isPhoneNumber: true)
        }
        retryTypingText(element: phoneField, textField: phone)
    }

    private func typeEmail(email: String, updateText: Bool = false) {
        let emailField = app.staticTexts["Email"]
        scrollToElement(emailField)
        emailField.waitAndTap()
        if updateText {
            clearText()
        }
        retryTypingText(element: emailField, textField: email)
    }

    private func retryTypingText(element: XCUIElement, textField: String) {
        var nrOfTaps = 5
        sleep(3)
        while !element.isVisible() && nrOfTaps > 0 {
            element.tapIfExists()
            nrOfTaps -= 1
        }
        app.typeText(textField)
    }

    private func tapSave(withRetry: Bool = false) {
        if withRetry {
            app.buttons["Save"].tapWithRetry()
        } else {
            app.buttons["Save"].waitAndTap()
        }
    }

    private func tapEdit() {
        app.buttons["Edit"].waitAndTap()
    }

    private func removeAddress() {
        app.buttons["Remove Address"].waitAndTap()
        app.buttons["Remove"].waitAndTap()
    }

    private func clearText(isPhoneNumber: Bool = false) {
        if isPhoneNumber && !iPad() {
            mozWaitForElementToExist(app.keyboards.keys["Delete"])
            app.keyboards.keys["Delete"].press(forDuration: 2.2)
        } else {
            mozWaitForElementToExist(app.keyboards.keys["delete"])
            app.keyboards.keys["delete"].press(forDuration: 2.2)
        }
    }
}
