// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import SwiftUI
import TipKit

@available(iOS 17.0, *)
struct GoogleLensTip: Tip {
    var title: Text {
        Text(verbatim: String.ContextualHints.Toolbar.GoogleLens.Title)
    }

    var message: Text? {
        Text(verbatim: String.ContextualHints.Toolbar.GoogleLens.Description)
    }

    var options: [any TipOption] {
        MaxDisplayCount(1)
        IgnoresDisplayFrequency(true)
    }
}
