// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Growth Points levelling system based on API data
/// Provides convenient access to level information and progress calculations
public struct GrowthPointsLevelSystem {

    // MARK: - Level Information

    /// Gets the current level number from API response
    public static func currentLevel(from response: AccountVisitResponse) -> Int {
        return response.growthPoints.level.number
    }

    /// Gets the localized name for a given level number
    public static func levelName(for levelNumber: Int) -> String {
        switch levelNumber {
        case 1: return String.localized(.ecocurious)
        case 2: return String.localized(.greenExplorer)
        case 3: return String.localized(.planetPal)
        case 4: return String.localized(.seedlingSupporter)
        case 5: return String.localized(.biodiversityBeetle)
        case 6: return String.localized(.forestFriend)
        case 7: return String.localized(.wildlifeProtector)
        case 8: return String.localized(.ecoExplorer)
        case 9: return String.localized(.rainforestReviver)
        case 10: return String.localized(.planetProtector)
        case 11: return String.localized(.carbonNeutralizer)
        case 12: return String.localized(.seekerOfSustainability)
        case 13: return String.localized(.branchBuilder)
        case 14: return String.localized(.ecoEnthusiast)
        case 15: return String.localized(.carbonCutter)
        case 16: return String.localized(.seedSower)
        case 17: return String.localized(.emissionEliminator)
        case 18: return String.localized(.sustainabilitySage)
        case 19: return String.localized(.earthAdvocate)
        case 20: return String.localized(.seedSuperstar)
        default: return String.localized(.ecocurious) // Fallback to level 1
        }
    }

    /// Gets the current level name from API response
    public static func currentLevelName(from response: AccountVisitResponse) -> String {
        return levelName(for: response.growthPoints.level.number)
    }

    /// Gets the previous level number from API response
    public static func previousLevel(from response: AccountVisitResponse) -> Int {
        return response.growthPoints.previousLevel.number
    }

    // MARK: - Progress Information

    /// Calculates progress towards next level from API response (0.0 to 1.0)
    public static func progressToNextLevel(from response: AccountVisitResponse) -> Double {
        return response.progressToNextLevel
    }

    /// Checks if the user leveled up from the API response
    public static func didLevelUp(from response: AccountVisitResponse) -> Bool {
        return response.didLevelUp
    }

    /// Gets growth points earned towards next level
    public static func growthPointsEarned(from response: AccountVisitResponse) -> Int {
        return response.growthPoints.level.growthPointsEarnedTowardsNextLevel
    }

    /// Gets growth points required to unlock next level
    public static func growthPointsRequired(from response: AccountVisitResponse) -> Int {
        return response.growthPoints.level.growthPointsToUnlockNextLevel
    }

    /// Gets seeds rewarded for reaching current level
    public static func seedsRewardedForLevelUp(from response: AccountVisitResponse) -> Int {
        return response.growthPoints.level.seedsRewardedForLevelUp
    }

    /// Gets total growth points required for current level
    public static func totalGrowthPointsRequired(from response: AccountVisitResponse) -> Int {
        return response.growthPoints.level.totalGrowthPointsRequired
    }
}
