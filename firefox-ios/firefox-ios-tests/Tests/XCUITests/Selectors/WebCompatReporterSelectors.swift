// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol WebCompatReporterSelectorSet {
    var NAVIGATION_BAR: Selector { get }
    var CLOSE_BUTTON: Selector { get }
    var URL_FIELD: Selector { get }
    var URL_CLEAR_BUTTON: Selector { get }
    var URL_ERROR: Selector { get }
    var CATEGORY_MENU: Selector { get }
    var SITE_ISSUE_HEADER: Selector { get }
    var SEND_BUTTON: Selector { get }
    var all: [Selector] { get }
    func issueType(_ title: String) -> Selector
    func subOption(_ rawValue: String) -> Selector
}

struct WebCompatReporterSelectors: WebCompatReporterSelectorSet {
    private enum IDs {
        static let navigationBar = String.MainMenu.ToolsSection.ReportBrokenSite
        // The close button has no accessibility identifier, it is matched on its label
        static let closeButton = String.WebCompatReporter.Sheet.CloseButtonAccessibilityLabel
        static let urlField = AccessibilityIdentifiers.WebCompatReporter.urlField
        static let urlClearButton = "Clear text"
        // The error row has no accessibility identifier, it is matched on its label
        static let urlError = String.WebCompatReporter.Fields.URLError
        static let categoryMenu = AccessibilityIdentifiers.WebCompatReporter.categoryMenu
        // Section headers have no accessibility identifier, they are matched on their label.
        // They surface as a Cell below iOS 26 and as a StaticText on iOS 26.
        static let siteIssueHeader = String.WebCompatReporter.IssueSection.Title
        static let subOption = AccessibilityIdentifiers.WebCompatReporter.subOption
        static let sendButton = AccessibilityIdentifiers.WebCompatReporter.sendButton
    }

    let NAVIGATION_BAR = Selector.navigationBarByIdOrLabel(
        IDs.navigationBar,
        description: "Navigation bar of the Report Broken Site sheet",
        groups: ["WebCompatReporter"]
    )

    let CLOSE_BUTTON = Selector.buttonInNavigationBarByLabel(
        IDs.closeButton,
        description: "Close button in the Report Broken Site sheet navigation bar",
        groups: ["WebCompatReporter"]
    )

    let URL_FIELD = Selector.textFieldId(
        IDs.urlField,
        description: "URL field in the Report Broken Site sheet",
        groups: ["WebCompatReporter"]
    )

    let URL_CLEAR_BUTTON = Selector.buttonByLabel(
        IDs.urlClearButton,
        description: "System clear button of the URL field, shown while editing",
        groups: ["WebCompatReporter"]
    )

    let URL_ERROR = Selector.staticTextByLabel(
        IDs.urlError,
        description: "Error shown under the URL field when the URL is not reportable",
        groups: ["WebCompatReporter"]
    )

    let CATEGORY_MENU = Selector.buttonId(
        IDs.categoryMenu,
        description: "Issue type menu in the Report Broken Site sheet",
        groups: ["WebCompatReporter"]
    )

    let SITE_ISSUE_HEADER = Selector.anyIdOrLabel(
        IDs.siteIssueHeader,
        description: "Site Issue section header above the issue type menu",
        groups: ["WebCompatReporter"]
    )

    let SEND_BUTTON = Selector.buttonId(
        IDs.sendButton,
        description: "Send Report button in the Report Broken Site sheet",
        groups: ["WebCompatReporter"]
    )

    var all: [Selector] { [NAVIGATION_BAR, CLOSE_BUTTON, URL_FIELD, URL_CLEAR_BUTTON, URL_ERROR,
                           CATEGORY_MENU, SITE_ISSUE_HEADER, SEND_BUTTON] }

    /// An option of the issue type menu, matched on its title.
    func issueType(_ title: String) -> Selector {
        Selector.menuItemOrButtonByLabel(
            title,
            description: "\(title) option of the issue type menu",
            groups: ["WebCompatReporter"]
        )
    }

    /// A sub-option row of the selected issue type, `rawValue` being its Glean value (e.g. `no_video`).
    func subOption(_ rawValue: String) -> Selector {
        Selector.cellById(
            "\(IDs.subOption).\(rawValue)",
            description: "\(rawValue) sub-option row",
            groups: ["WebCompatReporter"]
        )
    }
}
