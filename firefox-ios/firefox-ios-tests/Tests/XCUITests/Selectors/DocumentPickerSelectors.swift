// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol DocumentPickerSelectorsSet {
    var SAVE_BUTTON: Selector { get }
    var FILE_NAME_FIELD: Selector { get }
    var UNTAGGED_FILE_NAME_FIELD: Selector { get }
    var all: [Selector] { get }
}

struct DocumentPickerSelectors: DocumentPickerSelectorsSet {
    private enum IDs {
        static let saveButton = "Save"
        static let fileNameField = "DOCPicker.filenameTextField"
        static let fileNameFieldTagsButton = "Tags"
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

    var all: [Selector] { [SAVE_BUTTON, FILE_NAME_FIELD, UNTAGGED_FILE_NAME_FIELD] }
}
