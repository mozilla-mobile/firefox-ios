// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol WebsiteDataSelectorsSet {
    var TABLE_WEBSITE_DATA: Selector { get }
    var CELL_CLEAR_ALL: Selector { get }
    var ALERT_OK_BUTTON: Selector { get }
    var BUTTON_DATA_MANAGEMENT: Selector { get }
    var BUTTON_SETTINGS: Selector { get }
    var BUTTON_DONE: Selector { get }
    var CELL_SHOW_MORE: Selector { get }
    var EXAMPLE_EQUAL: Selector { get }
    var EXAMPLE_CONTAINS: Selector { get }
    var CIRCLE_IMAGE_ANYWHERE: Selector { get }
    var STATIC_TEXT_EXAMPLE_IN_CELL: Selector { get }

    @MainActor
    func clearAllLabel(in app: XCUIApplication) -> XCUIElement
    @MainActor
    func circleImageInsideCells(_ app: XCUIApplication) -> XCUIElement
    @MainActor
    func anyTableButton(_ app: XCUIApplication) -> XCUIElement

    var all: [Selector] { get }
}

struct WebsiteDataSelectors: WebsiteDataSelectorsSet {
    private enum IDs {
        static let websiteDataOther = "Website Data"
        static let clearAllCell     = "ClearAllWebsiteData"
        static let clearAllLabel    = "Clear All Website Data"
        static let showMoreCell     = "ShowMoreWebsiteData"
        static let exampleLabel     = "example.com"
        static let circleImageId    = "circle"
        static let dataManagement   = "Data Management"
        static let settings         = "Settings"
        static let doneButton       = "Done"
        static let exampleUrl       = "example.com"
    }

    let TABLE_WEBSITE_DATA = Selector.tableOtherById(
        IDs.websiteDataOther,
        description: "Main Website Data table",
        groups: ["settings"]
    )

    let CELL_CLEAR_ALL = Selector.cellById(
        IDs.clearAllCell,
        description: "Cell 'ClearAllWebsiteData'",
        groups: ["settings"]
    )

    let ALERT_OK_BUTTON = Selector.buttonByLabel(
        "OK",
        description: "Confirmation button in clear data alert",
        groups: ["settings"]
    )

    let BUTTON_DATA_MANAGEMENT = Selector.buttonByLabel(
        IDs.dataManagement,
        description: "Back button from Website Data to Data Management screen",
        groups: ["settings"]
    )

    let BUTTON_SETTINGS = Selector.buttonByLabel(
        IDs.settings,
        description: "Back button to Settings screen",
        groups: ["settings"]
    )

    let BUTTON_DONE = Selector.buttonByLabel(
        IDs.doneButton,
        description: "Done button to exit Settings",
        groups: ["settings"]
    )

    let CELL_SHOW_MORE = Selector.cellById(
        IDs.showMoreCell,
        description: "Show more website data cell",
        groups: ["settings", "websitedata"]
    )

    let EXAMPLE_EQUAL = Selector.staticTextByExactLabel(
        IDs.exampleLabel,
        description: "example.com exact label",
        groups: ["settings", "websitedata"]
    )

    let EXAMPLE_CONTAINS = Selector.staticTextLabelContains(
        IDs.exampleLabel,
        description: "any staticText containing 'example.com'",
        groups: ["settings", "websitedata"]
    )

    let CIRCLE_IMAGE_ANYWHERE = Selector.imageById(
        IDs.circleImageId,
        description: "circle image id anywhere",
        groups: ["settings", "websitedata"]
    )

    let STATIC_TEXT_EXAMPLE_IN_CELL = Selector.cellStaticTextLabelContains(
        IDs.exampleUrl,
        description: "StaticText 'example.com' inside Website Data cell",
        groups: ["settings", "websitedata"]
    )

    @MainActor
    func clearAllLabel(in app: XCUIApplication) -> XCUIElement {
        app.tables.cells[IDs.clearAllCell].staticTexts[IDs.clearAllLabel]
    }

    @MainActor
    func circleImageInsideCells(_ app: XCUIApplication) -> XCUIElement {
        return app.cells.images.matching(identifier: IDs.circleImageId).firstMatch
    }

    @MainActor
    func anyTableButton(_ app: XCUIApplication) -> XCUIElement {
        return app.tables.buttons.firstMatch
    }

    var all: [Selector] {
        [
            TABLE_WEBSITE_DATA, CELL_CLEAR_ALL, ALERT_OK_BUTTON,
            BUTTON_DATA_MANAGEMENT, BUTTON_SETTINGS, BUTTON_DONE,
            CELL_SHOW_MORE, EXAMPLE_EQUAL, EXAMPLE_CONTAINS,
            CIRCLE_IMAGE_ANYWHERE, STATIC_TEXT_EXAMPLE_IN_CELL
        ]
    }
}
