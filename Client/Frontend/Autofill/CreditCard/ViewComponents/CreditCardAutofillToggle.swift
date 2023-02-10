// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI

struct CreditCardAutofillToggle: View {
    @State private var toggleState = false

    var body: some View {
        VStack {
            Divider()
                .frame(height: 0.7)
                .padding(.leading, 16)
                .hidden()
            HStack {
                Toggle(isOn: $toggleState) {
                    Text("Save and autofill cards")
                }.font(.system(size: 17))
                 .padding(.leading, 16)
                 .padding(.trailing, 16)
            }
            Divider()
                .frame(height: 0.7)
                .padding(.leading, 16)
        }
        .frame(width: UIScreen.main.bounds.size.width, height: 42)
    }
}
