// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol Publisher: AnyObject {
    associatedtype Input
    var subscriptions: [Subscription<Input>] { get set }
}

public extension Publisher {
    func send(_ input: Input) {
        subscriptions.removeAll { $0.subscriber == nil }
        subscriptions.forEach { $0.closure(input) }
    }

    func subscribe(_ subscriber: AnyObject, closure: @escaping (Input) -> Void) {
        guard !subscriptions.contains(where: { $0.subscriber === subscriber }) else { return }
        subscriptions.append(.init(subscriber: subscriber, closure: closure))
    }

    func unsubscribe(_ subscriber: AnyObject) {
        subscriptions.removeAll { $0.subscriber === subscriber }
    }
}

public struct Subscription<Input> {
    weak var subscriber: AnyObject?
    let closure: (Input) -> Void
}

public protocol StatePublisher: Publisher {
    var state: Input? { get }
}

public extension StatePublisher {
    func subscribeAndReceive(_ subscriber: AnyObject, closure: @escaping (Input) -> Void) {
        subscribe(subscriber, closure: closure)
        state.map(closure)
    }
}
