// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class AddressesTests: BaseTestCase {
    let addressSavedTxt = "Address Saved"
    let savedAddressesTxt = "SAVED ADDRESSES"

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

    private func reachAddNewAddressScreen() {
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(AddressesSettings)
        let addresses = AccessibilityIdentifiers.Settings.Address.Addresses.self
        mozWaitForElementToExist(app.navigationBars[addresses.title])
        app.buttons[addresses.addAddress].tap()
        mozWaitForElementToExist(app.navigationBars[addresses.addAddress])
        if iPad() {
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

    private func typeName(name: String) {
        app.staticTexts["Name"].tap()
        app.typeText(name)
    }

    private func typeOrganization(organization: String) {
        app.staticTexts["Organization"].tap()
        app.typeText(organization)
    }

    private func typeStreetAddress(street: String) {
        app.staticTexts["Street Address"].tap()
        app.typeText(street)
    }

    private func typeCity(city: String) {
        app.staticTexts["City"].tap()
        app.typeText(city)
    }

    private func typeZIP(zip: String) {
        scrollToElement(app.staticTexts["ZIP Code"])
        app.staticTexts["ZIP Code"].tap()
        app.typeText(zip)
    }

    private func typePhone(phone: String) {
        if app.buttons["Done"].isHittable {
            app.buttons["Done"].tap()
        }
        app.staticTexts["Phone"].tapOnApp()
        app.typeText(phone)
    }

    private func typeEmail(email: String) {
        scrollToElement(app.staticTexts["Email"])
        app.staticTexts["Email"].tap()
        app.typeText(email)
    }

    private func tapSave() {
        app.buttons["Save"].waitAndTap()
    }
}
