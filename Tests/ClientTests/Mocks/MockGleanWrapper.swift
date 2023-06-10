// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
@testable import Client

class MockGleanWrapper: GleanWrapper {
    var handleDeeplinkUrlCalled = 0
    var submitPingCalled = 0
    var setUploadEnabledCalled = 0

    var savedHandleDeeplinkUrl: URL?
    var savedSetUploadIsEnabled: Bool?

    func handleDeeplinkUrl(url: URL) {
        handleDeeplinkUrlCalled += 1
        savedHandleDeeplinkUrl = url
    }
    func submitPing() {
        submitPingCalled += 1
    }
    func setUpload(isEnabled: Bool) {
        setUploadEnabledCalled += 1
        savedSetUploadIsEnabled = isEnabled
    }
}
