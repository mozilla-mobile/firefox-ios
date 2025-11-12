// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class TinyRouterTests: XCTestCase {
    func test_route_exactMatch_returnsReply() throws {
        let route = MockRoute(replyText: "A")
        let subject = createSubject()
            .register("a", route)

        let url = makeURL("a")
        let reply = try subject.route(url)
        XCTAssertEqual(String(decoding: reply.body, as: UTF8.self), "A")
        XCTAssertEqual(route.calls.count, 1)
    }

    func test_route_prefixMatch_returnsReply() throws {
        let route = MockRoute(replyText: "a")
        let subject = createSubject()
            .register("a", route)

        let url = makeURL("a/b/c")
        let reply = try subject.route(url)
        XCTAssertEqual(String(decoding: reply.body, as: UTF8.self), "a")
        XCTAssertEqual(route.calls.count, 1)
    }

    func test_route_order_firstRegisteredWins() throws {
        /// This test ensures that if multiple routes are registered for the same path,
        /// the router uses the first one registered.
        let first = MockRoute(replyText: "first")
        let second = MockRoute(replyText: "second")

        let subject = createSubject()
            .register("a", first)
            .register("a", second)

        let url = makeURL("a")
        let reply = try subject.route(url)
        XCTAssertEqual(String(decoding: reply.body, as: UTF8.self), "first")
        XCTAssertEqual(first.calls.count, 1)
        XCTAssertEqual(second.calls.count, 0)
    }

    func test_route_returnsNil_fallsThroughToNext() throws {
        let nilRoute = MockRoute(reply: nil)
        let nextRoute = MockRoute(replyText: "next")

        let subject = createSubject()
            .register("a", nilRoute)
            .register("a", nextRoute)

        let url = makeURL("a/whatever")
        let reply = try subject.route(url)
        XCTAssertEqual(String(decoding: reply.body, as: UTF8.self), "next")
        XCTAssertEqual(nilRoute.calls.count, 1)
        XCTAssertEqual(nextRoute.calls.count, 1)
    }

    func test_route_usesDefaultRouteWhenNoMatch() throws {
        let randomRoute = MockRoute(replyText: "random")
        let defaultRoute = MockRoute(replyText: "default")
        let subject = createSubject()
            .register("a", randomRoute)
            .setDefault(defaultRoute)

        let url = makeURL("unknown/path")
        let reply = try subject.route(url)
        XCTAssertEqual(String(decoding: reply.body, as: UTF8.self), "default")
        XCTAssertEqual(defaultRoute.calls.count, 1)
    }

    func test_route_throwsNotFoundWhenNoHandlersAndNoDefault() {
        let subject = createSubject()
        let url = makeURL("nada")
        XCTAssertThrowsError(try subject.route(url)) { error in
            XCTAssertEqual(error as? TinyRouterError, .notFound)
        }
    }

    func test_route_propagatesRouteError() {
        enum Fake: Error, Equatable { case boom }
        let route = MockRoute(reply: nil, error: Fake.boom)

        let subject = createSubject()
            .register("explode", route)

        let url = makeURL("explode")
        XCTAssertThrowsError(try subject.route(url)) { error in
            XCTAssertEqual(error as? Fake, .boom)
        }
    }

    private func createSubject() -> TinyRouter {
        return TinyRouter()
    }

    private func makeURL(_ path: String) -> URL {
        URL(string: "foo://bar/\(path)")!
    }
}
