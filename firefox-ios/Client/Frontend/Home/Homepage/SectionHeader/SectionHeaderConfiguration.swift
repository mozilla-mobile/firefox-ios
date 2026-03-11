// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct SectionHeaderConfiguration: Equatable, Hashable {
    enum Style: Equatable, Hashable {
        case sectionTitle
        case newsAffordance
    }

    let title: String
    let a11yIdentifier: String
    var isButtonHidden = true
    var buttonA11yIdentifier: String?
    var buttonTitle: String?
    var style: Style = .sectionTitle
    /// When `true`, a frosted-glass material background is shown behind the header text/button
    /// so the content remains legible over a homepage wallpaper.
    var showsBlurBackground = false
}
