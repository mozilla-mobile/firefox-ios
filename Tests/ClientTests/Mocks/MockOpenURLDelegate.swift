// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
@testable import Client

class MockOpenURLDelegate: OpenURLDelegate {
    var savedURL: URL?
    var savedIsPrivate: Bool?
    var savedSelectedNewTab: Bool?

    func didRequestToOpenInNewTab(url: URL, isPrivate: Bool, selectNewTab: Bool) {
        savedURL = url
        savedIsPrivate = isPrivate
        savedSelectedNewTab = selectNewTab
    }
}
