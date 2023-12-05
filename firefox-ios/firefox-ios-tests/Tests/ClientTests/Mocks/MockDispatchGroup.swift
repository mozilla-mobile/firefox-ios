// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
@testable import Client

class MockDispatchGroup: DispatchGroupInterface {
    func enter() {}

    func leave() {}

    func notify(qos: DispatchQoS,
                flags: DispatchWorkItemFlags,
                queue: DispatchQueue,
                execute work: @escaping @convention(block) () -> Void) {
        work()
    }

    func notify(qos: DispatchQoS,
                flags: DispatchWorkItemFlags,
                queue: DispatchQueueInterface,
                execute work: @escaping @convention(block) () -> Void) {
        work()
    }
}
