// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

class MockTabDisplayViewDragAndDropInteraction: TabDisplayViewDragAndDropInteraction {
    var dragAndDropStartedCalled = 0
    var dragAndDropEndedCalled = 0

    func dragAndDropStarted() {
        dragAndDropStartedCalled += 1
    }

    func dragAndDropEnded() {
        dragAndDropEndedCalled += 1
    }
}
