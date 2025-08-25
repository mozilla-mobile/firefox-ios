// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

final class MockTabScrollHandlerDelegate: TabScrollHandler.Delegate {
    struct TransitionCall {
        let progress: CGFloat
        let towards: TabScrollHandler.ToolbarDisplayState
    }
    var updateCalls: [TransitionCall] = []
    var showCount = 0
    var hideCount = 0

    func updateToolbarTransition(progress: CGFloat, towards state: TabScrollHandler.ToolbarDisplayState) {
        updateCalls.append(.init(progress: progress, towards: state))
    }
    func showToolbar() { showCount += 1 }
    func hideToolbar() { hideCount += 1 }
}
