// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Account

final class SyncAuthStateTests: XCTestCase {
    let CurrentSyncAuthStateCacheVersion = 1
    func testAsJSON() {
        let mockToken = TokenServerToken(id: "id", key: "key", api_endpoint: "api_endpoint", uid: UInt64(), hashedFxAUID: "hashedUID", durationInSeconds: UInt64(Date.getCurrentPeriod()), remoteTimestamp: Timestamp(Date.getCurrentPeriod()))
        let mockKey = "mockKey"
        let mockData = mockKey.hexDecodedData
        let mockExpiresAt = Date().toTimestamp()
        let mockSyncAuthState = SyncAuthStateCache(token: mockToken, forKey: mockData, expiresAt: mockExpiresAt)

        let jsonDict = mockSyncAuthState.asJSON()

        let expectedJsonDict: [String: Any] = [
            "version": CurrentSyncAuthStateCacheVersion,
            "token": mockToken.asJSON(),
            "forKey": mockData.hexEncodedString,
            "expiresAt": NSNumber(value: mockSyncAuthState.expiresAt),
        ]

        XCTAssertTrue(NSDictionary(dictionary: jsonDict).isEqual(to: expectedJsonDict))
    }

    func testSyncAuthStateCachefromValidJSON() {
        let id = "id"
        let key = "key"
        let apiEndpoint = "api_endpoint"
        let uid = Int64(1)
        let hashedFxAUID = "hashed_fxa_uid"
        let durationInSeconds = Int64(Date.getCurrentPeriod())
        let remoteTimestamp = Int64(Date.getCurrentPeriod())

        let mockKey = "mockKey"
        let mockExpiresAt = Int64(1)
        var jsonDict: [String: Any] = [:]
        jsonDict["version"] = CurrentSyncAuthStateCacheVersion
        jsonDict["token"] = ["id": id, "key": key, "api_endpoint": apiEndpoint, "uid": uid, "hashed_fxa_uid": hashedFxAUID, "duration": durationInSeconds, "remoteTimestamp": remoteTimestamp]
        jsonDict["forKey"] = mockKey
        jsonDict["expiresAt"] = mockExpiresAt
        let syncAuthStateCache = syncAuthStateCachefromJSON(jsonDict)
        XCTAssertNotNil(syncAuthStateCache)
    }

    func testSyncAuthStateCachefromInvalidJSON() {
        let jsonDict: [String: Any] = [:]
        let syncAuthStateCache = syncAuthStateCachefromJSON(jsonDict)
        XCTAssertNil(syncAuthStateCache)
    }
}
