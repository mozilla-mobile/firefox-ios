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
    var NAVIGATION_BAR: Selector { get }
    var BROWSE_BUTTON: Selector { get }
    var SEARCH_FIELD: Selector { get }
    var MORE_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct DocumentPickerSelectors: DocumentPickerSelectorsSet {
    private enum IDs {
        static let saveButton = "Save"
        static let fileNameField = "DOCPicker.filenameTextField"
        static let fileNameFieldTagsButton = "Tags"
        static let backButton = "BackButton"
        static let onDeviceLocationPrefix = "DOC.sidebar.item.On My "
        static let navigationBar = "FullDocumentManagerViewControllerNavigationBar"
        static let browseButton = "Browse"
        static let searchField = "Search"
        static let moreButton = "OverflowBarButtonItem"
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
    let ON_DEVICE_LOCATION = Selector.cellIdBeginsWith(
        IDs.onDeviceLocationPrefix,
        description: "On-device storage location in the iOS document picker",
        groups: ["documentPicker", "system"]
    )

    let NAVIGATION_BAR = Selector.navigationBarId(
        IDs.navigationBar,
        description: "Navigation bar of the iOS document picker",
        groups: ["documentPicker", "system"]
    )

    // Leads back to the picker's Browse list of locations.
    let BROWSE_BUTTON = Selector.buttonInNavigationBarByLabel(
        IDs.browseButton,
        description: "Browse button in the iOS document picker navigation bar",
        groups: ["documentPicker", "system"]
    )

    let SEARCH_FIELD = Selector.searchFieldByIdOrLabel(
        IDs.searchField,
        description: "Search field in the iOS document picker navigation bar",
        groups: ["documentPicker", "system"]
    )

    // "More" (…) button in the picker's navigation bar, holding the view and sort options.
    let MORE_BUTTON = Selector.buttonId(
        IDs.moreButton,
        description: "More button in the iOS document picker navigation bar",
        groups: ["documentPicker", "system"]
    )

    var all: [Selector] { [SAVE_BUTTON, FILE_NAME_FIELD, UNTAGGED_FILE_NAME_FIELD, BACK_BUTTON, ON_DEVICE_LOCATION,
                           NAVIGATION_BAR, BROWSE_BUTTON, SEARCH_FIELD, MORE_BUTTON] }
}
