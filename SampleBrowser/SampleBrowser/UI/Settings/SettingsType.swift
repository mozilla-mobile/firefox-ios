// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// Used to trigger some functionalities from the WebEngine with a simple UI
public enum SettingsType: String {
    case standardContentBlocking
    case strictContentBlocking
    case disableContentBlocking
    case noImageMode
    case findInPage
    case scrollingToTop
    case zoomIncrease
    case zoomDecrease
    case zoomReset
    case zoomSet
}
