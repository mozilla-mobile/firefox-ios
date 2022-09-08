// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol DispatchQueueInterface {
    func async(group: DispatchGroup?,
               qos: DispatchQoS,
               flags: DispatchWorkItemFlags,
               execute work: @escaping @convention(block) () -> Void)

    func ensureMainThread(execute work: @escaping @convention(block) () -> Swift.Void)

    func asyncAfter(deadline: DispatchTime, execute: DispatchWorkItem)
}

extension DispatchQueueInterface {
    func async(group: DispatchGroup? = nil,
               qos: DispatchQoS = .unspecified,
               flags: DispatchWorkItemFlags = [],
               execute work: @escaping @convention(block) () -> Void) {
        async(group: group, qos: qos, flags: flags, execute: work)
    }

    func ensureMainThread(execute work: @escaping @convention(block) () -> Swift.Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async {
                work()
            }
        }
    }
}

extension DispatchQueue: DispatchQueueInterface {}
