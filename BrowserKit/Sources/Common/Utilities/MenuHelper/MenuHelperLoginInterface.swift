// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@objc
public protocol MenuHelperLoginInterface {
    /// Used to add the copy menu option on the login detail screen
    @objc
    optional func menuHelperCopy()

    /// Used to add the copy and fille menu option on the login detail screen
    @objc
    optional func menuHelperOpenAndFill()

    /// Used to add a reveal password menu option on the login detail screen
    @objc
    optional func menuHelperReveal()

    /// Used to add a reveal password menu option on the login detail screen
    @objc
    optional func menuHelperSecure()
}

/// Used to pass in the Client strings for the Login menu options
public struct MenuHelperLoginModel {
    public static let selectorCopy: Selector = #selector(MenuHelperLoginInterface.menuHelperCopy)
    public static let selectorHide: Selector = #selector(MenuHelperLoginInterface.menuHelperSecure)
    public static let selectorOpenAndFill: Selector = #selector(MenuHelperLoginInterface.menuHelperOpenAndFill)
    public static let selectorReveal: Selector = #selector(MenuHelperLoginInterface.menuHelperReveal)

    var revealPasswordTitle: String
    var hidePasswordTitle: String
    var copyItemTitle: String
    var openAndFillTitle: String

    public init(revealPasswordTitle: String,
                hidePasswordTitle: String,
                copyItemTitle: String,
                openAndFillTitle: String) {
        self.revealPasswordTitle = revealPasswordTitle
        self.hidePasswordTitle = hidePasswordTitle
        self.copyItemTitle = copyItemTitle
        self.openAndFillTitle = openAndFillTitle
    }
}
