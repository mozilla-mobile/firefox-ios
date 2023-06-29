// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class PasswordManagerCoordinatorDelegateMock: PasswordManagerCoordinatorDelegate {
    var settingsOpenURLInNewTabCalled = 0
    var didFinishPasswordManagerCalled = 0
    var url: URL?

    func settingsOpenURLInNewTab(_ url: URL) {
        settingsOpenURLInNewTabCalled += 1
        self.url = url
    }

    func didFinishPasswordManager(from coordinator: PasswordManagerCoordinator) {
        didFinishPasswordManagerCalled += 1
    }
}
