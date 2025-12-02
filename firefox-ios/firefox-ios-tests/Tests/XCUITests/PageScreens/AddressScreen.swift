// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class AddressScreen {
    private let app: XCUIApplication
    private let sel: AddressSelectorsSet

    init(app: XCUIApplication, selectors: AddressSelectorsSet = AddressSelectors()) {
        self.app = app
        self.sel = selectors
    }

    // Navigation

    func reachAddNewAddressScreen() {
        BaseTestCase().mozWaitForElementToExist(sel.NAVBAR_ADDRESSES.element(in: app))

        // Tap en "Add Address"
        let addAddressButton = sel.BUTTON_ADD_ADDRESS.element(in: app)
        addAddressButton.waitAndTap()

        BaseTestCase().mozWaitForElementToExist(sel.NAVBAR_ADD_ADDRESS.element(in: app))

        let closeButton = sel.BUTTON_CLOSE.element(in: app)
        var attempts = 3
        while !sel.FIELD_NAME.element(in: app).exists && attempts > 0 {
            closeButton.tapIfExists()
            addAddressButton.tapIfExists()
            attempts -= 1
        }

        BaseTestCase().mozWaitForElementToExist(sel.FIELD_NAME.element(in: app))
    }

    // Actions

    func tapSave(withRetry: Bool = false) {
        let button = sel.BUTTON_SAVE.element(in: app)
        if withRetry {
            button.tapWithRetry()
        } else {
            button.waitAndTap()
        }
    }

    func tapEdit() {
        sel.BUTTON_EDIT.element(in: app).waitAndTap()
    }

    func tapRemoveAddress() {
        sel.BUTTON_REMOVE_ADDRESS.element(in: app).waitAndTap()
        sel.BUTTON_REMOVE.element(in: app).waitAndTap()
    }

    func reachEditAndRemoveAddress() {
        app.collectionViews.cells.buttons.staticTexts.firstMatch.tapWithRetry()
        // Update the all addresses fields
        let buttonEdit = sel.BUTTON_EDIT.element(in: app)
        buttonEdit.waitAndTap()
        // Remove address
        let buttonRemoveAddress = sel.BUTTON_REMOVE_ADDRESS.element(in: app)
        let buttonRemove = sel.BUTTON_REMOVE.element(in: app)
        buttonRemoveAddress.waitAndTap()
        buttonRemove.waitAndTap()
    }

    func openAutofillMenuAndManageAddresses() {
        let addressAutofillButton = AccessibilityIdentifiers.Browser.KeyboardAccessory.addressAutofillButton
        let manageAddresses = AccessibilityIdentifiers.Autofill.footerPrimaryAction
        app.buttons[addressAutofillButton].waitAndTap()
        // Tap the "Manage addresses" link
        app.otherElements.buttons[manageAddresses].waitAndTap()
    }

    func openAutofillMenuAndManageAddresses(addressSel: AddressSelectorsSet) {
        let autofillButton = app.buttons[addressSel.BUTTON_AUTOFILL.value]
        let manageButton = app.otherElements.buttons[addressSel.BUTTON_MANAGE_ADDRESSES.value]

        autofillButton.waitAndTap()
        manageButton.waitAndTap()
    }

    // Fill fields

    func typeName(name: String, updateText: Bool = false) {
        let element = sel.FIELD_NAME.element(in: app)
        element.waitAndTap()
        if updateText {
            clearText()
        }
        retryTypingText(element: element, textField: name)
    }

    func typeOrganization(organization: String, updateText: Bool = false) {
        let element = sel.FIELD_ORGANIZATION.element(in: app)
        element.waitAndTap()
        if updateText {
            clearText()
        }
        retryTypingText(element: element, textField: organization)
    }

    func typeStreet(street: String, updateText: Bool = false) {
        let element = sel.FIELD_STREET.element(in: app)
        element.waitAndTap()
        if updateText {
            clearText()
        }
        retryTypingText(element: element, textField: street)
    }

    func typeCity(city: String, updateText: Bool = false) {
        let element = sel.FIELD_CITY.element(in: app)
        element.waitAndTap()
        if updateText {
            clearText()
        }
        retryTypingText(element: element, textField: city)
    }

    func typeZIP(zip: String, updateText: Bool = false, isPostalCode: Bool = false) {
        if isPostalCode {
            let postalCodeField = sel.FIELD_POSTAL_CODE.element(in: app)
            scrollToElement(postalCodeField)
            postalCodeField.waitAndTap()
            if updateText {
                clearText()
            }
            retryTypingText(element: postalCodeField, textField: zip)
        } else {
            let zipCodeField = sel.FIELD_ZIP.element(in: app)
            scrollToElement(zipCodeField)
            zipCodeField.waitAndTap()
            if updateText {
                clearText()
            }
            retryTypingText(element: zipCodeField, textField: zip)
        }
    }

    func typePhone(phone: String, updateText: Bool = false) {
        let element = sel.FIELD_PHONE.element(in: app)
        element.waitAndTap()
        if updateText {
            clearText()
        }
        retryTypingText(element: element, textField: phone)
    }

    func typeEmail(email: String, updateText: Bool = false) {
        let emailField = sel.FIELD_EMAIL.element(in: app)
        scrollToElement(emailField)
        emailField.waitAndTap()
        if updateText {
            clearText()
        }
        retryTypingText(element: emailField, textField: email)
    }

    func selectCountry(_ country: String) {
        sel.FIELD_COUNTRY.element(in: app).waitAndTap()
        app.buttons[country].waitAndTap()
    }

    func addNewAddress() {
        typeName(name: "Test")
        typeOrganization(organization: "organization test")
        typeStreet(street: "test address")
        typeCity(city: "city test")
        typeZIP(zip: "123456")
        typePhone(phone: "01234567")
        typeEmail(email: "test@mozilla.com")
    }

    func assertAddressSaved(values: [String]) {
        BaseTestCase().mozWaitForElementToExist(sel.LABEL_SAVED_ADDRESSES.element(in: app))

        for value in values {
            BaseTestCase().mozWaitForElementToExist(app.staticTexts[value])
        }
    }

    func assertAddressNotVisible(values: [String]) {
        for value in values {
            BaseTestCase().mozWaitForElementToNotExist(app.staticTexts[value])
        }
    }

    func assertAddressesSettingsScreenVisible(timeout: TimeInterval = TIMEOUT) {
        let addressesNavBar = sel.NAVBAR_ADDRESSES.element(in: app)
        BaseTestCase().mozWaitForElementToExist(addressesNavBar, timeout: timeout)
    }

    // Handle iPad Navigation

    func handleiPadNavigationKeys() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        app.buttons["_previousTapped"].waitAndTap()
    }

    // Helpers

    private func typeText(selector: Selector, text: String, update: Bool = false, isPhone: Bool = false) {
        let element = selector.element(in: app)
        element.waitAndTap()

        if update {
            clearText(isPhoneNumber: isPhone)
        }

        retryTypingText(element: element, textField: text)
    }

    private func retryTypingText(element: XCUIElement, textField: String) {
        var taps = 5
        sleep(1)
        while !element.isVisible() && taps > 0 {
            element.tapIfExists()
            taps -= 1
        }
        app.typeText(textField)
    }

    private func clearText(isPhoneNumber: Bool = false) {
        if isPhoneNumber && UIDevice.current.userInterfaceIdiom != .pad {
            BaseTestCase().mozWaitForElementToExist(app.keyboards.keys["Delete"])
            app.keyboards.keys["Delete"].press(forDuration: 2.2)
        } else {
            BaseTestCase().mozWaitForElementToExist(app.keyboards.keys["delete"])
            app.keyboards.keys["delete"].press(forDuration: 2.2)
        }
    }

    private func scrollToElement(_ element: XCUIElement) {
        while !element.isVisible() {
            app.swipeUp()
        }
    }
}
