// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum OnboardingInstructionsPopupActions: String, CaseIterable, Codable {
    case dismiss = "dismiss"
    case dismissAndNextCard = "dismiss-and-next-card"
    case openIosFxSettings = "open-ios-fx-settings"
}
