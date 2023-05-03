// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
@testable import Client

class MockOpenURLDelegate: OpenURLDelegate {
    var savedURL: URL?
    var savedIsPrivate: Bool?

    func didRequestToOpenInNewTab(url: URL, isPrivate: Bool) {
        savedURL = url
        savedIsPrivate = isPrivate
    }
}
