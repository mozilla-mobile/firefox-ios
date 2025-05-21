// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct OnboardingButtonInfoModel<OnboardingActionType> {
    let title: String
    let action: OnboardingActionType

    public init(title: String, action: OnboardingActionType) {
        self.title = title
        self.action = action
    }
}
