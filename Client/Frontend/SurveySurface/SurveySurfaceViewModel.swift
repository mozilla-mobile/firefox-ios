// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class SurveySurfaceViewModel {
    //    private var message: GleanPlumbMessage
    //    private var messagingManager: GleanPlumbMessageManagerProtocol

    weak var delegate: SurveySurfaceDelegate?
    //    weak var homepanelDelegate: HomePanelDelegate?
    //    var dismissClosure: (() -> Void)?

    var info: SurveySurfaceInfoProtocol

    init(with info: SurveySurfaceInfoProtocol,
         andDelegate delegate: SurveySurfaceDelegate
    ) {
        self.info = info
        self.delegate = delegate
    }

    func didDisplayMessage() {
//        delegate?.didDisplayMessage()
    }

    func didTapTakeSurvey() {
//        delegate?.didTapTakeSurvey()
    }

    func didTapDismissSurvey() {
//        delegate?.didTapDismissSurvey()
    }
}
