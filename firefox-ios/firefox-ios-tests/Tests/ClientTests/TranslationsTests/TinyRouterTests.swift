// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
final class TinyRouterTests: XCTestCase {
    func test_route_exactMatch_returnsReply() async throws {
        let route = MockRoute(replyText: "A")
        let subject = createSubject()
            .register("a", route)

        let url = makeURL("a")
        let reply = try await subject.route(url)
        XCTAssertEqual(String(decoding: reply.body, as: UTF8.self), "A")
        XCTAssertEqual(route.calls.count, 1)
    }

    func test_route_prefixMatch_returnsReply() async throws {
        let route = MockRoute(replyText: "a")
        let subject = createSubject()
            .register("a", route)

        let url = makeURL("a/b/c")
        let reply = try await subject.route(url)
        XCTAssertEqual(String(decoding: reply.body, as: UTF8.self), "a")
        XCTAssertEqual(route.calls.count, 1)
    }

    func test_route_order_firstRegisteredWins() async throws {
        /// This test ensures that if multiple routes are registered for the same path,
        /// the router uses the first one registered.
        let first = MockRoute(replyText: "first")
        let second = MockRoute(replyText: "second")

        let subject = createSubject()
            .register("a", first)
            .register("a", second)

        let url = makeURL("a")
        let reply = try await subject.route(url)
        XCTAssertEqual(String(decoding: reply.body, as: UTF8.self), "first")
        XCTAssertEqual(first.calls.count, 1)
        XCTAssertEqual(second.calls.count, 0)
    }

    func test_route_returnsNil_fallsThroughToNext() async throws {
        let nilRoute = MockRoute(reply: nil)
        let nextRoute = MockRoute(replyText: "next")

        let subject = createSubject()
            .register("a", nilRoute)
            .register("a", nextRoute)

        let url = makeURL("a/whatever")
        let reply = try await subject.route(url)
        XCTAssertEqual(String(decoding: reply.body, as: UTF8.self), "next")
        XCTAssertEqual(nilRoute.calls.count, 1)
        XCTAssertEqual(nextRoute.calls.count, 1)
    }

    func test_route_usesDefaultRouteWhenNoMatch() async throws {
        let randomRoute = MockRoute(replyText: "random")
        let defaultRoute = MockRoute(replyText: "default")
        let subject = createSubject()
            .register("a", randomRoute)
            .setDefault(defaultRoute)

        let url = makeURL("unknown/path")
        let reply = try await subject.route(url)
        XCTAssertEqual(String(decoding: reply.body, as: UTF8.self), "default")
        XCTAssertEqual(defaultRoute.calls.count, 1)
    }

    func test_route_throwsNotFoundWhenNoHandlersAndNoDefault() async {
        let subject = createSubject()
        let url = makeURL("nada")
        await assertAsyncThrowsEqual(TinyRouterError.notFound) {
            try await subject.route(url)
        }
    }

    func test_route_propagatesRouteError() async {
        enum Fake: Error, Equatable { case boom }
        let route = MockRoute(reply: nil, error: Fake.boom)

        let subject = createSubject()
            .register("explode", route)

        let url = makeURL("explode")
        await assertAsyncThrowsEqual(Fake.boom) {
            try await subject.route(url)
        }
    }

    private func createSubject() -> TinyRouter {
        return TinyRouter()
    }

    private func makeURL(_ path: String) -> URL {
        URL(string: "foo://bar/\(path)")!
    }
}
