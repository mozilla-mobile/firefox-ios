// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

final class RemoteTabsEmptyViewDelegateMock: RemoteTabsEmptyViewDelegate {
    private(set) var remotePanelDidRequestToSignInCallCount = 0
    private(set) var presentFxAccountSettingsCallCount = 0
    private(set) var remotePanelDidRequestToOpenInNewTabCallCount = 0

    func remotePanelDidRequestToSignIn() {
        remotePanelDidRequestToSignInCallCount += 1
    }

    func presentFxAccountSettings() {
        presentFxAccountSettingsCallCount += 1
    }

    func remotePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        remotePanelDidRequestToOpenInNewTabCallCount += 1
    }
}
