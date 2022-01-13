//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

extension XCUIApplication {
    var settingsButton: XCUIElement {
        if #available(iOS 14, *) {
            return self.collectionViews.cells.buttons["Settings"]
        } else {
            return self.tables.cells["Settings"]
        }
    }
    
    var findInPageButton: XCUIElement {
        if #available(iOS 14, *) {
            return self.collectionViews.cells.buttons["Find in Page"]
        } else {
            return self.tables.cells["Find in Page"]
        }
    }

    var eraseButton: XCUIElement {
        return self.buttons["URLBar.deleteButton"]
    }

    var urlTextField: XCUIElement {
        return self.textFields["URLBar.urlText"]
    }
}
