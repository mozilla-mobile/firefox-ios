// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import SwiftUI
@testable import Ecosia

@available(iOS 16.0, *)
final class EcosiaAccountAvatarPerformanceTests: XCTestCase {

    // MARK: - Performance Tests

    @MainActor
    func testViewModelInitializationPerformance() {
        // Test that ViewModel initialization is fast (Apple recommends < 16ms for UI)
        measure {
            for _ in 0..<100 {
                _ = EcosiaAccountAvatarViewModel(
                    avatarURL: URL(string: "https://example.com/avatar.jpg"),
                    progress: 0.75
                )
            }
        }
    }

    @MainActor
    func testProgressUpdatePerformance() {
        // Test that progress updates are fast enough for smooth animations
        let viewModel = EcosiaAccountAvatarViewModel()

        measure {
            for i in 0..<1000 {
                let progress = Double(i % 100) / 100.0
                viewModel.updateProgress(progress)
            }
        }
    }

    @MainActor
    func testSparkleAnimationTriggerPerformance() {
        // Test that sparkle animation triggering is responsive
        let viewModel = EcosiaAccountAvatarViewModel()

        measure {
            for _ in 0..<50 {
                viewModel.triggerSparkles(duration: 0.1)
            }
        }
    }

    // MARK: - Responsiveness Tests

    func testMainThreadResponsiveness() {
        // Test that our notification handlers don't block the main thread
        let startTime = CFAbsoluteTimeGetCurrent()
        let iterations = 1000

        for i in 0..<iterations {
            let progress = Double(i % 100) / 100.0
            EcosiaAccountNotificationCenter.postProgressUpdated(progress: progress)
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        let averageTime = totalTime / Double(iterations)

        // Apple recommends keeping UI updates under 16ms (60 FPS)
        XCTAssertLessThan(averageTime, 0.016, "Notification handling should be under 16ms per operation")
    }
}

// MARK: - Integration Tests
@available(iOS 16.0, *)
final class EcosiaAccountAvatarIntegrationTests: XCTestCase {

    @MainActor
    func testFullWorkflow() {
        // Test complete user workflow
        let viewModel = EcosiaAccountAvatarViewModel()

        // 1. Start signed out
        XCTAssertNil(viewModel.avatarURL)
        XCTAssertEqual(viewModel.progress, 0.25)
        XCTAssertFalse(viewModel.showSparkles)

        // 2. User signs in
        viewModel.updateAvatarURL(URL(string: "https://example.com/avatar.jpg"))
        viewModel.updateProgress(0.4)

        XCTAssertNotNil(viewModel.avatarURL)
        XCTAssertEqual(viewModel.progress, 0.4)

        // 3. User gains progress
        viewModel.updateProgress(0.7)
        XCTAssertEqual(viewModel.progress, 0.7)

        // 4. User levels up
        viewModel.updateProgress(0.9)
        viewModel.triggerSparkles()

        XCTAssertEqual(viewModel.progress, 0.9)
        XCTAssertTrue(viewModel.showSparkles)

        // 5. Sparkles auto-hide (test async behavior)
        // Note: We can't reliably test the exact timing, but we verify sparkles were triggered
        XCTAssertTrue(viewModel.showSparkles)
    }

    @MainActor
    func testNotificationIntegration() {
        // Test that notifications properly update the ViewModel
        let viewModel = EcosiaAccountAvatarViewModel()
        let expectation = XCTestExpectation(description: "Notification received")

        // Listen for progress changes
        let cancellable = viewModel.$progress.sink { progress in
            if progress == 0.8 {
                expectation.fulfill()
            }
        }

        // Send notification
        EcosiaAccountNotificationCenter.postProgressUpdated(progress: 0.8)

        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()
    }
}
