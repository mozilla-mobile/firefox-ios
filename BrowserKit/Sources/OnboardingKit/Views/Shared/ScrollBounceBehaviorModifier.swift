// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct ScrollBounceBehaviorModifier: ViewModifier {
    let basedOnSize: Bool

    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.scrollBounceBehavior(basedOnSize ? .basedOnSize : .always)
        } else {
            content
        }
    }
}

extension View {
    func scrollBounceBehavior(basedOnSize: Bool) -> some View {
        modifier(ScrollBounceBehaviorModifier(basedOnSize: basedOnSize))
    }
}
