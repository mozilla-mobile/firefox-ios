// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI

struct ErrorTextStyle: ViewModifier {
    var color: Color

    func body(content: Content) -> some View {
        content
            .preferredBodyFont(size: 15)
            .padding(.leading, 10)
            .foregroundColor(color)
    }
}

extension View {
    func errorTextStyle(color: Color) -> some View {
        modifier(ErrorTextStyle(color: color))
    }
}
