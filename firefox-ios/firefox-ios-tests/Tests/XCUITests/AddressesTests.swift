// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class AddressesTests: BaseTestCase {
    let addressSavedTxt = "Address Saved"
    let addressUpdatedTxt = "Address Information Updated"
    let savedAddressesTxt = "SAVED ADDRESSES"
    let removedAddressTxt = "Address Removed"

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

    // https://mozilla.testrail.io/index.php?/cases/view/2618654
    // Smoketest
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

    // https://mozilla.testrail.io/index.php?/cases/view/2618655
    // Smoketest
    func testDeleteAddress() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Addresses setting is not available for iOS 15")
        }
        reachAddNewAddressScreen()
        addNewAddress()
        tapSave()
        if iPad() {
            app.collectionViews.buttons.element(boundBy: 0).waitAndTap()
        } else {
            app.collectionViews.buttons.element(boundBy: 1).waitAndTap()
        }
        // Update the all addresses fields
        tapEdit()
        // Remove address
        removeAddress()
        // The "Address Removed" toast message is displayed
        mozWaitForElementToExist(app.staticTexts[removedAddressTxt])
        let addressInfo = ["Test2", "test address2", "city test2, AL, 100000"]
        for i in addressInfo {
            mozWaitForElementToNotExist(app.staticTexts[i])
        }
    }

    private func updateFieldsWithWithoutState(updateCountry: Bool, isPostalCode: Bool) {
        // Choose to update an address
        if iPad() {
            app.collectionViews.buttons.element(boundBy: 0).waitAndTap()
        } else {
            app.collectionViews.buttons.element(boundBy: 1).waitAndTap()
        }
        // Update the all addresses fields
        tapEdit()
        updateAddress(updateCountry: updateCountry, isPostalCode: isPostalCode)
        tapSave()
        // The "Address Information Updated" toast message is displayed
        mozWaitForElementToExist(app.staticTexts[addressUpdatedTxt])
        // The address is saved
        // Update with correct toast message after https://mozilla-hub.atlassian.net/browse/FXIOS-10422 is fixed
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
        app.buttons[addresses.addAddress].tap()
        mozWaitForElementToExist(app.navigationBars[addresses.addAddress])
        if !app.staticTexts["Name"].exists {
            app.buttons["Close"].tap()
            app.buttons[addresses.addAddress].tap()
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

    private func typeName(name: String, updateText: Bool = false) {
        app.staticTexts["Name"].tap()
        if updateText {
            clearText()
        }
        app.typeText(name)
    }

    private func typeOrganization(organization: String, updateText: Bool = false) {
        app.staticTexts["Organization"].tap()
        if updateText {
            clearText()
        }
        app.typeText(organization)
    }

    private func typeStreetAddress(street: String, updateText: Bool = false) {
        app.staticTexts["Street Address"].tap()
        if updateText {
            clearText()
        }
        app.typeText(street)
    }

    private func typeCity(city: String, updateText: Bool = false) {
        app.staticTexts["City"].tap()
        if updateText {
            clearText()
        }
        app.typeText(city)
    }

    private func selectCountry(country: String) {
        app.staticTexts["Country or Region"].tap()
        mozWaitForElementToExist(app.buttons[country])
        app.buttons[country].tap()
    }

    private func typeZIP(zip: String, updateText: Bool = false, isPostalCode: Bool = false) {
        if isPostalCode {
            scrollToElement(app.staticTexts["Postal Code"])
            app.staticTexts["Postal Code"].tap()
        } else {
            scrollToElement(app.staticTexts["ZIP Code"])
            app.staticTexts["ZIP Code"].tap()
        }
        if updateText {
            clearText()
        }
        app.typeText(zip)
    }

    private func typePhone(phone: String, updateText: Bool = false) {
        if app.buttons["Done"].isHittable {
            app.buttons["Done"].tap()
        }
        app.staticTexts["Phone"].tapOnApp()
        if updateText {
            clearText(isPhoneNumber: true)
        }
        app.typeText(phone)
    }

    private func typeEmail(email: String, updateText: Bool = false) {
        scrollToElement(app.staticTexts["Email"])
        app.staticTexts["Email"].tap()
        if updateText {
            clearText()
        }
        app.typeText(email)
    }

    private func tapSave() {
        app.buttons["Save"].waitAndTap()
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
