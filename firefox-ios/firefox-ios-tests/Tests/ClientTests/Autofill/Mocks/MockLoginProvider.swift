// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

class MockLoginProvider: LoginProvider, SyncLoginProvider {
    var searchLoginsWithQueryCalledCount = 0
    var addLoginCalledCount = 0
    var getStoredKeyCalledCount = 0
    var registerWithSyncManagerCalled = 0
    var verifyLoginsCalled = 0
    var loginsVerified = false

    func searchLoginsWithQuery(
        _ query: String?,
        completionHandler: @escaping (
            Result<
                [MozillaAppServices.Login],
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
            MozillaAppServices.Login?,
            any Error
            >
        ) -> Void
    ) {
        addLoginCalledCount += 1
        completionHandler(.success(nil))
    }

    func getStoredKey(completion: @escaping (Result<String, NSError>) -> Void) {
        getStoredKeyCalledCount += 1
        return completion(.success("test encryption key"))
    }

    func registerWithSyncManager() {
        registerWithSyncManagerCalled += 1
    }

    func verifyLogins(completionHandler: @escaping (Bool) -> Void) {
        verifyLoginsCalled += 1
        completionHandler(loginsVerified)
    }
}
