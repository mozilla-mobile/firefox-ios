// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol DispatchQueueInterface {
    @preconcurrency
    func async(group: DispatchGroup?,
               qos: DispatchQoS,
               flags: DispatchWorkItemFlags,
               execute work: @escaping @Sendable @convention(block) () -> Void)

    @preconcurrency
    func ensureMainThread(execute work: @escaping @Sendable @convention(block) () -> Swift.Void)

    func asyncAfter(deadline: DispatchTime, execute: DispatchWorkItem)

    @preconcurrency
    func asyncAfter(deadline: DispatchTime,
                    qos: DispatchQoS,
                    flags: DispatchWorkItemFlags,
                    execute work: @escaping @Sendable @convention(block) () -> Void)
}

extension DispatchQueueInterface {
    @preconcurrency
    public func async(group: DispatchGroup? = nil,
                      qos: DispatchQoS = .unspecified,
                      flags: DispatchWorkItemFlags = [],
                      execute work: @escaping @Sendable @convention(block) () -> Void) {
        async(group: group, qos: qos, flags: flags, execute: work)
    }

    @preconcurrency
    public func asyncAfter(deadline: DispatchTime,
                           qos: DispatchQoS = .unspecified,
                           flags: DispatchWorkItemFlags = [],
                           execute work: @escaping @Sendable @convention(block) () -> Void) {
        asyncAfter(deadline: deadline, qos: qos, flags: flags, execute: work)
    }

    @preconcurrency
    public func ensureMainThread(execute work: @escaping @Sendable @convention(block) () -> Swift.Void) {
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
