// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

final class MockMicrosurveySurfaceManager: MicrosurveyManager {
    var model: MicrosurveyModel?
    var handleMessageDisplayedCount = 0
    var handleMessagePressedCount = 0
    var handleMessageDismissCount = 0

    init(with model: MicrosurveyModel? = nil) {
        self.model = model
    }

    func showMicrosurveyPrompt() -> Client.MicrosurveyModel? {
        return model
    }

    func handleMessageDisplayed() {
        handleMessageDisplayedCount += 1
    }

    func handleMessagePressed() {
        handleMessagePressedCount += 1
    }

    func handleMessageDismiss() {
        handleMessageDismissCount += 1
    }
}
