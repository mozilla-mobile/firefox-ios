// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct EmbeddedLink {
    let fullText: String
    let linkText: String
    let action: TosAction

    public init(fullText: String, linkText: String, action: TosAction) {
        self.fullText = fullText
        self.linkText = linkText
        self.action = action
    }
}
