// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OnboardingCardDelegate: AnyObject {
    func handleButtonPress(for action: OnboardingActions, from cardNamed: String)
    func showPrivacyPolicy(from cardNamed: String)
    func showNextPage(from cardNamed: String)
    func pageChanged(from cardNamed: String)
}
