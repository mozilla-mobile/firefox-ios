// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

class MockDispatchQueue: DispatchQueueInterface {
    var asyncCalled = 0
    var asyncAferCalled = 0
    var ensureMainThreadCalled = 0
    var asyncAfterDispatchWorkItemCalled = 0

    func async(group: DispatchGroup?,
               qos: DispatchQoS,
               flags: DispatchWorkItemFlags,
               execute work: @escaping @convention(block) () -> Void) {
        asyncCalled += 1
        work()
    }

    func asyncAfter(deadline: DispatchTime,
                    qos: DispatchQoS,
                    flags: DispatchWorkItemFlags,
                    execute work: @escaping @convention(block) () -> Void) {
        asyncAferCalled += 1
        work()
    }

    func ensureMainThread(execute work: @escaping () -> Void) {
        ensureMainThreadCalled += 1
        work()
    }

    func asyncAfter(deadline: DispatchTime, execute: DispatchWorkItem) {
        asyncAfterDispatchWorkItemCalled += 1
        execute.perform()
    }
}
