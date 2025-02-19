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
        if iPad() {
            app.collectionViews.buttons.element(boundBy: 0).tapWithRetry()
        } else {
            app.collectionViews.buttons.element(boundBy: 1).tapWithRetry()
        }
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
        if iPad() {
            app.collectionViews.buttons.element(boundBy: 0).tapWithRetry()
        } else {
            app.collectionViews.buttons.element(boundBy: 1).tapWithRetry()
        }
        // Update the all addresses fields
        tapEdit()
        // Remove address
        removeAddress()
        // The "Address Removed" toast message is displayed
        mozWaitForElementToExist(app.staticTexts[removedAddressTxt])
    }

    private func updateFieldsWithWithoutState(updateCountry: Bool, isPostalCode: Bool) {
        // Choose to update an address
        if iPad() {
            app.collectionViews.buttons.element(boundBy: 0).tapWithRetry()
        } else {
            app.collectionViews.buttons.element(boundBy: 1).tapWithRetry()
        }
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
        mozWaitForElementToExist(app.navigationBars[addresses.title])
        app.buttons[addresses.addAddress].waitAndTap()
        mozWaitForElementToExist(app.navigationBars[addresses.addAddress])
        if !app.staticTexts["Name"].exists {
            app.buttons["Close"].waitAndTap()
            app.buttons[addresses.addAddress].waitAndTap()
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
        if iPad() {
            app.collectionViews.buttons.element(boundBy: 0).tapWithRetry()
        } else {
            app.collectionViews.buttons.element(boundBy: 1).tapWithRetry()
        }
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
        if iPad() {
            app.collectionViews.buttons.element(boundBy: 0).tapWithRetry()
        } else {
            app.collectionViews.buttons.element(boundBy: 1).tapWithRetry()
        }
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
        if iPad() {
            app.collectionViews.buttons.element(boundBy: 0).tapWithRetry()
        } else {
            app.collectionViews.buttons.element(boundBy: 1).tapWithRetry()
        }
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
        app.staticTexts["Name"].waitAndTap()
        if updateText {
            clearText()
        }
        app.typeText(name)
    }

    private func typeOrganization(organization: String, updateText: Bool = false) {
        app.staticTexts["Organization"].waitAndTap()
        if updateText {
            clearText()
        }
        app.typeText(organization)
    }

    private func typeStreetAddress(street: String, updateText: Bool = false) {
        app.staticTexts["Street Address"].waitAndTap()
        if updateText {
            clearText()
        }
        app.typeText(street)
    }

    private func typeCity(city: String, updateText: Bool = false) {
        app.staticTexts["City"].waitAndTap()
        if updateText {
            clearText()
        }
        app.typeText(city)
    }

    private func selectCountry(country: String) {
        app.staticTexts["Country or Region"].waitAndTap()
        app.buttons[country].waitAndTap()
    }

    private func typeZIP(zip: String, updateText: Bool = false, isPostalCode: Bool = false) {
        if isPostalCode {
            scrollToElement(app.staticTexts["Postal Code"])
            app.staticTexts["Postal Code"].waitAndTap()
        } else {
            scrollToElement(app.staticTexts["ZIP Code"])
            app.staticTexts["ZIP Code"].waitAndTap()
        }
        if updateText {
            clearText()
        }
        app.typeText(zip)
    }

    private func typePhone(phone: String, updateText: Bool = false) {
        if app.buttons["Done"].isHittable {
            app.buttons["Done"].waitAndTap()
        }
        app.staticTexts["Phone"].tapOnApp()
        if updateText {
            clearText(isPhoneNumber: true)
        }
        app.typeText(phone)
    }

    private func typeEmail(email: String, updateText: Bool = false) {
        scrollToElement(app.staticTexts["Email"])
        app.staticTexts["Email"].waitAndTap()
        if updateText {
            clearText()
        }
        app.typeText(email)
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
