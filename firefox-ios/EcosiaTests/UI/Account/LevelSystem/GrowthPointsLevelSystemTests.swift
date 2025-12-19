// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class GrowthPointsLevelSystemTests: XCTestCase {

    // MARK: - Helper Methods

    private func createMockResponse(
        currentLevel: Int = 2,
        previousLevel: Int = 1,
        growthPointsEarned: Int = 125,
        growthPointsRequired: Int = 175
    ) -> AccountVisitResponse {
        let timestamp = "2024-12-07T10:50:26Z"
        return AccountVisitResponse(
            seeds: AccountVisitResponse.Seeds(
                balanceAmount: 10,
                totalAmount: 10,
                previousTotalAmount: 8,
                isModified: true,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            ),
            growthPoints: AccountVisitResponse.GrowthPoints(
                balanceAmount: 200,
                totalAmount: 200,
                previousTotalAmount: 175,
                level: AccountVisitResponse.Level(
                    number: currentLevel,
                    totalGrowthPointsRequired: 75,
                    seedsRewardedForLevelUp: 2,
                    growthPointsToUnlockNextLevel: growthPointsRequired,
                    growthPointsEarnedTowardsNextLevel: growthPointsEarned
                ),
                previousLevel: AccountVisitResponse.Level(
                    number: previousLevel,
                    totalGrowthPointsRequired: 0,
                    seedsRewardedForLevelUp: 1,
                    growthPointsToUnlockNextLevel: 75,
                    growthPointsEarnedTowardsNextLevel: 75
                ),
                isModified: true,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            )
        )
    }

    // MARK: - Level Detection Tests

    func testCurrentLevel() {
        // Given
        let response = createMockResponse(currentLevel: 5)

        // When
        let level = GrowthPointsLevelSystem.currentLevel(from: response)

        // Then
        XCTAssertEqual(level, 5)
    }

    func testPreviousLevel() {
        // Given
        let response = createMockResponse(previousLevel: 3)

        // When
        let level = GrowthPointsLevelSystem.previousLevel(from: response)

        // Then
        XCTAssertEqual(level, 3)
    }

    func testCheckLevelUp_WhenLeveledUp() {
        // Given
        let response = createMockResponse(currentLevel: 3, previousLevel: 2)

        // When
        let didLevelUp = GrowthPointsLevelSystem.didLevelUp(from: response)

        // Then
        XCTAssertTrue(didLevelUp)
    }

    func testCheckLevelUp_WhenNoLevelUp() {
        // Given
        let response = createMockResponse(currentLevel: 2, previousLevel: 2)

        // When
        let didLevelUp = GrowthPointsLevelSystem.didLevelUp(from: response)

        // Then
        XCTAssertFalse(didLevelUp)
    }

    // MARK: - Progress Calculation Tests

    func testProgressToNextLevel_MidProgress() {
        // Given
        // 125 earned out of 175 required = ~0.714
        let response = createMockResponse(growthPointsEarned: 125, growthPointsRequired: 175)

        // When
        let progress = GrowthPointsLevelSystem.progressToNextLevel(from: response)

        // Then
        XCTAssertEqual(progress, 125.0 / 175.0, accuracy: 0.01)
    }

    func testProgressToNextLevel_ZeroProgress() {
        // Given
        let response = createMockResponse(growthPointsEarned: 0, growthPointsRequired: 175)

        // When
        let progress = GrowthPointsLevelSystem.progressToNextLevel(from: response)

        // Then
        XCTAssertEqual(progress, 0.0, accuracy: 0.01)
    }

    func testProgressToNextLevel_FullProgress() {
        // Given
        let response = createMockResponse(growthPointsEarned: 175, growthPointsRequired: 175)

        // When
        let progress = GrowthPointsLevelSystem.progressToNextLevel(from: response)

        // Then
        XCTAssertEqual(progress, 1.0, accuracy: 0.01)
    }

    // MARK: - Growth Points Tests

    func testGrowthPointsEarned() {
        // Given
        let response = createMockResponse(growthPointsEarned: 125)

        // When
        let earned = GrowthPointsLevelSystem.growthPointsEarned(from: response)

        // Then
        XCTAssertEqual(earned, 125)
    }

    func testGrowthPointsRequired() {
        // Given
        let response = createMockResponse(growthPointsRequired: 175)

        // When
        let required = GrowthPointsLevelSystem.growthPointsRequired(from: response)

        // Then
        XCTAssertEqual(required, 175)
    }

    func testSeedsRewardedForLevelUp() {
        // Given
        let response = createMockResponse()

        // When
        let seedsRewarded = GrowthPointsLevelSystem.seedsRewardedForLevelUp(from: response)

        // Then
        XCTAssertEqual(seedsRewarded, 2)
    }

    func testTotalGrowthPointsRequired() {
        // Given
        let response = createMockResponse()

        // When
        let totalRequired = GrowthPointsLevelSystem.totalGrowthPointsRequired(from: response)

        // Then
        XCTAssertEqual(totalRequired, 75)
    }

    // MARK: - Edge Cases

    func testProgressCalculation_WithZeroRequired() {
        // Given
        let timestamp = "2024-12-07T10:50:26Z"
        let response = AccountVisitResponse(
            seeds: AccountVisitResponse.Seeds(
                balanceAmount: 10,
                totalAmount: 10,
                previousTotalAmount: 10,
                isModified: false,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            ),
            growthPoints: AccountVisitResponse.GrowthPoints(
                balanceAmount: 100,
                totalAmount: 100,
                previousTotalAmount: 100,
                level: AccountVisitResponse.Level(
                    number: 1,
                    totalGrowthPointsRequired: 0,
                    seedsRewardedForLevelUp: 0,
                    growthPointsToUnlockNextLevel: 0,
                    growthPointsEarnedTowardsNextLevel: 0
                ),
                previousLevel: AccountVisitResponse.Level(
                    number: 1,
                    totalGrowthPointsRequired: 0,
                    seedsRewardedForLevelUp: 0,
                    growthPointsToUnlockNextLevel: 0,
                    growthPointsEarnedTowardsNextLevel: 0
                ),
                isModified: false,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            )
        )

        // When
        let progress = GrowthPointsLevelSystem.progressToNextLevel(from: response)

        // Then
        XCTAssertEqual(progress, 0.0, accuracy: 0.01)
    }

    // MARK: - Level Thresholds Tests

    func testLevelThresholds_MatchBackendSpecification() {
        // swiftlint:disable large_tuple
        // Given
        let expectedLevels: [(number: Int, totalGrowthPointsRequired: Int, seedsRewardedForLevelUp: Int)] = [
            (1, 0, 0),
            (2, 75, 2),
            (3, 250, 7),
            (4, 500, 12),
            (5, 750, 18),
            (6, 1250, 25),
            (7, 2000, 33),
            (8, 2750, 42),
            (9, 3750, 52),
            (10, 5000, 63),
            (11, 6500, 75),
            (12, 8000, 88),
            (13, 10000, 101),
            (14, 12000, 116),
            (15, 14250, 131),
            (16, 17000, 147),
            (17, 19750, 164),
            (18, 23000, 182),
            (19, 26250, 200),
            (20, 30000, 220)
        ]
        // swiftlint:enable large_tuple
        let timestamp = "2024-12-07T10:50:26Z"

        // When/Then
        for expected in expectedLevels {
            let response = AccountVisitResponse(
                seeds: AccountVisitResponse.Seeds(
                    balanceAmount: 100,
                    totalAmount: 100,
                    previousTotalAmount: 100,
                    isModified: false,
                    lastVisitAt: timestamp,
                    updatedAt: timestamp
                ),
                growthPoints: AccountVisitResponse.GrowthPoints(
                    balanceAmount: expected.totalGrowthPointsRequired,
                    totalAmount: expected.totalGrowthPointsRequired,
                    previousTotalAmount: expected.totalGrowthPointsRequired,
                    level: AccountVisitResponse.Level(
                        number: expected.number,
                        totalGrowthPointsRequired: expected.totalGrowthPointsRequired,
                        seedsRewardedForLevelUp: expected.seedsRewardedForLevelUp,
                        growthPointsToUnlockNextLevel: 100,
                        growthPointsEarnedTowardsNextLevel: 0
                    ),
                    previousLevel: AccountVisitResponse.Level(
                        number: expected.number,
                        totalGrowthPointsRequired: expected.totalGrowthPointsRequired,
                        seedsRewardedForLevelUp: expected.seedsRewardedForLevelUp,
                        growthPointsToUnlockNextLevel: 100,
                        growthPointsEarnedTowardsNextLevel: 0
                    ),
                    isModified: false,
                    lastVisitAt: timestamp,
                    updatedAt: timestamp
                )
            )

            XCTAssertEqual(
                GrowthPointsLevelSystem.currentLevel(from: response),
                expected.number,
                "Level number mismatch for level \(expected.number)"
            )
            XCTAssertEqual(
                GrowthPointsLevelSystem.totalGrowthPointsRequired(from: response),
                expected.totalGrowthPointsRequired,
                "Total growth points mismatch for level \(expected.number)"
            )
            XCTAssertEqual(
                GrowthPointsLevelSystem.seedsRewardedForLevelUp(from: response),
                expected.seedsRewardedForLevelUp,
                "Seeds reward mismatch for level \(expected.number)"
            )
        }
    }
}
