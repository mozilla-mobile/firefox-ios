// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

/// Remember that we always start from 1 seed and level 1 every time.
final class UnleashUserDefaultsSeedProgressManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "CurrentLevel")
        UserDefaults.standard.removeObject(forKey: "TotalSeedsCollected")
        UserDefaults.standard.removeObject(forKey: "LastAppOpenDate")
    }

    // Test experimental cap with maxCappedLevel and maxCappedSeeds using current Unleash JSON-provided levels
    func test_experimental_cap_respected_with_json_provided_levels() {
        // Update the config to use experimental cap with JSON-provided levels
        UserDefaultsSeedProgressManager.seedCounterConfig = SeedCounterConfig(
            sparklesAnimationDuration: 10,
            maxCappedLevel: 2,
            maxCappedSeeds: 10,
            levels: [
                SeedCounterConfig.SeedLevel(level: 1, requiredSeeds: 1),
                SeedCounterConfig.SeedLevel(level: 2, requiredSeeds: 3),
                SeedCounterConfig.SeedLevel(level: 3, requiredSeeds: 10)
            ]
        )

        // Add enough seeds to reach max capped seeds (10)
        UserDefaultsSeedProgressManager.addSeeds(9) // +9 seeds; total: 10 seeds (1 initially)

        // Ensure user is capped at 10 seeds
        let totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        let currentLevel = UserDefaultsSeedProgressManager.loadCurrentLevel()

        XCTAssertEqual(currentLevel, 2, "User should reach level 2, but not go beyond.")
        XCTAssertEqual(totalSeedsCollected, 10, "Total seeds should be capped at 10 as per the experiment.")
    }

    // Test with JSON-provided seed levels for regular progression
    func test_add_seeds_with_json_provided_levels() {
        // Update the config to use current Unleash's JSON-provided levels
        UserDefaultsSeedProgressManager.seedCounterConfig = SeedCounterConfig(
            sparklesAnimationDuration: 10,
            maxCappedLevel: nil,
            maxCappedSeeds: nil,
            levels: [
                SeedCounterConfig.SeedLevel(level: 1, requiredSeeds: 1),
                SeedCounterConfig.SeedLevel(level: 2, requiredSeeds: 3),
                SeedCounterConfig.SeedLevel(level: 3, requiredSeeds: 10)
            ]
        )

        // Add seeds to test progression through current Unleash's JSON-defined levels
        UserDefaultsSeedProgressManager.addSeeds(2) // +2 seed; total: 3 seeds (1 initial + 2 added)
        var totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        var currentLevel = UserDefaultsSeedProgressManager.loadCurrentLevel()

        XCTAssertEqual(currentLevel, 2, "User should reach level 2 after collecting 3 seeds in total.")
        XCTAssertEqual(totalSeedsCollected, 3, "Total seeds should be 3.")

        // Add more seeds to progress to level 3
        UserDefaultsSeedProgressManager.addSeeds(7) // +7 seeds; total: 10 seeds
        totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        currentLevel = UserDefaultsSeedProgressManager.loadCurrentLevel()

        XCTAssertEqual(currentLevel, 3, "User should reach level 3 after collecting 10 seeds.")
        XCTAssertEqual(totalSeedsCollected, 10, "Total seeds should be exactly 10.")
    }
}
