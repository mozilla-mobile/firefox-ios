// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class PublishersTests: XCTestCase {
    func testNotifySubscriber() {
        let publisher = ExamplePublisher()
        let subscriber = ExampleSubscriber(expectation(description: ""), publisher: publisher)
        subscriber.shouldReceive = ["hello", "world"]
        publisher.eventHappened(["hello", "world"])
        waitForExpectations(timeout: 1)
    }

    func testNotRetainingSubscriber() {
        let publisher = ExamplePublisher()
        var subscriber: ExampleSubscriber? = ExampleSubscriber(expectation(description: ""), publisher: publisher)
        subscriber!.shouldReceive = ["hello", "world"]
        publisher.eventHappened(["hello", "world"])
        subscriber = nil
        publisher.eventHappened(["hello", "world"])
        waitForExpectations(timeout: 1) { _ in
            XCTAssertTrue(publisher.subscriptions.isEmpty)
        }
    }

    func testUnsubscribe() {
        let publisher = ExamplePublisher()
        publisher.subscribe(self) { _ in }
        publisher.unsubscribe(self)
        XCTAssertTrue(publisher.subscriptions.isEmpty)
    }

    func testSubscribeMultipleTimes() {
        let publisher = ExamplePublisher()
        publisher.subscribe(self) { _ in }
        publisher.subscribe(self) { _ in }
        XCTAssertEqual(1, publisher.subscriptions.count)
    }
}

private final class ExamplePublisher: Publisher {
    var subscriptions = [Subscription<[String]>]()

    func eventHappened(_ messages: [String]) {
        send(messages)
    }
}

private final class ExampleSubscriber {
    var shouldReceive = [String]()
    private let expect: XCTestExpectation

    init(_ expect: XCTestExpectation, publisher: ExamplePublisher) {
        self.expect = expect
        publisher.subscribe(self) { [weak self] in
            XCTAssertEqual(self?.shouldReceive, $0)
            self?.expect.fulfill()
        }
    }
}
