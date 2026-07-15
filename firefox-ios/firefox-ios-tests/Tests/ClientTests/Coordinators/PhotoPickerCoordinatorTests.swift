// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import PhotosUI

@testable import Client

@MainActor
final class PhotoPickerCoordinatorTests: XCTestCase {
    private var router: MockRouter!
    private var parentCoordinator: MockParentCoordinator!

    override func setUp() async throws {
        try await super.setUp()
        router = MockRouter(navigationController: MockNavigationController())
        parentCoordinator = MockParentCoordinator()
    }

    override func tearDown() async throws {
        router = nil
        parentCoordinator = nil
        try await super.tearDown()
    }

    func test_start_presentsPhotoPicker() {
        let photoPickerTelemetry = MockSystemPhotoPickerTelemetry()
        let subject = createSubject(photoPickerTelemetry: photoPickerTelemetry)

        subject.start()

        XCTAssertEqual(router.presentCalled, 1)
        XCTAssertTrue(router.presentedViewController is PHPickerViewController)
        XCTAssertEqual(photoPickerTelemetry.shownCalled, 1)
        XCTAssertEqual(photoPickerTelemetry.savedShownReason, .googleLens)
    }

    func test_didFinishPicking_callsCompletionAndNotifiesParent() {
        var completionCalled = 0
        let photoPickerTelemetry = MockSystemPhotoPickerTelemetry()
        let subject = createSubject(photoPickerTelemetry: photoPickerTelemetry,
                                    onComplete: { _ in completionCalled += 1 })
        let picker = PHPickerViewController(configuration: PHPickerConfiguration(photoLibrary: .shared()))

        subject.picker(picker, didFinishPicking: [])

        XCTAssertEqual(completionCalled, 1)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(router.dismissCalled, 1)
        XCTAssertEqual(photoPickerTelemetry.closedCalled, 1)
        XCTAssertEqual(photoPickerTelemetry.savedClosedReason, .googleLens)
    }

    func test_interactiveDismissal_callsCompletionAndNotifiesParent() {
        var completionResults: [PHPickerResult]?
        let photoPickerTelemetry = MockSystemPhotoPickerTelemetry()
        let subject = createSubject(photoPickerTelemetry: photoPickerTelemetry,
                                    onComplete: { completionResults = $0 })

        subject.start()
        router.savedCompletion?()

        XCTAssertEqual(completionResults?.count, 0)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(photoPickerTelemetry.closedCalled, 1)
        XCTAssertEqual(photoPickerTelemetry.savedClosedReason, .googleLens)
    }

    // MARK: - Helper Methods
    private func createSubject(photoPickerTelemetry: SystemPhotoPickerTelemetryProtocol = MockSystemPhotoPickerTelemetry(),
                               onComplete: @escaping ([PHPickerResult]) -> Void = { _ in },
                               file: StaticString = #filePath,
                               line: UInt = #line) -> PhotoPickerCoordinator {
        let subject = PhotoPickerCoordinator(parentCoordinatorDelegate: parentCoordinator,
                                             router: router,
                                             photoPickerReason: .googleLens,
                                             photoPickerTelemetry: photoPickerTelemetry,
                                             onComplete: onComplete)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
