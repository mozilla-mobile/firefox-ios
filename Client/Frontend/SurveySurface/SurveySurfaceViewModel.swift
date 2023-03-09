// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class SurveySurfaceViewModel {
//    private var message: GleanPlumbMessage
//    private var messagingManager: GleanPlumbMessageManagerProtocol

//    weak var delegate: HomepageDataModelDelegate?
//    weak var homepanelDelegate: HomePanelDelegate?
//    var dismissClosure: (() -> Void)?

    var info: SurveySurfaceInfoProtocol

    init(with info: SurveySurfaceInfoProtocol) {
        self.info = info
    }

//    func getMessage(for surface: MessageSurfaceId) -> GleanPlumbMessage {
//        return message
//    }

//    var shouldDisplayMessageCard: Bool {
//        guard let message = message else { return false }
//
//        return !message.isExpired
//    }

//    func handleMessageDisplayed() {
//        message.map(messagingManager.onMessageDisplayed)
//    }
//
//    func handleMessagePressed() {
//        message.map(messagingManager.onMessagePressed)
//        dismissClosure?()
//    }
//
//    func handleMessageDismiss() {
//        message.map(messagingManager.onMessageDismissed)
//        dismissClosure?()
//    }
}
