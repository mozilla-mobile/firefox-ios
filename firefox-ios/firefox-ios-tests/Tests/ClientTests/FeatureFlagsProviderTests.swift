// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import XCTest

@testable import Client

final class FeatureFlagsProviderTests: XCTestCase {
    private var prefs: MockProfilePrefs!
    private var mockLayer: MockNimbusFeatureFlagLayer!
    private var subject: FeatureFlagsProvider!

    override func setUp() {
        super.setUp()
        prefs = MockProfilePrefs()
        mockLayer = MockNimbusFeatureFlagLayer()
        subject = FeatureFlagsProvider(layer: mockLayer, prefs: prefs)
    }

    override func tearDown() {
        prefs = nil
        mockLayer = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - isEnabled with mock layer

    func testIsEnabled_layerReturnsTrue_returnsTrue() {
        mockLayer.enabledFlags = [.translation]

        XCTAssertTrue(subject.isEnabled(.translation))
    }

    func testIsEnabled_layerReturnsFalse_returnsFalse() {
        mockLayer.enabledFlags = []

        XCTAssertFalse(subject.isEnabled(.translation))
    }

    // MARK: - Debug override behavior

    func testIsEnabled_debugOverrideTrue_overridesLayerFalse() {
        mockLayer.enabledFlags = []
        guard let debugKey = FeatureFlagID.translation.debugKey else {
            XCTFail("translation should have a debugKey")
            return
        }
        prefs.setBool(true, forKey: debugKey)

        #if MOZ_CHANNEL_beta || MOZ_CHANNEL_developer
        XCTAssertTrue(subject.isEnabled(.translation))
        #else
        XCTAssertFalse(subject.isEnabled(.translation))
        #endif
    }

    func testIsEnabled_debugOverrideFalse_overridesLayerTrue() {
        mockLayer.enabledFlags = [.translation]
        guard let debugKey = FeatureFlagID.translation.debugKey else {
            XCTFail("translation should have a debugKey")
            return
        }
        prefs.setBool(false, forKey: debugKey)

        #if MOZ_CHANNEL_beta || MOZ_CHANNEL_developer
        XCTAssertFalse(subject.isEnabled(.translation))
        #else
        XCTAssertTrue(subject.isEnabled(.translation))
        #endif
    }

    func testIsEnabled_flagWithoutDebugKey_ignoresPrefsAndReturnsLayerValue() {
        XCTAssertNil(FeatureFlagID.addressAutofillEdit.debugKey)
        mockLayer.enabledFlags = [.addressAutofillEdit]

        XCTAssertTrue(subject.isEnabled(.addressAutofillEdit))
    }

    func testIsEnabled_flagWithoutDebugKey_returnsFalseFromLayer() {
        XCTAssertNil(FeatureFlagID.addressAutofillEdit.debugKey)
        mockLayer.enabledFlags = []

        XCTAssertFalse(subject.isEnabled(.addressAutofillEdit))
    }

    // MARK: - setDebugOverride

    func testSetDebugOverride_flagWithDebugKey_writesToPrefs() {
        guard let debugKey = FeatureFlagID.translation.debugKey else {
            XCTFail("translation should have a debugKey")
            return
        }

        subject.setDebugOverride(.translation, to: true)

        XCTAssertEqual(prefs.boolForKey(debugKey), true)
    }

    func testSetDebugOverride_flagWithoutDebugKey_doesNotWriteToPrefs() {
        XCTAssertNil(FeatureFlagID.addressAutofillEdit.debugKey)

        subject.setDebugOverride(.addressAutofillEdit, to: true)

        // No key should have been written for this flag
        XCTAssertNil(prefs.boolForKey(
            FeatureFlagID.addressAutofillEdit.rawValue + PrefsKeys.FeatureFlags.DebugSuffixKey
        ))
    }

    // MARK: - MockNimbusFeatureFlags (FeatureFlagProviding) conformance

    func testMockFeatureFlagProvidingConformance() {
        let mock = MockNimbusFeatureFlags()
        mock.enabledFlags = [.translation]

        XCTAssertTrue(mock.isEnabled(.translation))
        XCTAssertFalse(mock.isEnabled(.reportSiteIssue))
    }
}

// MARK: - Test Helpers

final class MockNimbusFeatureFlagLayer: NimbusFeatureFlagLayerProviding, @unchecked Sendable {
    var enabledFlags: Set<FeatureFlagID> = []

    func checkNimbusConfigFor(_ featureID: FeatureFlagID) -> Bool {
        enabledFlags.contains(featureID)
    }
}

final class MockNimbusFeatureFlags: FeatureFlagProviding, @unchecked Sendable {
    var enabledFlags: Set<FeatureFlagID> = []
    var debugOverrides: [FeatureFlagID: Bool] = [:]

    func isEnabled(_ flag: FeatureFlagID) -> Bool {
        enabledFlags.contains(flag)
    }

    func setDebugOverride(_ flag: FeatureFlagID, to value: Bool) {
        debugOverrides[flag] = value
    }
}
