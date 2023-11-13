// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
@testable import Client

class MockDispatchQueue: DispatchQueueInterface {
    func async(group: DispatchGroup?,
               qos: DispatchQoS,
               flags: DispatchWorkItemFlags,
               execute work: @escaping @convention(block) () -> Void) {
        work()
    }

    func asyncAfter(deadline: DispatchTime,
                    qos: DispatchQoS,
                    flags: DispatchWorkItemFlags,
                    execute work: @escaping @convention(block) () -> Void) {
        work()
    }

    func ensureMainThread(execute work: @escaping () -> Void) {
        work()
    }

    func asyncAfter(deadline: DispatchTime, execute: DispatchWorkItem) {
        execute.perform()
    }
}
