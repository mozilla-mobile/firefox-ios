// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import UIKit
@testable import Client

@MainActor
final class SurveySurfaceViewModelTests: XCTestCase {
    /// Regression test: the delegate must be retained strongly. In production the delegate
    /// (`SurveySurfaceManager`) is only otherwise owned by the transient `LaunchScreenViewModel`,
    /// which is deallocated while the survey is still on screen. A `weak` delegate left it `nil`
    /// by the time the user tapped, so the button actions never reached the manager.
    func testDelegate_isRetainedStrongly_afterExternalReferenceReleased() {
        var delegate: MockSurveySurfaceDelegate? = MockSurveySurfaceDelegate()
        let surveySurfaceInfoModel = SurveySurfaceInfoModel(
            text: "text",
            takeSurveyButtonLabel: "take",
            dismissActionLabel: "dismiss",
            image: UIImage()
        )
        let subject = SurveySurfaceViewModel(with: surveySurfaceInfoModel, delegate: delegate!)
        trackForMemoryLeaks(subject)

        // Drop the only external strong reference, mirroring LaunchScreenViewModel being torn down.
        delegate = nil

        subject.didTapTakeSurvey()
        subject.didTapDismissSurvey()
        subject.didDisplayMessage()

        let retainedDelegate = subject.delegate as? MockSurveySurfaceDelegate
        XCTAssertNotNil(retainedDelegate, "View model should keep the delegate alive.")
        XCTAssertEqual(retainedDelegate?.didTapTakeSurveyCalled, 1)
        XCTAssertEqual(retainedDelegate?.didTapDismissSurveyCalled, 1)
        XCTAssertEqual(retainedDelegate?.didDisplayMessageCalled, 1)

        // Guard against the strong reference becoming a retain cycle: once `subject` and this local
        // are released at the end of the test, the delegate must deallocate.
        trackForMemoryLeaks(retainedDelegate)
    }
}

// MARK: - MockSurveySurfaceDelegate
private final class MockSurveySurfaceDelegate: SurveySurfaceDelegate {
    var didDisplayMessageCalled = 0
    var didTapTakeSurveyCalled = 0
    var didTapDismissSurveyCalled = 0

    func didDisplayMessage() { didDisplayMessageCalled += 1 }
    func didTapTakeSurvey() { didTapTakeSurveyCalled += 1 }
    func didTapDismissSurvey() { didTapDismissSurveyCalled += 1 }
}
