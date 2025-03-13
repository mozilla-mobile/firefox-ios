// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct TextStyle {
    static func title(_ text: Text) -> some View {
        text
            .font(.title28Bold)
            .multilineTextAlignment(.center)
    }
    
    static func subtitle(_ text: Text) -> some View {
        text
            .font(.title20)
            .multilineTextAlignment(.center)
    }
}
