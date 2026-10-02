// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol DocumentPickerSelectorsSet {
    var SAVE_BUTTON: Selector { get }
    var FILE_NAME_FIELD: Selector { get }
    var FILE_NAME_FIELD_TAGS_BUTTON: Selector { get }
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

    // Older iOS leaves the file name field untagged; this button inside it is what tells it apart.
    let FILE_NAME_FIELD_TAGS_BUTTON = Selector.buttonIdOrLabel(
        IDs.fileNameFieldTagsButton,
        description: "Tags button inside the iOS document picker's file name field",
        groups: ["documentPicker", "system"]
    )

    var all: [Selector] { [SAVE_BUTTON, FILE_NAME_FIELD, FILE_NAME_FIELD_TAGS_BUTTON] }
}
