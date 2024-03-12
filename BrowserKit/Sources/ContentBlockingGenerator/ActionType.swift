// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Those are the actionType that will be used in WebKit
/// https://developer.apple.com/documentation/safariservices/creating_a_content_blocker
enum ActionType: String {
    case blockAll = "block"
    case blockCookies = "block-cookies"

    var webKitFormat: String {
        return "\"\(self.rawValue)\""
    }
}
