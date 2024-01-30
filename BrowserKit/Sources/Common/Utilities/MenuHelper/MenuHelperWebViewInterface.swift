// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@objc
public protocol MenuHelperWebViewInterface {
    /// Used to add a find in page menu option on webview textfields
    @objc
    optional func menuHelperFindInPage()

    /// Used to add a search with "client" menu option on the webview textfields
    @objc
    optional func menuHelperSearchWith()
}

/// Used to pass in the Client strings for the webview textfields menu options
public struct MenuHelperWebViewModel {
    public static let selectorFindInPage: Selector = #selector(MenuHelperWebViewInterface.menuHelperFindInPage)
    public static let selectorSearchWith: Selector = #selector(MenuHelperWebViewInterface.menuHelperSearchWith)

    var searchTitle: String
    var findInPageTitle: String

    public init(searchTitle: String,
                findInPageTitle: String) {
        self.searchTitle = searchTitle
        self.findInPageTitle = findInPageTitle
    }
}
