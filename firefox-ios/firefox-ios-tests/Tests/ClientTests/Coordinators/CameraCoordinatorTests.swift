// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import AVFoundation
import Common
import UIKit

@testable import Client

@MainActor
final class CameraCoordinatorTests: XCTestCase {
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

    func test_start_whenCameraUnavailable_finishesWithNilAndNotifiesParent() {
        var completionCalled = 0
        var completionImage: UIImage?
        let subject = createSubject(isCameraAvailable: false) { image in
            completionCalled += 1
            completionImage = image
        }

        subject.start()

        XCTAssertEqual(router.presentCalled, 0)
        XCTAssertEqual(completionCalled, 1)
        XCTAssertNil(completionImage)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    func test_didFinishPicking_withImage_callsCompletionAndNotifiesParent() {
        let expectedImage = UIImage()
        var completionImage: UIImage?
        let subject = createSubject(onComplete: { completionImage = $0 })
        let picker = UIImagePickerController()

        subject.imagePickerController(picker, didFinishPickingMediaWithInfo: [.originalImage: expectedImage])

        XCTAssertIdentical(completionImage, expectedImage)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(router.dismissCalled, 1)
    }

    func test_didFinishPicking_withoutImage_callsCompletionWithNil() {
        var completionCalled = 0
        var completionImage: UIImage?
        let subject = createSubject(onComplete: { image in
            completionCalled += 1
            completionImage = image
        })
        let picker = UIImagePickerController()

        subject.imagePickerController(picker, didFinishPickingMediaWithInfo: [:])

        XCTAssertEqual(completionCalled, 1)
        XCTAssertNil(completionImage)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(router.dismissCalled, 1)
    }

    func test_dismissCameraInterface_dismissesAndFinishesWithNil() {
        var completionCalled = 0
        var completionImage: UIImage?
        let subject = createSubject(onComplete: { image in
            completionCalled += 1
            completionImage = image
        })

        subject.dismissCameraInterface()

        XCTAssertEqual(router.dismissCalled, 1)
        XCTAssertEqual(completionCalled, 1)
        XCTAssertNil(completionImage)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    func test_dismissCameraInterfaceIfAccessRefused_whenRefused_dismissesAndFinishesWithNil() async {
        var completionCalled = 0
        var completionImage: UIImage?
        let subject = createSubject(requestCameraAccess: { false },
                                    onComplete: { image in
            completionCalled += 1
            completionImage = image
        })

        await subject.dismissCameraInterfaceIfAccessRefused()

        XCTAssertEqual(router.dismissCalled, 1)
        XCTAssertEqual(completionCalled, 1)
        XCTAssertNil(completionImage)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    func test_dismissCameraInterfaceIfAccessRefused_whenGranted_keepsInterfacePresented() async {
        var completionCalled = 0
        let subject = createSubject(requestCameraAccess: { true },
                                    onComplete: { _ in completionCalled += 1 })

        await subject.dismissCameraInterfaceIfAccessRefused()

        XCTAssertEqual(router.dismissCalled, 0)
        XCTAssertEqual(completionCalled, 0)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 0)
    }

    func test_didCancel_callsCompletionWithNilAndNotifiesParent() {
        var completionCalled = 0
        var completionImage: UIImage?
        let subject = createSubject(onComplete: { image in
            completionCalled += 1
            completionImage = image
        })
        let picker = UIImagePickerController()

        subject.imagePickerControllerDidCancel(picker)

        XCTAssertEqual(completionCalled, 1)
        XCTAssertNil(completionImage)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(router.dismissCalled, 1)
    }

    // MARK: - Helper Methods
    private func createSubject(isCameraAvailable: Bool = true,
                               cameraAuthorizationStatus: AVAuthorizationStatus = .authorized,
                               requestCameraAccess: @escaping () async -> Bool = { false },
                               onComplete: @escaping (UIImage?) -> Void = { _ in },
                               file: StaticString = #filePath,
                               line: UInt = #line) -> CameraCoordinator {
        let subject = CameraCoordinator(parentCoordinatorDelegate: parentCoordinator,
                                        router: router,
                                        isCameraAvailable: isCameraAvailable,
                                        cameraAuthorizationStatus: cameraAuthorizationStatus,
                                        requestCameraAccess: requestCameraAccess,
                                        onComplete: onComplete)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
