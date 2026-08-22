// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import Common
import MozillaAppServices

final class ASSearchEngineProviderTests: XCTestCase {
    func testInit_withInjectedRemoteSettingsService_doesNotRequireProfileToBeRegistered() {
        AppContainer.shared.reset()

        let subject = ASSearchEngineProvider(
            remoteSettingsService: MockRemoteSettingsService(syncResult: []),
            iconDataFetcher: nil
        )

        XCTAssertEqual(subject.preferencesVersion, .v2)
    }
}
