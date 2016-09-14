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

    func testAllCompleted() {
        let results: EngineResults = [
            ("tabs", .Completed),
            ("clients", .Completed)
        ]
        let maybeResults = Maybe(success: results)

        let resolver = SyncStatusResolver(engineResults: maybeResults)
        XCTAssertTrue(resolver.resolveResults() == SyncDisplayState.Good)
    }

    func testAllCompletedExceptOneDisabledRemotely() {
        let results: EngineResults = [
            ("tabs", .Completed),
            ("clients", .NotStarted(.EngineRemotelyNotEnabled(collection: "clients")))
        ]
        let maybeResults = Maybe(success: results)

        let resolver = SyncStatusResolver(engineResults: maybeResults)
        XCTAssertTrue(resolver.resolveResults() == SyncDisplayState.Good)
    }

    func testAllCompletedExceptNotStartedBecauseNoAccount() {
        let results: EngineResults = [
            ("tabs", .Completed),
            ("clients", .NotStarted(.NoAccount))
        ]
        let maybeResults = Maybe(success: results)

        let resolver = SyncStatusResolver(engineResults: maybeResults)
        XCTAssertTrue(resolver.resolveResults() == SyncDisplayState.Warning(message: Strings.FirefoxSyncOfflineTitle))
    }

    func testAllCompletedExceptNotStartedBecauseOffline() {
        let results: EngineResults = [
            ("tabs", .Completed),
            ("clients", .NotStarted(.Offline))
        ]
        let maybeResults = Maybe(success: results)

        let resolver = SyncStatusResolver(engineResults: maybeResults)
        XCTAssertTrue(resolver.resolveResults() == SyncDisplayState.Bad(message: Strings.FirefoxSyncOfflineTitle))
    }

    func testOfflineAndNoAccount() {
        let results: EngineResults = [
            ("tabs", .NotStarted(.NoAccount)),
            ("clients", .NotStarted(.Offline))
        ]

        let maybeResults = Maybe(success: results)

        let resolver = SyncStatusResolver(engineResults: maybeResults)
        XCTAssertTrue(resolver.resolveResults() == SyncDisplayState.Bad(message: Strings.FirefoxSyncOfflineTitle))
    }

    func testAllPartial() {
        let results: EngineResults = [
            ("tabs", .Partial),
            ("clients", .Partial)
        ]
        let maybeResults = Maybe(success: results)

        let resolver = SyncStatusResolver(engineResults: maybeResults)
        XCTAssertTrue(resolver.resolveResults() == SyncDisplayState.Good)
    }

    func testBookmarkMergeError() {
        let maybeResults: Maybe<EngineResults> = Maybe(failure: BookmarksMergeError())
        let resolver = SyncStatusResolver(engineResults: maybeResults)
        let expected = SyncDisplayState.Warning(message: String(format: Strings.FirefoxSyncPartialTitle, Strings.localizedStringForSyncComponent("bookmarks") ?? ""))
        XCTAssertTrue(resolver.resolveResults() == expected)
    }

    func testBookmarksDatabaseError() {
        let maybeResults: Maybe<EngineResults> = Maybe(failure: BookmarksDatabaseError(err: nil))
        let resolver = SyncStatusResolver(engineResults: maybeResults)
        let expected = SyncDisplayState.Warning(message: String(format: Strings.FirefoxSyncPartialTitle, Strings.localizedStringForSyncComponent("bookmarks") ?? ""))
        XCTAssertTrue(resolver.resolveResults() == expected)
    }

    func testRandomFailure() {
        let maybeResults: Maybe<EngineResults> = Maybe(failure: RandomError())
        let resolver = SyncStatusResolver(engineResults: maybeResults)
        let expected = SyncDisplayState.Bad(message: nil)
        XCTAssertTrue(resolver.resolveResults() == expected)
    }
}