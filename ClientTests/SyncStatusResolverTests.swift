/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
@testable import Sync

import Shared
import Storage
import XCTest

private class RandomError: MaybeErrorType {
    var description = "random_error"
}

class SyncStatusResolverTests: XCTestCase {

    private func mockStatsForCollection(collection: String) -> SyncEngineStatsSession {
        return SyncEngineStatsSession(collection: collection)
    }

    func testAllCompleted() {
        let results: EngineResults = [
            ("tabs", .completed(mockStatsForCollection(collection: "tabs"))),
            ("clients", .completed(mockStatsForCollection(collection: "clients")))
        ]
        let maybeResults = Maybe(success: results)

        let resolver = SyncStatusResolver(engineResults: maybeResults)
        XCTAssertTrue(resolver.resolveResults() == SyncDisplayState.good)
    }

    func testAllCompletedExceptOneDisabledRemotely() {
        let results: EngineResults = [
            ("tabs", .completed(mockStatsForCollection(collection: "tabs"))),
            ("clients", .notStarted(.engineRemotelyNotEnabled(collection: "clients")))
        ]
        let maybeResults = Maybe(success: results)

        let resolver = SyncStatusResolver(engineResults: maybeResults)
        XCTAssertTrue(resolver.resolveResults() == SyncDisplayState.good)
    }

    func testAllCompletedExceptNotStartedBecauseNoAccount() {
        let results: EngineResults = [
            ("tabs", .completed(mockStatsForCollection(collection: "tabs"))),
            ("clients", .notStarted(.noAccount))
        ]
        let maybeResults = Maybe(success: results)

        let resolver = SyncStatusResolver(engineResults: maybeResults)
        XCTAssertTrue(resolver.resolveResults() == SyncDisplayState.warning(message: Strings.FirefoxSyncOfflineTitle))
    }

    func testAllCompletedExceptNotStartedBecauseOffline() {
        let results: EngineResults = [
            ("tabs", .completed(mockStatsForCollection(collection: "tabs"))),
            ("clients", .notStarted(.offline))
        ]
        let maybeResults = Maybe(success: results)

        let resolver = SyncStatusResolver(engineResults: maybeResults)
        XCTAssertTrue(resolver.resolveResults() == SyncDisplayState.bad(message: Strings.FirefoxSyncOfflineTitle))
    }

    func testOfflineAndNoAccount() {
        let results: EngineResults = [
            ("tabs", .notStarted(.noAccount)),
            ("clients", .notStarted(.offline))
        ]

        let maybeResults = Maybe(success: results)

        let resolver = SyncStatusResolver(engineResults: maybeResults)
        XCTAssertTrue(resolver.resolveResults() == SyncDisplayState.bad(message: Strings.FirefoxSyncOfflineTitle))
    }

    func testAllPartial() {
        let results: EngineResults = [
            ("tabs", .partial(SyncEngineStatsSession(collection: "tabs"))),
            ("clients", .partial(SyncEngineStatsSession(collection: "clients")))
        ]
        let maybeResults = Maybe(success: results)

        let resolver = SyncStatusResolver(engineResults: maybeResults)
        XCTAssertTrue(resolver.resolveResults() == SyncDisplayState.good)
    }

    func testBookmarkMergeError() {
        let maybeResults: Maybe<EngineResults> = Maybe(failure: BookmarksMergeError())
        let resolver = SyncStatusResolver(engineResults: maybeResults)
        let expected = SyncDisplayState.warning(message: String(format: Strings.FirefoxSyncPartialTitle, Strings.localizedStringForSyncComponent("bookmarks") ?? ""))
        XCTAssertTrue(resolver.resolveResults() == expected)
    }

    func testBookmarksDatabaseError() {
        let maybeResults: Maybe<EngineResults> = Maybe(failure: BookmarksDatabaseError(err: nil))
        let resolver = SyncStatusResolver(engineResults: maybeResults)
        let expected = SyncDisplayState.warning(message: String(format: Strings.FirefoxSyncPartialTitle, Strings.localizedStringForSyncComponent("bookmarks") ?? ""))
        XCTAssertTrue(resolver.resolveResults() == expected)
    }

    func testRandomFailure() {
        let maybeResults: Maybe<EngineResults> = Maybe(failure: RandomError())
        let resolver = SyncStatusResolver(engineResults: maybeResults)
        let expected = SyncDisplayState.bad(message: nil)
        XCTAssertTrue(resolver.resolveResults() == expected)
    }
}
