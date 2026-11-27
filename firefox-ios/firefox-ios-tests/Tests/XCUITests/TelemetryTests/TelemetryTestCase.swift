// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

/// Base class for UI tests that assert on Glean telemetry. The app uploads its pings to a `GleanPingServer`
/// owned by the test instead of the production endpoint, and starts with empty Glean storage on every launch.
class TelemetryTestCase: BaseTestCase {
    private var pingServer: GleanPingServer!
    var telemetry: TelemetryVerifier!

    override func setUp() async throws {
        guard #available(iOS 16.4, *) else {
            throw XCTSkip("Telemetry UI tests submit Glean pings through a deeplink, which needs iOS 16.4 or newer")
        }

        pingServer = GleanPingServer()
        let endpoint = try pingServer.start()
        launchArguments.append("\(LaunchArguments.GleanTestServerEndpoint)\(endpoint)")
        try await super.setUp()
        telemetry = TelemetryVerifier(server: pingServer, urlScheme: currentScheme.internalURLScheme)
    }

    override func tearDown() async throws {
        pingServer?.stop()
        try await super.tearDown()
    }
}
