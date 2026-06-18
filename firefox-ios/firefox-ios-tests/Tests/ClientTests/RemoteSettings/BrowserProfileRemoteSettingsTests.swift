// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import MozillaAppServices
import XCTest

final class BrowserProfileRemoteSettingsTests: XCTestCase {
    func testRemoteSettingsServiceLazyAttachesGleanTelemetry() {
        let spy = SpyRemoteSettingsService()

        let profile = BrowserProfile(
            localName: "rs-wiring-test-\(UUID().uuidString)",
            clear: true,
            remoteSettingsServiceFactory: { _, _ in spy }
        )

        _ = profile.remoteSettingsService

        XCTAssertEqual(
            spy.setTelemetryCalled,
            1,
            "BrowserProfile should call setTelemetry exactly once when constructing the service"
        )
        XCTAssertTrue(
            spy.capturedTelemetry is RemoteSettingsGleanTelemetry,
            "Expected RemoteSettingsGleanTelemetry, got \(String(describing: spy.capturedTelemetry))"
        )
    }
}

private final class SpyRemoteSettingsService: RemoteSettingsService, @unchecked Sendable {
    var setTelemetryCalled = 0
    var capturedTelemetry: RemoteSettingsTelemetry?

    init() {
        super.init(noHandle: NoHandle())
    }

    required init(unsafeFromHandle handle: UInt64) {
        super.init(unsafeFromHandle: handle)
    }

    override func setTelemetry(telemetry: RemoteSettingsTelemetry) {
        setTelemetryCalled += 1
        capturedTelemetry = telemetry
    }
}
