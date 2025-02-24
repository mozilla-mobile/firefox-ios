// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
@testable import WebEngine

class MockDispatchSourceTimerFactory: DispatchSourceTimerFactory {
    var dispatchSource = MockDispatchSourceInterface()
    func createDispatchSource() -> DispatchSourceInterface {
        return dispatchSource
    }
}

class MockDispatchSourceInterface: DispatchSourceInterface {
    var scheduleCalled = 0
    var setEventHandlerCalled = 0
    var resumeCalled = 0
    var cancelCalled = 0

    func schedule(deadline: DispatchTime,
                  repeating interval: DispatchTimeInterval = .never,
                  leeway: DispatchTimeInterval = .nanoseconds(0)) {
        scheduleCalled += 1
    }

    func setEventHandler(completion: @escaping () -> Void) {
        setEventHandlerCalled += 1
        completion()
    }

    func resume() {
        resumeCalled += 1
    }

    func cancel() {
        cancelCalled += 1
    }
}
