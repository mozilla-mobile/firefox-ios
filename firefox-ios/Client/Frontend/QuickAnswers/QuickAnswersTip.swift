// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import TipKit

@available(iOS 17.0, *)
struct QuickAnswersTip: Tip {
    // TODO: FXIOS-14720 add Translations
    var title: Text {
        Text(verbatim: "Ask Out Loud for Quick Answers")
    }

    var message: Text? {
        Text(verbatim: "Tap here to get started.")
    }

    var options: [any TipOption] {
        MaxDisplayCount(1)
        IgnoresDisplayFrequency(true)
    }
}
