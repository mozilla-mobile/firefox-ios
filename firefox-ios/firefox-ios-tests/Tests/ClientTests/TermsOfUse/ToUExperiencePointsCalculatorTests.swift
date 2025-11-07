// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

final class ToUExperiencePointsCalculatorTests: XCTestCase {
    var userDefaults: MockUserDefaults!

    override func setUp() {
        super.setUp()
        userDefaults = MockUserDefaults()
    }

    override func tearDown() {
        userDefaults = nil
        super.tearDown()
    }

    func testCalculatePoints_ZeroPoints_WhenNoSettingsEnabled() {
        let calculator = ToUExperiencePointsCalculator(userDefaults: userDefaults, region: "US")
        XCTAssertEqual(calculator.calculatePoints(), 0)
    }

    func testCalculatePoints_ZeroPoints_WhenUnsupportedCountry() {
        let sponsoredKey = ProfilePrefsReader.prefix + PrefsKeys.FeatureFlags.SponsoredShortcuts
        userDefaults.set(false, forKey: sponsoredKey)

        let calculator = ToUExperiencePointsCalculator(userDefaults: userDefaults, region: "CN")
        XCTAssertEqual(calculator.calculatePoints(), 0)
    }

    func testCalculatePoints_OnePoint_WhenETPStrict() {
        let enabledKey = ProfilePrefsReader.prefix + ContentBlockingConfig.Prefs.EnabledKey
        let strengthKey = ProfilePrefsReader.prefix + ContentBlockingConfig.Prefs.StrengthKey
        userDefaults.set(true, forKey: enabledKey)
        userDefaults.set(BlockingStrength.strict.rawValue, forKey: strengthKey)

        let calculator = ToUExperiencePointsCalculator(userDefaults: userDefaults, region: "US")
        XCTAssertEqual(calculator.calculatePoints(), 1)
    }

    func testCalculatePoints_OnePoint_WhenSponsoredDisabled() {
        let sponsoredKey = ProfilePrefsReader.prefix + PrefsKeys.FeatureFlags.SponsoredShortcuts
        userDefaults.set(false, forKey: sponsoredKey)

        let calculator = ToUExperiencePointsCalculator(userDefaults: userDefaults, region: "US")
        XCTAssertEqual(calculator.calculatePoints(), 1)
    }

    func testCalculatePoints_TwoPoints_WhenBothEnabled() {
        let enabledKey = ProfilePrefsReader.prefix + ContentBlockingConfig.Prefs.EnabledKey
        let strengthKey = ProfilePrefsReader.prefix + ContentBlockingConfig.Prefs.StrengthKey
        let sponsoredKey = ProfilePrefsReader.prefix + PrefsKeys.FeatureFlags.SponsoredShortcuts

        userDefaults.set(true, forKey: enabledKey)
        userDefaults.set(BlockingStrength.strict.rawValue, forKey: strengthKey)
        userDefaults.set(false, forKey: sponsoredKey)

        let calculator = ToUExperiencePointsCalculator(userDefaults: userDefaults, region: "DE")
        XCTAssertEqual(calculator.calculatePoints(), 2)
    }
}
