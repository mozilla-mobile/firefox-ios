// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

/// Asserts on the Glean telemetry the app uploads to `GleanPingServer`.
@MainActor
final class TelemetryVerifier {
    private let server: GleanPingServer
    private let springboardScreen: SpringboardScreen
    private let urlScheme: String

    /// - Parameter urlScheme: Internal URL scheme of the build under test, used to deliver Glean deeplinks.
    init(server: GleanPingServer, urlScheme: String, springboardScreen: SpringboardScreen = SpringboardScreen()) {
        self.server = server
        self.urlScheme = urlScheme
        self.springboardScreen = springboardScreen
    }

    /// Submits the `events` ping and fails unless it reports `category.name` with `extras` exactly `count` times.
    /// Extras not listed in `extras` are ignored.
    func assertEventRecorded(
        category: String,
        name: String,
        extras: [String: String] = [:],
        count: Int = 1,
        timeout: TimeInterval = TIMEOUT,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard #available(iOS 16.4, *) else {
            XCTFail("Submitting Glean pings through a deeplink needs iOS 16.4 or newer", file: file, line: line)
            return
        }
        springboardScreen.openDeeplinkFromOutsideApp(Deeplink.gleanSendPing("events").url(scheme: urlScheme))

        let server = server
        let received = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                Self.events(in: server.pings).contains { $0.matches(category: category, name: name, extras: extras) }
            },
            object: nil
        )
        _ = XCTWaiter().wait(for: [received], timeout: timeout)
        attachPings(server.pings, rejected: server.rejected)

        let events = Self.events(in: server.pings)
        let matches = events.filter { $0.matches(category: category, name: name, extras: extras) }
        let rejected = server.rejected
        let rejectedNote = rejected.isEmpty ? "" : ". Requests not read as Glean pings: \(rejected.map(\.description))"
        XCTAssertEqual(
            matches.count,
            count,
            "Expected \(count) \(category).\(name) event(s) with \(extras). Events received: \(events)\(rejectedNote)",
            file: file,
            line: line
        )
    }

    /// Keeps the received `events` pings in the test report, whether the test passes or fails, as evidence of
    /// what the app actually sent.
    private func attachPings(_ pings: [GleanPing], rejected: [RejectedRequest]) {
        XCTContext.runActivity(named: "Glean events pings") { activity in
            var summaryText = "Pings received: \(pings.map(\.name).joined(separator: ", "))"
            if !rejected.isEmpty {
                let rejectedList = rejected.map(\.description).joined(separator: "\n")
                summaryText += "\nRequests not read as Glean pings:\n\(rejectedList)"
            }
            let summary = XCTAttachment(string: summaryText)
            summary.name = "Pings received"
            summary.lifetime = .keepAlways
            activity.add(summary)

            for (index, ping) in pings.filter({ $0.name == "events" }).enumerated() {
                let attachment = XCTAttachment(data: ping.prettyJSON, uniformTypeIdentifier: "public.json")
                attachment.name = "events ping \(index + 1).json"
                attachment.lifetime = .keepAlways
                activity.add(attachment)
            }

            for (index, rejection) in rejected.enumerated() {
                let attachment = XCTAttachment(data: rejection.body, uniformTypeIdentifier: "public.data")
                attachment.name = "rejected request \(index + 1)"
                attachment.lifetime = .keepAlways
                activity.add(attachment)
            }
        }
    }

    nonisolated private static func events(in pings: [GleanPing]) -> [GleanEvent] {
        pings.filter { $0.name == "events" }.flatMap(\.events)
    }
}
