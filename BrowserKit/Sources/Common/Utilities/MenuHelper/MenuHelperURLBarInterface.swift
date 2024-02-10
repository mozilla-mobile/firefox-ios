// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@objc
public protocol MenuHelperURLBarInterface {
    /// Used to add a paste and go option on the URL bar textfield
    @objc
    optional func menuHelperPasteAndGo()
}

/// Used to pass in the Client strings for the URL bar textfield menu options
public struct MenuHelperURLBarModel {
    public static let selectorPasteAndGo: Selector = #selector(MenuHelperURLBarInterface.menuHelperPasteAndGo)

    var pasteAndGoTitle: String

    public init(pasteAndGoTitle: String) {
        self.pasteAndGoTitle = pasteAndGoTitle
    }
}
