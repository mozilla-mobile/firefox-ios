// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class SurveySurfaceViewModel {
    // MARK: - Properties
    /// Held strongly on purpose. The `SurveySurfaceManager` acting as delegate is otherwise only
    /// retained by the transient `LaunchScreenViewModel`, which is deallocated once the browser
    /// becomes the root view controller — while the survey is still presented. A `weak` reference
    /// here left the delegate `nil` by the time the user tapped a button, so `didTapTakeSurvey`
    /// never reached the manager (no telemetry, no survey URL). The manager does not reference this
    /// view model back, so there is no retain cycle.
    var delegate: SurveySurfaceDelegate?
    var info: SurveySurfaceInfoProtocol

    // MARK: - Initialization
    init(with info: SurveySurfaceInfoProtocol,
         delegate: SurveySurfaceDelegate
    ) {
        self.info = info
        self.delegate = delegate
    }

    // MARK: - Functionality
    func didDisplayMessage() {
        delegate?.didDisplayMessage()
    }

    @MainActor
    func didTapTakeSurvey() {
        delegate?.didTapTakeSurvey()
    }

    func didTapDismissSurvey() {
        delegate?.didTapDismissSurvey()
    }
}
