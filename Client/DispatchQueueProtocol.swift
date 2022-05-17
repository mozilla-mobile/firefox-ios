// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

enum DispatchQueueContext: Equatable {
    case main
    case global(DispatchQoS.QoSClass)
}

protocol DispatchQueueProtocol {
    func shared(_ context: DispatchQueueContext) -> DispatchQueue
    func async(context: DispatchQueueContext, _ work: @escaping @convention(block) () -> Void)
}

extension DispatchQueueProtocol {
    func shared(_ context: DispatchQueueContext) -> DispatchQueue {
        switch context {
        case .main:
            return DispatchQueue.main
        case .global(let qos):
            return DispatchQueue.global(qos: qos)
        }
    }
}

class MozillaDispatchQueue: DispatchQueueProtocol {
    func async(context: DispatchQueueContext, _ work: @escaping @convention(block) () -> Void) {
        shared(context).async(execute: work)
    }
}

