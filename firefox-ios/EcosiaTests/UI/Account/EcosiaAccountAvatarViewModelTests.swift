// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Combine
@testable import Ecosia

@available(iOS 16.0, *)
final class EcosiaAccountAvatarViewModelTests: XCTestCase {

    private var viewModel: EcosiaAccountAvatarViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    @MainActor
    func testInitialization_withDefaults() {
        // Given / When
        viewModel = EcosiaAccountAvatarViewModel()

        // Then
        XCTAssertNil(viewModel.avatarURL)
        XCTAssertEqual(viewModel.progress, 0.25)
        XCTAssertFalse(viewModel.showSparkles)
    }

    @MainActor
    func testInitialization_withCustomValues() {
        // Given / When
        viewModel = EcosiaAccountAvatarViewModel(
            progress: 0.75,
            seedCount: 10,
            levelNumber: 3
        )

        // Then
        XCTAssertEqual(viewModel.progress, 0.75)
        XCTAssertEqual(viewModel.seedCount, 10)
        XCTAssertEqual(viewModel.currentLevelNumber, 3)
        XCTAssertFalse(viewModel.showSparkles)
    }

    @MainActor
    func testInitialization_progressClamping() {
        // Given / When
        let viewModelUnder = EcosiaAccountAvatarViewModel(progress: -0.5)
        let viewModelOver = EcosiaAccountAvatarViewModel(progress: 1.5)

        // Then
        XCTAssertEqual(viewModelUnder.progress, 0.0)
        XCTAssertEqual(viewModelOver.progress, 1.0)
    }

    // MARK: - Manual Update Tests

    @MainActor
    func testUpdateAvatarURL() {
        // Given
        viewModel = EcosiaAccountAvatarViewModel()
        let newURL = URL(string: "https://example.com/new-avatar.jpg")

        // When
        viewModel.updateAvatarURL(newURL)

        // Then
        XCTAssertEqual(viewModel.avatarURL, newURL)
    }

    @MainActor
    func testUpdateProgress() {
        // Given
        viewModel = EcosiaAccountAvatarViewModel()

        // When
        viewModel.updateProgress(0.8)

        // Then
        XCTAssertEqual(viewModel.progress, 0.8)
    }

    @MainActor
    func testUpdateProgress_clamping() {
        // Given
        viewModel = EcosiaAccountAvatarViewModel()

        // When
        viewModel.updateProgress(-0.5)
        XCTAssertEqual(viewModel.progress, 0.0)

        viewModel.updateProgress(1.5)
        XCTAssertEqual(viewModel.progress, 1.0)
    }

    @MainActor
    func testTriggerSparkles() async {
        // Given
        viewModel = EcosiaAccountAvatarViewModel()
        XCTAssertFalse(viewModel.showSparkles)

        // When
        viewModel.triggerSparkles(duration: 0.1)

        // Then
        XCTAssertTrue(viewModel.showSparkles)

        // Wait for sparkles to auto-hide
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        XCTAssertFalse(viewModel.showSparkles)
    }

    // MARK: - Notification Tests

    @MainActor
    func testProgressUpdateNotification() {
        // Given / When
        viewModel = EcosiaAccountAvatarViewModel()
        let expectation = XCTestExpectation(description: "Progress updated to 0.6")

        viewModel.$progress
            .dropFirst()
            .sink { progress in
                if progress == 0.6 {
                expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        EcosiaAccountNotificationCenter.postProgressUpdated(progress: 0.6)

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    @MainActor
    func testLevelUpNotification() {
        // Given / When
        viewModel = EcosiaAccountAvatarViewModel()
        let sparklesExpectation = XCTestExpectation(description: "Sparkles triggered")
        let levelExpectation = XCTestExpectation(description: "Level updated")

        viewModel.$showSparkles
            .dropFirst()
            .sink { showSparkles in
                if showSparkles {
                sparklesExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.$currentLevelNumber
            .dropFirst()
            .sink { level in
                if level == 3 {
                    levelExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        EcosiaAccountNotificationCenter.postLevelUp(newLevel: 3, newProgress: 0.9)

        // Then
        wait(for: [sparklesExpectation, levelExpectation], timeout: 1.0)
    }
}

// MARK: - Notification Center Tests
final class EcosiaAccountNotificationCenterTests: XCTestCase {

    func testPostProgressUpdated() {
        // Given
        let expectation = XCTestExpectation(description: "Progress notification received")
        let observer = NotificationCenter.default.addObserver(
            forName: .EcosiaAccountProgressUpdated,
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let progress = userInfo[EcosiaAccountNotificationKeys.progress] as? Double else {
                XCTFail("Expected progress in userInfo")
                return
            }

            XCTAssertEqual(progress, 0.7)
            expectation.fulfill()
        }

        // When
        EcosiaAccountNotificationCenter.postProgressUpdated(progress: 0.7)

        // Then
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }

    func testPostLevelUp() {
        // Given
        let expectation = XCTestExpectation(description: "Level up notification received")
        let observer = NotificationCenter.default.addObserver(
            forName: .EcosiaAccountLevelUp,
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let newLevel = userInfo[EcosiaAccountNotificationKeys.newLevel] as? Int,
                  let newProgress = userInfo[EcosiaAccountNotificationKeys.newProgress] as? Double else {
                XCTFail("Expected level and progress in userInfo")
                return
            }

            XCTAssertEqual(newLevel, 5)
            XCTAssertEqual(newProgress, 0.85)
            expectation.fulfill()
        }

        // When
        EcosiaAccountNotificationCenter.postLevelUp(newLevel: 5, newProgress: 0.85)

        // Then
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
}
