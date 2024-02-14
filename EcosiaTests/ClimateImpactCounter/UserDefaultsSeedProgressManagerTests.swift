// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

/// Remember that we always start from 1 seed and level 1 every time.
final class UserDefaultsSeedProgressManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "CurrentLevel")
        UserDefaults.standard.removeObject(forKey: "TotalSeedsCollected")
        UserDefaults.standard.removeObject(forKey: "LastAppOpenDate")

        // Default Seed Levels for testing (arbitrary levels)
        UserDefaultsSeedProgressManager.seedCounterConfig = SeedCounterConfig(
            sparklesAnimationDuration: 10,
            maxCappedLevel: nil,
            maxCappedSeeds: nil,
            levels: [
                SeedCounterConfig.SeedLevel(level: 1, requiredSeeds: 5),
                SeedCounterConfig.SeedLevel(level: 2, requiredSeeds: 10)
            ]
        )
    }

    // Test the initial state
    func test_initial_seed_progress_state() {
        let level = UserDefaultsSeedProgressManager.loadCurrentLevel()
        let totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()

        XCTAssertEqual(level, 1, "Initial level should be 1")
        XCTAssertEqual(totalSeedsCollected, 1, "Initial totalSeedsCollected should be 1")
    }

    // Test adding seeds, make sure the user stays on level 1 until the required seeds to reach next level are added
    func test_add_seeds_progress_to_next_level() {
        UserDefaultsSeedProgressManager.addSeeds(4)

        var level = UserDefaultsSeedProgressManager.loadCurrentLevel()
        var totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()

        // User should still be in level 1 after collecting exactly 5 seeds
        XCTAssertEqual(level, 1, "User should still be in level 1 after collecting 5 seeds")
        XCTAssertEqual(totalSeedsCollected, 5, "Total seeds should be 5")

        // Add 5 more seeds, now the user should progress to level 2, as 10 seeds total reached
        UserDefaultsSeedProgressManager.addSeeds(5)

        level = UserDefaultsSeedProgressManager.loadCurrentLevel()
        totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()

        XCTAssertEqual(level, 2, "User should progress to level 2 after collecting the 10th seed")
        XCTAssertEqual(totalSeedsCollected, 10, "Total seeds should be 10")
    }

    // Test adding seeds beyond level 1 and keep accumulating for level 2
    func test_add_seeds_beyond_level_1() {
        // Collect 5 seeds, stay in level 1 (4+1)
        UserDefaultsSeedProgressManager.addSeeds(4)

        // Add 2 more seeds, stays at level 1
        UserDefaultsSeedProgressManager.addSeeds(2)

        let level = UserDefaultsSeedProgressManager.loadCurrentLevel()
        let totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()

        XCTAssertEqual(level, 1, "User should still be in level 1 after adding 2 more seed beyond the first level threshold")
        XCTAssertEqual(totalSeedsCollected, 7, "Total seeds should accumulate across levels (6 new added + 1 accumulated at the start")
    }

    // Test inner progress calculation for Level 2
    func test_calculate_inner_progress_for_level_2() {
        UserDefaultsSeedProgressManager.addSeeds(6)  // Collect 7 (1+6) seeds, which puts the user progressing to level 2

        let innerProgress = UserDefaultsSeedProgressManager.calculateInnerProgress()
        XCTAssertEqual(innerProgress, 0.4, accuracy: 0.01, "Inner progress should reflect 40% progress for level 2 after collecting 7 seeds total out of 10")
    }

    // Test resetting the progress to the initial state
    func test_reset_counter() {
        UserDefaultsSeedProgressManager.addSeeds(10)
        UserDefaultsSeedProgressManager.resetCounter()

        let level = UserDefaultsSeedProgressManager.loadCurrentLevel()
        let totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        let innerProgress = UserDefaultsSeedProgressManager.calculateInnerProgress()

        XCTAssertEqual(level, 1, "Reset should set the level to 1")
        XCTAssertEqual(totalSeedsCollected, 1, "Reset should set totalSeedsCollected to 1")
        XCTAssertEqual(innerProgress, 0.2, "Reset should set progress to 20%")
    }

    // Test collecting a seed once per day
    func test_collect_seed_once_per_day() {
        UserDefaultsSeedProgressManager.collectDailySeed()  // First seed collection today
        let totalSeedsAfterFirstCollect = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()

        UserDefaultsSeedProgressManager.collectDailySeed()  // Try collecting another seed today
        let totalSeedsAfterSecondCollect = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()

        XCTAssertEqual(totalSeedsAfterFirstCollect, 1, "Should collect one seed on first open")
        XCTAssertEqual(totalSeedsAfterSecondCollect, 1, "Should not collect more than one seed in a day")
    }

    // Test that a seed can be collected the next day
    func test_collect_seed_next_day() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        UserDefaults.standard.set(yesterday, forKey: "LastAppOpenDate")

        UserDefaultsSeedProgressManager.collectDailySeed()  // Simulate collecting seed today

        let totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        XCTAssertEqual(totalSeedsCollected, 2, "User should be able to collect a seed on a new day")
    }

    // Test that adding seeds beyond the maximum level stops at the maximum seeds for the last level.
    func test_add_seeds_beyond_maximum_level_stops_at_max_seeds_for_last_level() {
        // Add enough seeds to reach level 2
        UserDefaultsSeedProgressManager.addSeeds(9) // +9 seeds; total: 10 seeds (5 from level 1, 5 from level 2)

        // Ensure user is at level 2 and has 10 seeds
        var totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        var currentLevel = UserDefaultsSeedProgressManager.loadCurrentLevel()

        XCTAssertEqual(currentLevel, 2, "User should be at level 2 after collecting 10 seeds.")
        XCTAssertEqual(totalSeedsCollected, 10, "Total seeds should be exactly 10 after reaching level 2.")

        // Now, try to add more seeds beyond the maximum allowed seeds for level 2
        UserDefaultsSeedProgressManager.addSeeds(5) // Try adding +5 seeds

        // Reload the values after adding seeds
        totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        currentLevel = UserDefaultsSeedProgressManager.loadCurrentLevel()

        // Ensure user is still at level 2, and total seeds should be capped at 10
        XCTAssertEqual(currentLevel, 2, "User should remain at level 2, as it's the last level.")
        XCTAssertEqual(totalSeedsCollected, 10, "Total seeds should be capped at 10 (the maximum for level 2) even after adding more seeds.")
    }
}
