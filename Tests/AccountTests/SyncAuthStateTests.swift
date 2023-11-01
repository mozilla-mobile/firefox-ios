// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Account

final class SyncAuthStateTests: XCTestCase {
    func testAsJSON() throws {
        let mockToken = TokenServerToken(id: "id", key: "key", api_endpoint: "api_endpoint", uid: UInt64(), hashedFxAUID: "hashedUID", durationInSeconds: UInt64(Date.getCurrentPeriod()), remoteTimestamp: Timestamp(Date.getCurrentPeriod()))
        let mockKey = "mockKey"
        let mockData = mockKey.hexDecodedData
        let mockExpiresAt = Date().toTimestamp()
        let mockSyncAuthState = SyncAuthStateCache(token: mockToken, forKey: mockData, expiresAt: mockExpiresAt)

        let jsonDict = mockSyncAuthState.asJSON()

        let CurrentSyncAuthStateCacheVersion = 1
        let expectedJsonDict: [String: Any] = [
            "version": CurrentSyncAuthStateCacheVersion,
            "token": mockToken.asJSON(),
            "forKey": mockData.hexEncodedString,
            "expiresAt": NSNumber(value: mockSyncAuthState.expiresAt),
        ]

        XCTAssertTrue(NSDictionary(dictionary: jsonDict).isEqual(to: expectedJsonDict))
    }
}
