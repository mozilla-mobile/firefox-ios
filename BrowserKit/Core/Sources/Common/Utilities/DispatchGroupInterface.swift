// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol DispatchGroupInterface {
    func enter()
    func leave()
    func notify(qos: DispatchQoS,
                flags: DispatchWorkItemFlags,
                queue: DispatchQueue,
                execute work: @escaping @convention(block) () -> Void)

    func notify(qos: DispatchQoS,
                flags: DispatchWorkItemFlags,
                queue: DispatchQueueInterface,
                execute work: @escaping @convention(block) () -> Void)
}

extension DispatchGroupInterface {
    public func notify(qos: DispatchQoS = .unspecified,
                       flags: DispatchWorkItemFlags = [],
                       queue: DispatchQueue,
                       execute work: @escaping @convention(block) () -> Void) {
        notify(qos: qos,
               flags: flags,
               queue: queue,
               execute: work)
    }

    public func notify(qos: DispatchQoS = .unspecified,
                       flags: DispatchWorkItemFlags = [],
                       queue: DispatchQueueInterface,
                       execute work: @escaping @convention(block) () -> Void) {
        notify(qos: qos,
               flags: flags,
               queue: queue,
               execute: work)
    }
}

extension DispatchGroup: DispatchGroupInterface {
    public func notify(qos: DispatchQoS,
                       flags: DispatchWorkItemFlags,
                       queue: DispatchQueueInterface,
                       execute work: @escaping @convention(block) () -> Void) {
        guard let queue = queue as? DispatchQueue else { return }
        notify(qos: qos, flags: flags, queue: queue, execute: work)
    }
}
