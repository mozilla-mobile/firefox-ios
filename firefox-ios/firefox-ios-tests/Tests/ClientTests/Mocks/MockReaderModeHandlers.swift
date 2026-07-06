// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

@MainActor
final class MockReaderModeHandlers: ReaderModeHandlersProtocol {
    private(set) var registerCalled = 0

    func register(_ webServer: WebServerProtocol, profile: Profile) {
        registerCalled += 1
    }
}
