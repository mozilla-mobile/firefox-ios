// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

final class RemoteTabsPanelDelegateMock: RemoteTabsPanelDelegate {
    private(set) var presentFirefoxAccountSignInCallCount = 0
    private(set) var presentFxAccountSettingsCallCount = 0

    func presentFirefoxAccountSignIn() {
        presentFirefoxAccountSignInCallCount += 1
    }

    func presentFxAccountSettings() {
        presentFxAccountSettingsCallCount += 1
    }
}
