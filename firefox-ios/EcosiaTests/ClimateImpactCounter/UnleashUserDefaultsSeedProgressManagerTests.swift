// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia
@testable import Client

/// Tests for local seed collection system. Logged-out users start at 0 seeds and level 1.
/// They are capped at 3 seeds and always remain at level 1 (no level progression).
final class UnleashUserDefaultsSeedProgressManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "CurrentLevel")
        UserDefaults.standard.removeObject(forKey: "TotalSeedsCollected")
        UserDefaults.standard.removeObject(forKey: "LastAppOpenDate")
    }

    // Test that logged-out users are capped at 3 seeds even with config override
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

        // Attempt to add seeds beyond the 3-seed cap for logged-out users
        UserDefaultsSeedProgressManager.addSeeds(3) // +3 seeds; total: 3 seeds (capped)

        // Ensure user is capped at 3 seeds and stays at level 1
        let totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        let currentLevel = UserDefaultsSeedProgressManager.loadCurrentLevel()

        XCTAssertEqual(currentLevel, 1, "User should always stay at level 1.")
        XCTAssertEqual(totalSeedsCollected, 3, "Total seeds should be capped at 3 for logged-out users.")
    }

    // Test that logged-out users never level up regardless of config
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

        // Add seeds up to the 3-seed cap
        UserDefaultsSeedProgressManager.addSeeds(2) // +2 seeds; total: 2 seeds
        var totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        var currentLevel = UserDefaultsSeedProgressManager.loadCurrentLevel()

        XCTAssertEqual(currentLevel, 1, "User should always stay at level 1.")
        XCTAssertEqual(totalSeedsCollected, 2, "Total seeds should be 2.")

        // Add more seeds to reach 3-seed cap
        UserDefaultsSeedProgressManager.addSeeds(1) // +1 seed; total: 3 seeds
        totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        currentLevel = UserDefaultsSeedProgressManager.loadCurrentLevel()

        XCTAssertEqual(currentLevel, 1, "User should always stay at level 1.")
        XCTAssertEqual(totalSeedsCollected, 3, "Total seeds should be capped at 3.")
    }
}
