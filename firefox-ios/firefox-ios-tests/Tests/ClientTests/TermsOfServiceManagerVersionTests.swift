// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client

private class StubBundle: VersionProviding {
    var fakeVersion: String?
    init(fakeVersion: String? = nil) {
        self.fakeVersion = fakeVersion
    }
    func object(forInfoDictionaryKey key: String) -> Any? {
        guard key == "CFBundleShortVersionString" else { return nil }
        return fakeVersion
    }
}

final class TermsOfServiceManagerVersionTests: XCTestCase {
    // The half-open range [138.0, 138.1)
    let versionRange = "138.0"..<"138.1"

    /// Shared across all tests, set up fresh each time
    private var bundle: StubBundle!
    private var manager: TermsOfServiceManager!
    private var mockProfilePrefs: MockProfilePrefs!

    override func setUp() {
        super.setUp()
        // default to nil; individual tests will override as needed
        bundle = StubBundle(fakeVersion: nil)
        mockProfilePrefs = MockProfilePrefs()
        manager = TermsOfServiceManager(prefs: mockProfilePrefs, bundle: bundle)
    }

    func testMissingVersionStringReturnsFalse() {
        // fakeVersion is already nil
        XCTAssertFalse(manager.isAppVersion(in: versionRange),
                       "No version string should yield false")
    }

    func testVersionBelowMinimumReturnsFalse() {
        bundle.fakeVersion = "137.9"
        XCTAssertFalse(manager.isAppVersion(in: versionRange),
                       "137.9 is below the minimum 138.0")
    }

    func testVersionExactlyAtMinimumReturnsTrue() {
        bundle.fakeVersion = "138.0"
        XCTAssertTrue(manager.isAppVersion(in: versionRange),
                      "138.0 is the inclusive lower bound and should pass")
    }

    func testPatchVersionAboveMinimumReturnsTrue() {
        bundle.fakeVersion = "138.0.1"
        XCTAssertTrue(manager.isAppVersion(in: versionRange),
                      "138.0.1 is >138.0 and <138.1, so should pass")
    }

    func testVersionExactlyAtUpperBoundReturnsFalse() {
        bundle.fakeVersion = "138.1"
        XCTAssertFalse(manager.isAppVersion(in: versionRange),
                       "138.1 is the exclusive upper bound and should fail")
    }

    func testVersionAboveUpperBoundReturnsFalse() {
        bundle.fakeVersion = "138.2"
        XCTAssertFalse(manager.isAppVersion(in: versionRange),
                       "138.2 >138.1 should fail")
    }
}
