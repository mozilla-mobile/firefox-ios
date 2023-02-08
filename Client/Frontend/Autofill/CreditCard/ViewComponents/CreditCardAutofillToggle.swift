// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI

struct CreditCardAutofillToggle: View {
    var textColor: Color
    @State var isToggleOn: Bool = false // @ObservedObject

    var body: some View {
        VStack {
            Divider()
                .frame(height: 0.7)
                .padding(.leading, 16)
                .hidden()
            HStack {
                Toggle("Save and autofill cards", isOn: $isToggleOn)
                    .font(.system(.body))
                    .foregroundColor(textColor)
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
        CreditCardAutofillToggle(textColor: .gray,
                                 isToggleOn: true)

        CreditCardAutofillToggle(textColor: .gray,
                                 isToggleOn: true)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewDisplayName("Large")

        CreditCardAutofillToggle(textColor: .gray,
                                 isToggleOn: true)
            .environment(\.sizeCategory, .extraSmall)
            .previewDisplayName("Small")
    }
}
