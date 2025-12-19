// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class AccountsServiceTests: XCTestCase {

    private var mockHTTPClient: HTTPClientMock!
    private var accountsService: AccountsService!

    override func setUp() {
        super.setUp()
        mockHTTPClient = HTTPClientMock()
        accountsService = AccountsService(client: mockHTTPClient)
    }

    func testRegisterVisit_Success() async throws {
        // Arrange
        let timestamp = "2024-12-07T10:50:26Z"
        let expectedResponse = AccountVisitResponse(
            seeds: AccountVisitResponse.Seeds(
                balanceAmount: 5,
                totalAmount: 5,
                previousTotalAmount: 4,
                isModified: true,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            ),
            growthPoints: AccountVisitResponse.GrowthPoints(
                balanceAmount: 100,
                totalAmount: 100,
                previousTotalAmount: 75,
                level: AccountVisitResponse.Level(
                    number: 2,
                    totalGrowthPointsRequired: 75,
                    seedsRewardedForLevelUp: 2,
                    growthPointsToUnlockNextLevel: 175,
                    growthPointsEarnedTowardsNextLevel: 25
                ),
                previousLevel: AccountVisitResponse.Level(
                    number: 1,
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
        let responseData = try JSONEncoder().encode(expectedResponse)
        mockHTTPClient.data = responseData
        mockHTTPClient.response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        // Act
        let response = try await accountsService.registerVisit(accessToken: "test-access-token")

        // Assert
        XCTAssertEqual(response.seeds.totalAmount, 5)
        XCTAssertEqual(response.seeds.isModified, true)
        XCTAssertEqual(response.seeds.previousTotalAmount, 4)
        XCTAssertEqual(response.seedsIncrement, 1)
        XCTAssertEqual(response.growthPoints.level.number, 2)
        XCTAssertTrue(response.didLevelUp)
        XCTAssertEqual(mockHTTPClient.requests.count, 1)

        let request = mockHTTPClient.requests.first as? AccountVisitRequest
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.additionalHeaders?["Authorization"], "Bearer test-access-token")
    }

    func testRegisterVisit_NetworkError() async throws {
        // Arrange
        mockHTTPClient.response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )

        // Act & Assert
        do {
            _ = try await accountsService.registerVisit(accessToken: "test-access-token")
            XCTFail("Expected network error")
        } catch AccountsService.Error.network {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSeedsIncrement_NoChange() {
        // Arrange
        let timestamp = "2024-12-07T10:50:26Z"
        let response = AccountVisitResponse(
            seeds: AccountVisitResponse.Seeds(
                balanceAmount: 5,
                totalAmount: 5,
                previousTotalAmount: 5,
                isModified: false,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            ),
            growthPoints: AccountVisitResponse.GrowthPoints(
                balanceAmount: 100,
                totalAmount: 100,
                previousTotalAmount: 100,
                level: AccountVisitResponse.Level(
                    number: 2,
                    totalGrowthPointsRequired: 75,
                    seedsRewardedForLevelUp: 2,
                    growthPointsToUnlockNextLevel: 175,
                    growthPointsEarnedTowardsNextLevel: 25
                ),
                previousLevel: AccountVisitResponse.Level(
                    number: 2,
                    totalGrowthPointsRequired: 75,
                    seedsRewardedForLevelUp: 2,
                    growthPointsToUnlockNextLevel: 175,
                    growthPointsEarnedTowardsNextLevel: 25
                ),
                isModified: false,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            )
        )

        // Act & Assert
        XCTAssertNil(response.seedsIncrement)
    }

    func testSeedsIncrement_WithChange() {
        // Arrange
        let timestamp = "2024-12-07T10:50:26Z"
        let response = AccountVisitResponse(
            seeds: AccountVisitResponse.Seeds(
                balanceAmount: 8,
                totalAmount: 8,
                previousTotalAmount: 5,
                isModified: true,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            ),
            growthPoints: AccountVisitResponse.GrowthPoints(
                balanceAmount: 100,
                totalAmount: 100,
                previousTotalAmount: 75,
                level: AccountVisitResponse.Level(
                    number: 2,
                    totalGrowthPointsRequired: 75,
                    seedsRewardedForLevelUp: 2,
                    growthPointsToUnlockNextLevel: 175,
                    growthPointsEarnedTowardsNextLevel: 25
                ),
                previousLevel: AccountVisitResponse.Level(
                    number: 2,
                    totalGrowthPointsRequired: 75,
                    seedsRewardedForLevelUp: 2,
                    growthPointsToUnlockNextLevel: 175,
                    growthPointsEarnedTowardsNextLevel: 0
                ),
                isModified: true,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            )
        )

        // Act & Assert
        XCTAssertEqual(response.seedsIncrement, 3)
    }

    func testRegisterVisit_UnauthorizedError() async throws {
        // Arrange
        mockHTTPClient.response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )

        // Act & Assert
        do {
            _ = try await accountsService.registerVisit(accessToken: "invalid-token")
            XCTFail("Expected unauthorized error")
        } catch AccountsService.Error.authenticationRequired {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGrowthPointsIncrement() {
        // Arrange
        let timestamp = "2024-12-07T10:50:26Z"
        let response = AccountVisitResponse(
            seeds: AccountVisitResponse.Seeds(
                balanceAmount: 5,
                totalAmount: 5,
                previousTotalAmount: 4,
                isModified: true,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            ),
            growthPoints: AccountVisitResponse.GrowthPoints(
                balanceAmount: 200,
                totalAmount: 200,
                previousTotalAmount: 175,
                level: AccountVisitResponse.Level(
                    number: 2,
                    totalGrowthPointsRequired: 75,
                    seedsRewardedForLevelUp: 2,
                    growthPointsToUnlockNextLevel: 175,
                    growthPointsEarnedTowardsNextLevel: 125
                ),
                previousLevel: AccountVisitResponse.Level(
                    number: 2,
                    totalGrowthPointsRequired: 75,
                    seedsRewardedForLevelUp: 2,
                    growthPointsToUnlockNextLevel: 175,
                    growthPointsEarnedTowardsNextLevel: 100
                ),
                isModified: true,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            )
        )

        // Act & Assert
        XCTAssertEqual(response.growthPointsIncrement, 25)
    }

    func testLevelUp_Detection() {
        // Arrange
        let timestamp = "2024-12-07T10:50:26Z"
        let response = AccountVisitResponse(
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
                    number: 3,
                    totalGrowthPointsRequired: 150,
                    seedsRewardedForLevelUp: 3,
                    growthPointsToUnlockNextLevel: 250,
                    growthPointsEarnedTowardsNextLevel: 50
                ),
                previousLevel: AccountVisitResponse.Level(
                    number: 2,
                    totalGrowthPointsRequired: 75,
                    seedsRewardedForLevelUp: 2,
                    growthPointsToUnlockNextLevel: 175,
                    growthPointsEarnedTowardsNextLevel: 100
                ),
                isModified: true,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            )
        )

        // Act & Assert
        XCTAssertTrue(response.didLevelUp)
        XCTAssertEqual(response.growthPoints.level.number, 3)
        XCTAssertEqual(response.growthPoints.previousLevel.number, 2)
    }

    func testProgressToNextLevel_Calculation() {
        // Arrange
        let timestamp = "2024-12-07T10:50:26Z"
        let response = AccountVisitResponse(
            seeds: AccountVisitResponse.Seeds(
                balanceAmount: 5,
                totalAmount: 5,
                previousTotalAmount: 5,
                isModified: false,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            ),
            growthPoints: AccountVisitResponse.GrowthPoints(
                balanceAmount: 100,
                totalAmount: 100,
                previousTotalAmount: 100,
                level: AccountVisitResponse.Level(
                    number: 2,
                    totalGrowthPointsRequired: 75,
                    seedsRewardedForLevelUp: 2,
                    growthPointsToUnlockNextLevel: 175,
                    growthPointsEarnedTowardsNextLevel: 125
                ),
                previousLevel: AccountVisitResponse.Level(
                    number: 2,
                    totalGrowthPointsRequired: 75,
                    seedsRewardedForLevelUp: 2,
                    growthPointsToUnlockNextLevel: 175,
                    growthPointsEarnedTowardsNextLevel: 125
                ),
                isModified: false,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            )
        )

        // Act
        let progress = response.progressToNextLevel

        // Assert
        XCTAssertEqual(progress, 125.0 / 175.0, accuracy: 0.01)
    }

    func testGrowthPointsIncrement_NoChange() {
        // Arrange
        let timestamp = "2024-12-07T10:50:26Z"
        let response = AccountVisitResponse(
            seeds: AccountVisitResponse.Seeds(
                balanceAmount: 5,
                totalAmount: 5,
                previousTotalAmount: 5,
                isModified: false,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            ),
            growthPoints: AccountVisitResponse.GrowthPoints(
                balanceAmount: 100,
                totalAmount: 100,
                previousTotalAmount: 100,
                level: AccountVisitResponse.Level(
                    number: 2,
                    totalGrowthPointsRequired: 75,
                    seedsRewardedForLevelUp: 2,
                    growthPointsToUnlockNextLevel: 175,
                    growthPointsEarnedTowardsNextLevel: 125
                ),
                previousLevel: AccountVisitResponse.Level(
                    number: 2,
                    totalGrowthPointsRequired: 75,
                    seedsRewardedForLevelUp: 2,
                    growthPointsToUnlockNextLevel: 175,
                    growthPointsEarnedTowardsNextLevel: 125
                ),
                isModified: false,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            )
        )

        // Act & Assert
        XCTAssertNil(response.growthPointsIncrement)
    }
}
