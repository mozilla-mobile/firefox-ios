// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OnboardingTelemetryProtocol: AnyObject {
    func sendCardViewTelemetry(from cardName: String)
    func sendButtonActionTelemetry(from cardName: String,
                                   with action: OnboardingActions,
                                   and primaryButton: Bool)
    func sendDismissOnboardingTelemetry(from cardName: String)
}
