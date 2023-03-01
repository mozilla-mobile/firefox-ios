// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct SurveySurfaceData {
    let text: String
    let primaryButtonLabel: String
    let actionURL: URL
}

class SurveySurfaceViewModel {
    private let data: SurveySurfaceData
    private var messagingManager: GleanPlumbMessageManagerProtocol

//    weak var delegate: HomepageDataModelDelegate?
//    weak var homepanelDelegate: HomePanelDelegate?
    var dismissClosure: (() -> Void)?
    var theme: Theme

    init(
        with data: SurveySurfaceData,
        theme: Theme,
        and messagingManager: GleanPlumbMessageManagerProtocol
    ) {
        self.data = data
        self.theme = theme
        self.messagingManager = messagingManager
    }
}
