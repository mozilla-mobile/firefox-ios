// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// Enum file that holds the different cases for the Quick Actions small widget with their
/// configurations (string, backgrounds, images) as selected by the user in edit mode.
enum QuickLink: Int {
    case search = 1
    case copiedLink
    case privateSearch
    case closePrivateTabs

    public var imageName: String {
        switch self {
        case .search:
            return "faviconFox"
        case .privateSearch:
            return StandardImageIdentifiers.Large.privateMode
        case .copiedLink:
            return StandardImageIdentifiers.Large.tabTray
        case .closePrivateTabs:
            return StandardImageIdentifiers.Large.delete
        }
    }

    public var label: String {
        switch self {
        case .search:
            return String.SearchInFirefoxV2
        case .privateSearch:
            return String.SearchInPrivateTabLabelV2
        case .copiedLink:
            return String.GoToCopiedLinkLabelV2
        case .closePrivateTabs:
            return String.ClosePrivateTabsLabelV2
        }
    }

    public var smallWidgetUrl: URL {
        switch self {
        case .search:
            return linkToContainingApp("?private=false", query: "widget-small-quicklink-open-url")
        case .privateSearch:
            return linkToContainingApp("?private=true", query: "widget-small-quicklink-open-url")
        case .copiedLink:
            return linkToContainingApp(query: "widget-small-quicklink-open-copied")
        case .closePrivateTabs:
            return linkToContainingApp(query: "widget-small-quicklink-close-private-tabs")
        }
    }

    public var mediumWidgetUrl: URL {
        switch self {
        case .search:
            return linkToContainingApp("?private=false", query: "widget-medium-quicklink-open-url")
        case .privateSearch:
            return linkToContainingApp("?private=true", query: "widget-medium-quicklink-open-url")
        case .copiedLink:
            return linkToContainingApp(query: "widget-medium-quicklink-open-copied")
        case .closePrivateTabs:
            return linkToContainingApp(query: "widget-medium-quicklink-close-private-tabs")
        }
    }

    public var backgroundColors: [Color] {
        switch self {
        case .search:
            return [Color("searchButtonColorTwo"), Color("searchButtonColorOne")]
        case .privateSearch:
            return [Color("privateGradientThree"), Color("privateGradientTwo"), Color("privateGradientOne")]
        case .copiedLink:
            return [Color("goToCopiedLinkSolid")]
        case .closePrivateTabs:
            return [Color("privateGradientThree"), Color("privateGradientTwo"), Color("privateGradientOne")]
        }
    }
}
