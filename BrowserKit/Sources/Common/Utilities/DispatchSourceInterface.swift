// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol DispatchSourceTimerFactory {
    func createDispatchSource() -> DispatchSourceInterface
}

public struct DefaultDispatchSourceTimerFactory: DispatchSourceTimerFactory {
    public func createDispatchSource() -> DispatchSourceInterface {
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        return DefaultDispatchSourceTimer(timer: timer)
    }

    public init() {}
}

public protocol DispatchSourceInterface {
    func schedule(deadline: DispatchTime, repeating interval: DispatchTimeInterval, leeway: DispatchTimeInterval)

    func setEventHandler(completion: @escaping () -> Void)

    func resume()

    func cancel()
}

public extension DispatchSourceInterface {
    func schedule(deadline: DispatchTime,
                  repeating interval: DispatchTimeInterval = .never,
                  leeway: DispatchTimeInterval = .nanoseconds(0)) {
        schedule(deadline: deadline, repeating: interval, leeway: leeway)
    }
}

public struct DefaultDispatchSourceTimer: DispatchSourceInterface {
    let timer: DispatchSourceTimer

    public func schedule(deadline: DispatchTime,
                         repeating interval: DispatchTimeInterval = .never,
                         leeway: DispatchTimeInterval = .nanoseconds(0)) {
        timer.schedule(deadline: deadline, repeating: interval, leeway: leeway)
    }

    public func setEventHandler(completion: @escaping () -> Void) {
        timer.setEventHandler(handler: completion)
    }

    public func resume() {
        timer.resume()
    }

    public func cancel() {
        timer.cancel()
    }
}
