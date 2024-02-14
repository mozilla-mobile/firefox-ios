// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class UserDefaultsSeedProgressManager: SeedProgressManagerProtocol {

    private static let className = String(describing: SeedCounterNTPExperiment.progressManagerType.self)
    static var progressUpdatedNotification: Notification.Name { .init("\(className).SeedProgressUpdated") }
    static var levelUpNotification: Notification.Name { .init("\(className).SeedLevelUp") }
    private static let numberOfSeedsAtStart = 1

    // UserDefaults keys
    private static let totalSeedsCollectedKey = "TotalSeedsCollected"
    private static let currentLevelKey = "CurrentLevel"
    private static let lastAppOpenDateKey = "LastAppOpenDate"

    static var seedCounterConfig: SeedCounterConfig? = SeedCounterNTPExperiment.seedCounterConfig
    private static var seedLevels: [SeedCounterConfig.SeedLevel] { seedCounterConfig?.levels.compactMap { $0 } ?? [] }

    // Fetch max level and max seeds from remote configuration if provided
    private static let maxCappedLevel = seedCounterConfig?.maxCappedLevel
    private static let maxCappedSeeds = seedCounterConfig?.maxCappedSeeds

    private init() {}

    // MARK: - Static Methods

    // Load the current level from UserDefaults
    static func loadCurrentLevel() -> Int {
        let currentLevel = UserDefaults.standard.integer(forKey: currentLevelKey)
        return currentLevel == 0 ? 1 : currentLevel
    }

    // Load the total seeds collected from UserDefaults
    static func loadTotalSeedsCollected() -> Int {
        let seedsCollected = UserDefaults.standard.integer(forKey: totalSeedsCollectedKey)
        return seedsCollected == 0 ? numberOfSeedsAtStart : seedsCollected
    }

    // Load the last app open date from UserDefaults
    static func loadLastAppOpenDate() -> Date {
        return UserDefaults.standard.object(forKey: lastAppOpenDateKey) as? Date ?? .now
    }

    // Save the seed progress and level to UserDefaults
    static func saveProgress(totalSeeds: Int, currentLevel: Int, lastAppOpenDate: Date) {
        let defaults = UserDefaults.standard
        defaults.set(totalSeeds, forKey: totalSeedsCollectedKey)
        defaults.set(currentLevel, forKey: currentLevelKey)
        defaults.set(lastAppOpenDate, forKey: lastAppOpenDateKey)
        NotificationCenter.default.post(name: progressUpdatedNotification, object: nil)
    }

    // Helper method to get the seed threshold for the current level
    private static func requiredSeedsForLevel(_ level: Int) -> Int {
        if let seedLevel = seedLevels.first(where: { $0.level == level }) {
            return seedLevel.requiredSeeds
        }
        return seedLevels.first?.requiredSeeds ?? 0  // If the is no level matching, use the first one
    }

    // Calculate the inner progress for the current level (0 to 1)
    static func calculateInnerProgress() -> CGFloat {
        let totalSeeds = loadTotalSeedsCollected()

        // Find the level config where total seeds fall in the range of the current level and the next level
        guard let currentLevelConfig = seedLevels.first(where: { level in
            let previousLevelSeeds = level.level > 1 ? requiredSeedsForLevel(level.level - 1) : 0
            let nextLevelSeeds = requiredSeedsForLevel(level.level)
            return totalSeeds > previousLevelSeeds && totalSeeds <= nextLevelSeeds
        }) else {
            return 0.0 // Default to 0 if no valid level is found
        }

        let previousLevelSeeds = currentLevelConfig.level > 1 ? requiredSeedsForLevel(currentLevelConfig.level - 1) : 0
        let progressInCurrentLevel = totalSeeds - previousLevelSeeds
        let requiredSeedsForCurrentLevel = currentLevelConfig.requiredSeeds - previousLevelSeeds

        // Return progress as a fraction (between 0 and 1)
        return CGFloat(progressInCurrentLevel) / CGFloat(requiredSeedsForCurrentLevel)
    }

    // Add seeds to the counter and handle level progression
    static func addSeeds(_ count: Int) {
        addSeeds(count, relativeToDate: loadLastAppOpenDate())
    }

    // Add seeds to the counter with a specific date
    static func addSeeds(_ count: Int, relativeToDate date: Date) {
        // Load total seeds and current level from User Defaults
        var totalSeeds = loadTotalSeedsCollected()

        // Fetch the maximum seeds required for the current progression context
        let standardMaxRequiredSeeds = seedLevels.last?.requiredSeeds ?? 0

        // Determine the effective max seeds and level to enforce (capped or classic)
        let effectiveMaxLevel = maxCappedLevel ?? seedLevels.count
        let effectiveMaxRequiredSeeds = maxCappedSeeds ?? standardMaxRequiredSeeds

        // Early exit if the maximum number of seeds is already collected
        if totalSeeds >= effectiveMaxRequiredSeeds {
            return
        }

        var currentLevel = loadCurrentLevel()

        let thresholdForNextLevel = requiredSeedsForLevel(currentLevel + 1)

        totalSeeds += count

        /* 
         If the number of seeds being added (e.g. via "add 5 seeds" debug function) exceeds the max required seeds
         cap the totalSeeds to the maximum required.
         This is useful in case of a seeds multiplier when the configuration has the `maxCappedSeeds` evaluted.
         */
        if totalSeeds >= effectiveMaxRequiredSeeds {
            totalSeeds = effectiveMaxRequiredSeeds
        }

        var leveledUp = false
        // Only level up if the total seeds is equal or exceed the threshold for the level we are reaching to
        if totalSeeds >= thresholdForNextLevel && currentLevel < effectiveMaxLevel {
                currentLevel += 1
                leveledUp = true
        }

        // Save progress with updated total seeds and current level
        saveProgress(totalSeeds: totalSeeds, currentLevel: currentLevel, lastAppOpenDate: date)

        // Notify listeners if leveled up
        if leveledUp {
            NotificationCenter.default.post(name: levelUpNotification, object: nil)
        }
    }

    // Reset the counter to the initial state
    static func resetCounter() {
        saveProgress(totalSeeds: numberOfSeedsAtStart,
                     currentLevel: 1,
                     lastAppOpenDate: .now)
    }

    // Collect a seed once per day
    static func collectDailySeed() {
        let currentDate = Date()
        let lastOpenDate = loadLastAppOpenDate()
        let calendar = Calendar.current

        if calendar.isDateInToday(lastOpenDate) {
            return // Seed already collected today
        }

        // Add 1 seed and save the last open date as today
        addSeeds(1, relativeToDate: currentDate)
    }
}
