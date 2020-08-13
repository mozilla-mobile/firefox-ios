/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import Shared

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
            return "smallPrivateMask"
        case .copiedLink:
            return "copy_link_icon"
        case .closePrivateTabs:
            return "delete"
        }
    }

    public var headlineTxt: String {
        return String(String.newSearchButtonLabel.split(separator: " ")[2])
    }

    public var captionTxt: String {
        switch self {
        case .search:
            return String(String.newSearchButtonLabel.split(separator: " ")[0]) + " " + String(String.newSearchButtonLabel.split(separator: " ")[1])
        case .privateSearch:
            return String.NewPrivateTabButtonLabel
        case .copiedLink:
            return ""
        case .closePrivateTabs:
            return ""
        }
    }

    public var label: String {
        switch self {
        case .search:
            return String.newSearchButtonLabel
        case .privateSearch:
            return String.NewPrivateTabButtonLabel
        case .copiedLink:
            return String.GoToCopiedLinkLabelV2
        case .closePrivateTabs:
            return String.closePrivateTabsButtonLabel
        }
    }

    public var url: URL {
        switch self {
        case .search:
            return linkToContainingApp("?private=false", query: "open-url")
        case .privateSearch:
            return linkToContainingApp("?private=true", query: "open-url")
        case .copiedLink:
            return linkToContainingApp(query: "open-copied")
        case .closePrivateTabs:
            return linkToContainingApp(query: "close-private-tabs")
        }
    }

    public var backgroundColors: [Color] {
        switch self {
        case .search:
            return [Color("searchButtonColorTwo"), Color("searchButtonColorOne")]
        case .privateSearch:
            return [Color("privateGradientThree"), Color("privateGradientTwo"),Color("privateGradientOne")]
        case .copiedLink:
            return [Color("goToCopiedLinkSolid")]
        case .closePrivateTabs:
            return [Color("privateGradientThree"), Color("privateGradientTwo"),Color("privateGradientOne")]
        }
    }

    static func from(_ configuration: QuickLinkSelectionIntent) -> Self {
        switch configuration.selectedLink {
        case .search:
            return .search
        case .privateSearch:
            return .privateSearch
        case .clearPrivateTabs:
            return .closePrivateTabs
        case .copiedLink:
            return .copiedLink
        default:
            return .search
        }
    }
}
