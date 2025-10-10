// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol AddressSelectorsSet {
    var BUTTON_SAVE: Selector { get }
    var BUTTON_EDIT: Selector { get }
    var BUTTON_REMOVE_ADDRESS: Selector { get }
    var BUTTON_REMOVE: Selector { get }
    var BUTTON_CLOSE: Selector { get }
    var BUTTON_ADD_ADDRESS: Selector { get }

    var FIELD_NAME: Selector { get }
    var FIELD_ORGANIZATION: Selector { get }
    var FIELD_STREET: Selector { get }
    var FIELD_CITY: Selector { get }
    var FIELD_ZIP: Selector { get }
    var FIELD_POSTAL_CODE: Selector { get }
    var FIELD_PHONE: Selector { get }
    var FIELD_EMAIL: Selector { get }
    var FIELD_COUNTRY: Selector { get }

    var NAVBAR_ADDRESSES: Selector { get }
    var NAVBAR_ADD_ADDRESS: Selector { get }
    var LABEL_SAVED_ADDRESSES: Selector { get }
    var ADDRESSES_SCREEN_TITLE: Selector { get }

    var BUTTON_AUTOFILL: Selector { get }
    var BUTTON_MANAGE_ADDRESSES: Selector { get }

    var all: [Selector] { get }
}

struct AddressSelectors: AddressSelectorsSet {
    private enum ID {
        static let addAddressButton = AccessibilityIdentifiers.Settings.Address.Addresses.addAddress
        static let addressesTitle = AccessibilityIdentifiers.Settings.Address.Addresses.title
        static let addressAutofillButton = AccessibilityIdentifiers.Browser.KeyboardAccessory.addressAutofillButton
        static let manageAddresses = AccessibilityIdentifiers.Autofill.footerPrimaryAction
    }

    let BUTTON_SAVE = Selector.buttonByLabel(
        "Save",
        description: "Save button on Add/Edit Address screen",
        groups: ["addresses"]
    )

    let BUTTON_EDIT = Selector.buttonByLabel(
        "Edit",
        description: "Edit button in Address details screen",
        groups: ["addresses"]
    )

    let BUTTON_REMOVE_ADDRESS = Selector.buttonByLabel(
        "Remove Address",
        description: "Remove Address button",
        groups: ["addresses"]
    )

    let BUTTON_REMOVE = Selector.buttonByLabel(
        "Remove",
        description: "Confirm Remove button",
        groups: ["addresses"]
    )

    let BUTTON_CLOSE = Selector.buttonByLabel(
        "Close",
        description: "Close button to dismiss modal form",
        groups: ["addresses"]
    )

    let BUTTON_ADD_ADDRESS = Selector.buttonId(
        ID.addAddressButton,
        description: "Add Address button",
        groups: ["addresses"]
    )

    let FIELD_NAME = Selector.staticTextByLabel(
        "Name",
        description: "Name field label",
        groups: ["addresses"]
    )

    let FIELD_ORGANIZATION = Selector.staticTextByLabel(
        "Organization",
        description: "Organization field label",
        groups: ["addresses"]
    )

    let FIELD_STREET = Selector.staticTextByLabel(
        "Street Address",
        description: "Street Address field label",
        groups: ["addresses"]
    )

    let FIELD_CITY = Selector.staticTextByLabel(
        "City",
        description: "City field label",
        groups: ["addresses"]
    )

    let FIELD_ZIP = Selector.staticTextByLabel(
        "ZIP Code",
        description: "ZIP Code field label",
        groups: ["addresses"]
    )

    let FIELD_POSTAL_CODE = Selector.staticTextByLabel(
        "Postal Code",
        description: "Postal Code field label (used in some locales)",
        groups: ["addresses"]
    )

    let FIELD_PHONE = Selector.staticTextByLabel(
        "Phone",
        description: "Phone field label",
        groups: ["addresses"]
    )

    let FIELD_EMAIL = Selector.staticTextByLabel(
        "Email",
        description: "Email field label",
        groups: ["addresses"]
    )

    let FIELD_COUNTRY = Selector.staticTextByLabel(
        "Country or Region",
        description: "Country or Region field label",
        groups: ["addresses"]
    )

    let NAVBAR_ADD_ADDRESS = Selector.navigationBarId(
        AccessibilityIdentifiers.Settings.Address.Addresses.addAddress,
        description: "Navigation bar: Add Address",
        groups: ["addresses"]
    )

    let NAVBAR_ADDRESSES = Selector.navigationBarId(
        AccessibilityIdentifiers.Settings.Address.Addresses.title,
        description: "Navigation bar: Addresses",
        groups: ["addresses"]
    )

    let LABEL_SAVED_ADDRESSES = Selector.staticTextByLabel(
        "SAVED ADDRESSES",
        description: "Header label after saving an address",
        groups: ["addresses"]
    )

    let ADDRESSES_SCREEN_TITLE = Selector.staticTextId(
        ID.addressesTitle,
        description: "Title of the main Addresses screen",
        groups: ["addresses"]
    )

    let BUTTON_AUTOFILL = Selector.buttonId(
        ID.addressAutofillButton,
        description: "Autofill button on keyboard accessory bar",
        groups: ["addresses", "keyboard"]
    )

    let BUTTON_MANAGE_ADDRESSES = Selector.anyId(
        ID.manageAddresses,
        description: "Manage Addresses link in autofill popup",
        groups: ["addresses", "keyboard"]
    )

    var all: [Selector] {
        [
            BUTTON_SAVE, BUTTON_EDIT, BUTTON_REMOVE_ADDRESS, BUTTON_REMOVE, BUTTON_CLOSE, BUTTON_ADD_ADDRESS,
            FIELD_NAME, FIELD_ORGANIZATION, FIELD_STREET, FIELD_CITY,
            FIELD_ZIP, FIELD_POSTAL_CODE, FIELD_PHONE, FIELD_EMAIL, FIELD_COUNTRY,
            NAVBAR_ADDRESSES, NAVBAR_ADD_ADDRESS, LABEL_SAVED_ADDRESSES, ADDRESSES_SCREEN_TITLE,
            BUTTON_AUTOFILL, BUTTON_MANAGE_ADDRESSES
        ]
    }
}
