// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

final class MockPrivacyNoticeHelper: PrivacyNoticeHelperProtocol {
    private var shouldShowPrivacyNoticeCount = 0
    var shouldShowResult = false

    func shouldShowPrivacyNotice() -> Bool {
        shouldShowPrivacyNoticeCount += 1
        return shouldShowResult
    }
}
