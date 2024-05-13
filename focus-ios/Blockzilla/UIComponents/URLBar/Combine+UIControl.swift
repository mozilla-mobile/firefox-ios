// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Combine

public protocol CombineCompatible { }
extension UIControl: CombineCompatible { }
public extension CombineCompatible where Self: UIControl {
    func publisher(event: UIControl.Event) -> UIControlPublisher<UIControl> {
        return UIControlPublisher(control: self, event: event)
    }
}

public struct UIControlPublisher<Control: UIControl>: Publisher {
    public typealias Output = Control
    public typealias Failure = Never

    let control: Control
    let controlEvent: UIControl.Event

    init(control: Control, event: UIControl.Event) {
        self.control = control
        self.controlEvent = event
    }

    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == UIControlPublisher.Failure, S.Input == UIControlPublisher.Output {
        let subscription = UIControlSubscription(subscriber: subscriber, control: control, event: controlEvent)
        subscriber.receive(subscription: subscription)
    }
}

final class UIControlSubscription<SubscriberType: Subscriber,
                                  Control: UIControl>: Subscription
where SubscriberType.Input == Control {
    private var subscriber: SubscriberType?
    private let control: Control

    init(subscriber: SubscriberType, control: Control, event: UIControl.Event) {
        self.subscriber = subscriber
        self.control = control
        control.addTarget(self, action: #selector(eventHandler), for: event)
    }

    func request(_ demand: Subscribers.Demand) {
        // We do nothing here as we only want to send events when they occur.
        // See, for more info: https://developer.apple.com/documentation/combine/subscribers/demand
    }

    func cancel() {
        subscriber = nil
    }

    @objc
    private func eventHandler() {
        _ = subscriber?.receive(control)
    }
}
