// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol DocumentPickerSelectorsSet {
    var SAVE_BUTTON: Selector { get }
    var FILE_NAME_FIELD: Selector { get }
    var UNTAGGED_FILE_NAME_FIELD: Selector { get }
    var BACK_BUTTON: Selector { get }
    var ON_DEVICE_LOCATION: Selector { get }
    var all: [Selector] { get }
}

struct DocumentPickerSelectors: DocumentPickerSelectorsSet {
    private enum IDs {
        static let saveButton = "Save"
        static let fileNameField = "DOCPicker.filenameTextField"
        static let fileNameFieldTagsButton = "Tags"
        static let backButton = "BackButton"
        static let onDeviceLocationPrefix = "DOC.sidebar.item.On My "
    }

    let SAVE_BUTTON = Selector.buttonIdOrLabel(
        IDs.saveButton,
        description: "Save button in the iOS document picker",
        groups: ["documentPicker", "system"]
    )

    // Holds the name the picker pre-fills for the document being saved, without its extension.
    let FILE_NAME_FIELD = Selector.textFieldId(
        IDs.fileNameField,
        description: "File name field in the iOS document picker",
        groups: ["documentPicker", "system"]
    )

    // Older iOS leaves the file name field without an id, so find it by the Tags button it contains.
    let UNTAGGED_FILE_NAME_FIELD = Selector.textFieldContainingButton(
        labeled: IDs.fileNameFieldTagsButton,
        description: "File name field in the iOS document picker on iOS versions that leave it untagged",
        groups: ["documentPicker", "system"]
    )

    // Leads one level up from the current location, up to the Browse list of locations.
    let BACK_BUTTON = Selector.buttonInNavigationBarByLabel(
        IDs.backButton,
        description: "Back button in the iOS document picker",
        groups: ["documentPicker", "system"]
    )

    // "On My iPhone" or "On My iPad" in the picker's Browse list of locations.
    let ON_DEVICE_LOCATION = Selector(
        strategy: .predicate(NSPredicate(
            format: "elementType == %d AND identifier BEGINSWITH %@",
            XCUIElement.ElementType.cell.rawValue,
            IDs.onDeviceLocationPrefix
        )),
        value: IDs.onDeviceLocationPrefix,
        description: "On-device storage location in the iOS document picker",
        groups: ["documentPicker", "system"]
    )

    var all: [Selector] { [SAVE_BUTTON, FILE_NAME_FIELD, UNTAGGED_FILE_NAME_FIELD, BACK_BUTTON, ON_DEVICE_LOCATION] }
}
