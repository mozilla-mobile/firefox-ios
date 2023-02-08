// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI

struct CreditCardAutofillToggle: View {
    @State var isToggleOn: Bool = false

    var body: some View {
        VStack {
            Divider()
                .frame(height: 0.7)
                .padding(.leading, 16)
                .hidden()
            HStack {
                Toggle("Save and autofill cards", isOn: $isToggleOn)
                    .font(.system(.body))
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
            }
            Divider()
                .frame(height: 0.7)
                .padding(.leading, 16)
        }
    }
}

struct CreditCardAutofillToggle_Previews: PreviewProvider {
    static var previews: some View {
        CreditCardAutofillToggle(isToggleOn: true)

        CreditCardAutofillToggle(isToggleOn: true)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewDisplayName("Large")

        CreditCardAutofillToggle(isToggleOn: true)
            .environment(\.sizeCategory, .extraSmall)
            .previewDisplayName("Small")
    }
}
