/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Shared
import XCTest

class FeatureSwitchTests: XCTestCase {
    let buildChannel = AppConstants.BuildChannel

    func testPersistent() {
        let featureSwitch = FeatureSwitch(named: "test-persistent-over-restarts", allowPercentage: 50, buildChannel: buildChannel)
        let prefs = MockProfilePrefs()
        var membership = featureSwitch.isMember(prefs)
        var changed = 0
        for _ in 0..<100 {
            if featureSwitch.isMember(prefs) != membership {
                membership = !membership
                changed += 1
            }
        }

        XCTAssertEqual(changed, 0, "Users should get and keep the feature over restarts")
    }

    func testConsistentWhenChangingPercentage() {
        let featureID = "test-persistent-over-releases"
        let prefs = MockProfilePrefs()
        var membership = false
        var changed = 0
        for percent in 0..<100 {
            let featureSwitch = FeatureSwitch(named: featureID, allowPercentage: percent, buildChannel: buildChannel)
            if featureSwitch.isMember(prefs) != membership {
                membership = !membership
                changed += 1
            }
        }

        XCTAssertEqual(changed, 1, "Users should get and keep the feature if the feature is becoming successful")
    }
}

extension FeatureSwitchTests {
    func test0Percent() {
        let featureSwitch = FeatureSwitch(named: "test-never", allowPercentage: 0, buildChannel: buildChannel)
        testExactly(featureSwitch, expected: 0)
        testApprox(featureSwitch, expected: 0)
    }

    func test100Percent() {
        let featureSwitch = FeatureSwitch(named: "test-always", allowPercentage: 100, buildChannel: buildChannel)
        testExactly(featureSwitch, expected: 100)
        testApprox(featureSwitch, expected: 100)
    }

    func test50Percent() {
        let featureSwitch = FeatureSwitch(named: "test-half-the-population", allowPercentage: 50, buildChannel: buildChannel)
        testApprox(featureSwitch, expected: 50)
    }

    func test30Percent() {
        let featureSwitch = FeatureSwitch(named: "test-30%-population", allowPercentage: 30, buildChannel: buildChannel)
        testApprox(featureSwitch, expected: 30)
    }

    func testPerformance() {
        let featureSwitch = FeatureSwitch(named: "test-30%-population", allowPercentage: 30, buildChannel: buildChannel)
        let prefs = MockProfilePrefs()
        measure {
            for _ in 0..<1000 {
                let _ = featureSwitch.isMember(prefs)
            }
        }
    }

    func testAppConstantsWin() {
        // simulate in release channel, but switched off in AppConstants.
        let featureFlaggedOff = FeatureSwitch(named: "test-release-flagged-off", false, allowPercentage: 100, buildChannel: buildChannel)
        testExactly(featureFlaggedOff, expected: 0)

        // simulate in non-release channel, but switched on in AppConstants.
        let buildChannelAndFlaggedOn = FeatureSwitch(named: "test-flagged-on", true, allowPercentage: 0)
        testExactly(buildChannelAndFlaggedOn, expected: 100)

        // simulate in non-release channel, but switched off in AppConstants.
        let buildChannelAndFlaggedOff = FeatureSwitch(named: "test-flagged-off", false, allowPercentage: 100)
        testExactly(buildChannelAndFlaggedOff, expected: 0)
    }
}

private extension FeatureSwitchTests {
    func sampleN(_ featureSwitch: FeatureSwitch, testCount: Int = 1000) -> Int {
        var count = 0
        for _ in 0..<testCount {
            let prefs = MockProfilePrefs()
            if featureSwitch.isMember(prefs) {
                count += 1
            }
        }
        return count
    }

    func testExactly(_ featureSwitch: FeatureSwitch, expected: Int) {
        let testCount = 10
        let count = sampleN(featureSwitch, testCount: testCount)
        let normalizedExpectedCount = (testCount * expected) / 100
        XCTAssertEqual(count, normalizedExpectedCount)
    }

    func testApprox(_ featureSwitch: FeatureSwitch, expected: Int, epsilon: Int = 2) {
        let testCount = 10000
        let count = sampleN(featureSwitch, testCount: testCount)
        let acceptableRange = Range(uncheckedBounds: (
            lower: testCount * (expected - epsilon) / 100,
            upper: testCount * (expected + epsilon) / 100))
        
        XCTAssertTrue(acceptableRange.contains(count), "\(count) in \(acceptableRange)?")
    }
}
