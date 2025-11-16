// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct SectionHeaderConfiguration: Equatable, Hashable {
    let title: String
    let a11yIdentifier: String
    var isButtonHidden = true
    var buttonA11yIdentifier: String?
    var buttonTitle: String?
}
