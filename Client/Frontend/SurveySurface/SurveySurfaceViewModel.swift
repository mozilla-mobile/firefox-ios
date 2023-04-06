// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class SurveySurfaceViewModel {
    // MARK: - Properties
    weak var delegate: SurveySurfaceDelegate?
    var info: SurveySurfaceInfoProtocol
    private var nimbus: FxNimbus

    // MARK: - Initialization
    init(with info: SurveySurfaceInfoProtocol,
         delegate: SurveySurfaceDelegate,
         and nimbus: FxNimbus = FxNimbus.shared
    ) {
        self.info = info
        self.delegate = delegate
        self.nimbus = nimbus
    }

    // MARK: - Functionality
    func didDisplayMessage() {
        delegate?.didDisplayMessage()
        nimbus.features.messaging.recordExposure()
    }

    func didTapTakeSurvey() {
        delegate?.didTapTakeSurvey()
    }

    func didTapDismissSurvey() {
        delegate?.didTapDismissSurvey()
    }

    // MARK: - Orientation
    /// As per design, we will be locking the orientation for the survey
    /// surface to portait on iPhones.
    func setOrientationLockTo(on: Bool) {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }

        if on {
            // Portrait orientation: lock enable
            OrientationLockUtility.lockOrientation(UIInterfaceOrientationMask.portrait,
                                                   andRotateTo: UIInterfaceOrientation.portrait)
        } else {
            // Portrait orientation: lock disable
            OrientationLockUtility.lockOrientation(UIInterfaceOrientationMask.all)
        }
    }
}
