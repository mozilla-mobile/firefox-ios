// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import UIKit

class SurveySurfaceViewModel {
    // MARK: - Properties
    weak var delegate: SurveySurfaceDelegate?
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
