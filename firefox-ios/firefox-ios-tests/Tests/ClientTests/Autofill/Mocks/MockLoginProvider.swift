// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

class MockLoginProvider: LoginProvider {
    var searchLoginsWithQueryCalledCount = 0
    var addLoginCalledCount = 0
    func searchLoginsWithQuery(
        _ query: String?,
        completionHandler: @escaping (
            Result<
                [MozillaAppServices.EncryptedLogin],
            any Error
            >
        ) -> Void
    ) {
        searchLoginsWithQueryCalledCount += 1
        completionHandler(.success([]))
    }

    func addLogin(
        login: MozillaAppServices.LoginEntry,
        completionHandler: @escaping (
            Result<
            MozillaAppServices.EncryptedLogin?,
            any Error
            >
        ) -> Void
    ) {
        addLoginCalledCount += 1
        completionHandler(.success(nil))
    }
}
