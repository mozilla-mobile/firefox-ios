// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import SwiftUI
import TipKit
import UIKit

/// The tip presented when the user taps the "About your privacy" link of the Quick Answers content view.
@available(iOS 17.0, *)
struct QuickAnswersPrivacyTip: Tip {
    /// TipKit invalidates a tip for good once its close button is tapped, and a tip that is already
    /// invalidated can no longer be shown. Since the link can be tapped any number of times, every
    /// presentation gets its own identity so it is always eligible.
    let id = "QuickAnswersPrivacyTip-\(UUID().uuidString)"

    private let strings: QuickAnswersViewConfiguration.PrivacyBannerStrings
    private let icon: Image?

    init(strings: QuickAnswersViewConfiguration.PrivacyBannerStrings, iconColor: UIColor) {
        self.strings = strings
        self.icon = UIImage(named: StandardImageIdentifiers.Large.audioWave)
            .map { Image(uiImage: $0.tinted(withColor: iconColor)) }
    }

    var title: Text {
        Text(verbatim: strings.title)
    }

    var message: Text? {
        Text(verbatim: strings.description)
    }

    var image: Image? {
        icon
    }

    /// The tip is only ever presented on demand, so it must never be withheld by the display frequency rules.
    var options: [any TipOption] {
        IgnoresDisplayFrequency(true)
    }
}
