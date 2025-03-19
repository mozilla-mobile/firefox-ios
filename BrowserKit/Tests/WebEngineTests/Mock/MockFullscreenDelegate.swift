// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import WebEngine

final class MockFullscreenDelegate: FullscreenDelegate {
    var onFullscreeChangeCalled = 0
    var savedFullscreenState = false

    func enteringFullscreen() {
        onFullscreeChangeCalled += 1
        savedFullscreenState = true
    }

    func exitingFullscreen() {
        onFullscreeChangeCalled += 1
        savedFullscreenState = false
    }
}
