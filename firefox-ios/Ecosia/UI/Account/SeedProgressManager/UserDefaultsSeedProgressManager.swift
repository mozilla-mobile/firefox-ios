// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Manages local seed collection and progression for logged-out users.
///
/// This manager persists seed progress locally using `UserDefaults` and is intended
/// exclusively for tracking seeds collected by users who are not logged in. When users
/// log in, their seed progress is managed server-side through the account system.
///
/// ## Local Storage
///
/// The manager stores three key values in `UserDefaults`:
/// - Total seeds collected since first app launch
/// - Current level based on seed thresholds
/// - Last app open date for daily seed collection
///
/// ## Level Progression
///
/// Seed levels and thresholds are configured via `SeedCounterConfig`, which can be
/// remotely configured. The manager automatically handles level-up transitions when
/// seed thresholds are met and posts notifications for UI updates.
///
/// ## Important
///
/// This manager should only be used for logged-out users. Server-based seed management
/// takes precedence for authenticated users.
public final class UserDefaultsSeedProgressManager: SeedProgressManagerProtocol {

    private static let className = String(describing: UserDefaultsSeedProgressManager.self)
    public static let maxSeedsForLoggedOutUsers = 3
    public static var progressUpdatedNotification: Notification.Name { .init("\(className).SeedProgressUpdated") }
    public static var levelUpNotification: Notification.Name { .init("\(className).SeedLevelUp") }

    // UserDefaults keys
    private static let totalSeedsCollectedKey = "TotalSeedsCollected"
    private static let currentLevelKey = "CurrentLevel"
    private static let lastAppOpenDateKey = "LastAppOpenDate"

    public static var seedCounterConfig: SeedCounterConfig?
    private static var seedLevels: [SeedCounterConfig.SeedLevel] { seedCounterConfig?.levels.compactMap { $0 } ?? [] }

    // Fetch max level and max seeds from remote configuration if provided
    private static let maxCappedLevel = seedCounterConfig?.maxCappedLevel
    private static let maxCappedSeeds = seedCounterConfig?.maxCappedSeeds

    private init() {}

    // MARK: - Static Methods

    /// Loads the current level from UserDefaults.
    ///
    /// - Returns: The current level, defaulting to 1 if not set.
    public static func loadCurrentLevel() -> Int {
        let currentLevel = UserDefaults.standard.integer(forKey: currentLevelKey)
        return currentLevel == 0 ? 1 : currentLevel
    }

    /// Loads the total seeds collected from UserDefaults.
    ///
    /// - Returns: The total number of seeds collected. Returns 0 for first-time users.
    public static func loadTotalSeedsCollected() -> Int {
        return UserDefaults.standard.integer(forKey: totalSeedsCollectedKey)
    }

    /// Loads the last app open date from UserDefaults.
    ///
    /// - Returns: The last date the app was opened and a seed was collected, or `nil` if this is the first launch.
    public static func loadLastAppOpenDate() -> Date? {
        return UserDefaults.standard.object(forKey: lastAppOpenDateKey) as? Date
    }

    /// Saves the seed progress and level to UserDefaults.
    ///
    /// Posts a `progressUpdatedNotification` after saving.
    ///
    /// - Parameters:
    ///   - totalSeeds: The total number of seeds to save.
    ///   - currentLevel: The current level to save.
    ///   - lastAppOpenDate: The date to record as the last app open.
    public static func saveProgress(totalSeeds: Int, currentLevel: Int, lastAppOpenDate: Date) {
        let defaults = UserDefaults.standard
        defaults.set(totalSeeds, forKey: totalSeedsCollectedKey)
        defaults.set(currentLevel, forKey: currentLevelKey)
        defaults.set(lastAppOpenDate, forKey: lastAppOpenDateKey)
        NotificationCenter.default.post(name: progressUpdatedNotification, object: nil)
    }

    /// Returns the seed threshold required for a specific level.
    ///
    /// - Parameter level: The level to query.
    /// - Returns: The number of seeds required for the level, or 0 if not found.
    private static func requiredSeedsForLevel(_ level: Int) -> Int {
        if let seedLevel = seedLevels.first(where: { $0.level == level }) {
            return seedLevel.requiredSeeds
        }
        return seedLevels.first?.requiredSeeds ?? 0  // If the is no level matching, use the first one
    }

    /// Calculates the inner progress for the current level as a fraction from 0 to 1.
    ///
    /// - Returns: A value between 0.0 and 1.0 representing progress within the current level.
    public static func calculateInnerProgress() -> CGFloat {
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

    /// Adds seeds to the counter, using the current date.
    ///
    /// Enforces the maximum seed cap for logged-out users.
    ///
    /// - Parameter count: The number of seeds to add.
    public static func addSeeds(_ count: Int) {
        addSeeds(count, relativeToDate: .now)
    }

    /// Adds seeds to the counter with a specific date.
    ///
    /// Enforces the maximum seed cap for logged-out users (3 seeds).
    /// Posts a `progressUpdatedNotification` after adding seeds.
    ///
    /// - Parameters:
    ///   - count: The number of seeds to add.
    ///   - date: The date to record as the last app open.
    public static func addSeeds(_ count: Int, relativeToDate date: Date) {
        // Load total seeds
        var totalSeeds = loadTotalSeedsCollected()

        EcosiaLogger.accounts.info("Seed cap enforced for logged-out user: max \(maxSeedsForLoggedOutUsers) seeds")

        if totalSeeds >= maxSeedsForLoggedOutUsers {
            return
        }

        totalSeeds += count

        if totalSeeds >= maxSeedsForLoggedOutUsers {
            totalSeeds = maxSeedsForLoggedOutUsers
        }

        saveProgress(totalSeeds: totalSeeds, currentLevel: 1, lastAppOpenDate: date)
        NotificationCenter.default.post(name: progressUpdatedNotification, object: nil)
    }

    /// Resets the local seed progress to initial state (0 seeds, level 1, no last open date).
    ///
    /// Clears the last app open date to allow immediate seed collection.
    /// Used on logout to prepare for fresh local seed collection.
    public static func resetLocalSeedProgress() {
        UserDefaults.standard.set(0, forKey: totalSeedsCollectedKey)
        UserDefaults.standard.set(1, forKey: currentLevelKey)
        UserDefaults.standard.removeObject(forKey: lastAppOpenDateKey)
        NotificationCenter.default.post(name: progressUpdatedNotification, object: nil)
    }

    /// Collects a seed once per day for logged-out users.
    ///
    /// On first launch (no previous date saved), always collects a seed.
    /// On subsequent launches, only collects if a new day has started since the last collection.
    public static func collectDailySeed() {
        let currentDate = Date()
        let lastOpenDate = loadLastAppOpenDate()
        let calendar = Calendar.current

        guard let lastOpenDate = lastOpenDate else {
            EcosiaLogger.accounts.info("First seed collection for new user")
            addSeeds(1, relativeToDate: currentDate)
            return
        }

        if calendar.isDateInToday(lastOpenDate) {
            return // Seed already collected today
        }

        addSeeds(1, relativeToDate: currentDate)
    }
}
