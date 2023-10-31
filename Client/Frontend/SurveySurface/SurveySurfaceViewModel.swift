// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

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
}
