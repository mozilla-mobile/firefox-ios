// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct AccountVisitResponse: Codable {
    public let seeds: Seeds
    public let growthPoints: GrowthPoints

    public init(seeds: Seeds, growthPoints: GrowthPoints) {
        self.seeds = seeds
        self.growthPoints = growthPoints
    }

    public struct Seeds: Codable {
        public let balanceAmount: Int
        public let totalAmount: Int
        public let previousTotalAmount: Int
        public let isModified: Bool
        public let lastVisitAt: String
        public let updatedAt: String

        public init(balanceAmount: Int, totalAmount: Int, previousTotalAmount: Int, isModified: Bool, lastVisitAt: String, updatedAt: String) {
            self.balanceAmount = balanceAmount
            self.totalAmount = totalAmount
            self.previousTotalAmount = previousTotalAmount
            self.isModified = isModified
            self.lastVisitAt = lastVisitAt
            self.updatedAt = updatedAt
        }
    }

    public struct GrowthPoints: Codable {
        public let balanceAmount: Int
        public let totalAmount: Int
        public let previousTotalAmount: Int
        public let level: Level
        public let previousLevel: Level
        public let isModified: Bool
        public let lastVisitAt: String
        public let updatedAt: String

        public init(balanceAmount: Int, totalAmount: Int, previousTotalAmount: Int, level: Level, previousLevel: Level, isModified: Bool, lastVisitAt: String, updatedAt: String) {
            self.balanceAmount = balanceAmount
            self.totalAmount = totalAmount
            self.previousTotalAmount = previousTotalAmount
            self.level = level
            self.previousLevel = previousLevel
            self.isModified = isModified
            self.lastVisitAt = lastVisitAt
            self.updatedAt = updatedAt
        }
    }

    public struct Level: Codable {
        public let number: Int
        public let totalGrowthPointsRequired: Int
        public let seedsRewardedForLevelUp: Int
        public let growthPointsToUnlockNextLevel: Int
        public let growthPointsEarnedTowardsNextLevel: Int

        public init(number: Int, totalGrowthPointsRequired: Int, seedsRewardedForLevelUp: Int, growthPointsToUnlockNextLevel: Int, growthPointsEarnedTowardsNextLevel: Int) {
            self.number = number
            self.totalGrowthPointsRequired = totalGrowthPointsRequired
            self.seedsRewardedForLevelUp = seedsRewardedForLevelUp
            self.growthPointsToUnlockNextLevel = growthPointsToUnlockNextLevel
            self.growthPointsEarnedTowardsNextLevel = growthPointsEarnedTowardsNextLevel
        }
    }

    // MARK: - Convenience Properties

    /// Seeds increment, returns value only if seeds were modified
    public var seedsIncrement: Int? {
        guard seeds.isModified else { return nil }
        return seeds.totalAmount - seeds.previousTotalAmount
    }

    /// Growth points increment, returns value only if growth points were modified
    public var growthPointsIncrement: Int? {
        guard growthPoints.isModified else { return nil }
        return growthPoints.totalAmount - growthPoints.previousTotalAmount
    }

    /// Returns true if user leveled up
    public var didLevelUp: Bool {
        return growthPoints.level.number > growthPoints.previousLevel.number
    }

    /// Progress towards next level (0.0 to 1.0)
    public var progressToNextLevel: Double {
        let earned = growthPoints.level.growthPointsEarnedTowardsNextLevel
        let required = growthPoints.level.growthPointsToUnlockNextLevel
        guard required > 0 else { return 0.0 }
        return Double(earned) / Double(required)
    }
}
