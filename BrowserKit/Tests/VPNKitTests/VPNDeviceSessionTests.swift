// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import VPNKit

final class VPNDeviceSessionTests: XCTestCase {
    /// 2026-09-08 12:00:00 UTC, with a one hour TTL and renewal due after 45 minutes.
    private let issuedAtMilliseconds: Int64 = 1_788_004_800_000
    private var expiresAtMilliseconds: Int64 { issuedAtMilliseconds + 3_600_000 }
    private var renewAfterMilliseconds: Int64 { issuedAtMilliseconds + 2_700_000 }

    func test_decode_readsBackendMillisecondTimestamps() throws {
        let session = try JSONDecoder().decode(VPNDeviceSession.self, from: wireJSON)

        XCTAssertEqual(session.deviceSessionJwt, "header.payload.signature")
        XCTAssertEqual(session.expiresAtMilliseconds, expiresAtMilliseconds)
        XCTAssertEqual(session.renewAfterMilliseconds, renewAfterMilliseconds)
    }

    func test_encode_keepsBackendFieldNames() throws {
        let data = try JSONEncoder().encode(subject())
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        // The keychain stores this encoding, so the wire names must survive a round trip.
        XCTAssertEqual(json["expiresAt"] as? Int64, expiresAtMilliseconds)
        XCTAssertEqual(json["renewAfter"] as? Int64, renewAfterMilliseconds)
        XCTAssertNil(json["expiresAtMilliseconds"])
    }

    func test_isValid_treatsTimestampsAsMilliseconds() {
        let subject = subject()
        let oneSecondBeforeExpiry = date(atMilliseconds: expiresAtMilliseconds - 1000)
        let oneSecondAfterExpiry = date(atMilliseconds: expiresAtMilliseconds + 1000)

        XCTAssertTrue(subject.isValid(now: oneSecondBeforeExpiry))
        XCTAssertFalse(subject.isValid(now: oneSecondAfterExpiry))
    }

    func test_needsRenewal_treatsTimestampsAsMilliseconds() {
        let subject = subject()
        let beforeRenewal = date(atMilliseconds: renewAfterMilliseconds - 1000)
        let afterRenewal = date(atMilliseconds: renewAfterMilliseconds + 1000)

        XCTAssertFalse(subject.needsRenewal(now: beforeRenewal))
        XCTAssertTrue(subject.needsRenewal(now: afterRenewal))
        XCTAssertTrue(
            subject.isValid(now: afterRenewal),
            "Past renewal but before expiry the session must still count as valid"
        )
    }

    /// A session issued seconds-since-epoch by mistake would look long expired, which is the failure
    /// the millisecond naming exists to prevent.
    func test_isValid_isFalse_whenTimestampsAreSeconds() {
        let subject = VPNDeviceSession(
            deviceSessionJwt: "header.payload.signature",
            expiresAtMilliseconds: expiresAtMilliseconds / 1000,
            renewAfterMilliseconds: renewAfterMilliseconds / 1000
        )

        XCTAssertFalse(subject.isValid(now: date(atMilliseconds: issuedAtMilliseconds)))
    }

    // MARK: - Helpers

    private var wireJSON: Data {
        let json = """
        {
          "deviceSessionJwt": "header.payload.signature",
          "expiresAt": \(expiresAtMilliseconds),
          "renewAfter": \(renewAfterMilliseconds)
        }
        """
        return Data(json.utf8)
    }

    private func subject() -> VPNDeviceSession {
        return VPNDeviceSession(
            deviceSessionJwt: "header.payload.signature",
            expiresAtMilliseconds: expiresAtMilliseconds,
            renewAfterMilliseconds: renewAfterMilliseconds
        )
    }

    private func date(atMilliseconds milliseconds: Int64) -> Date {
        return Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}
