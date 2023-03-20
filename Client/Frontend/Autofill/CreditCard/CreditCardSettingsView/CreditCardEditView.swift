// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import SwiftUI

private struct CreditCardInputText {
    var name = ""
    var number = ""
    var expiration = ""
    var securityCode = ""
}

struct CreditCardEditView: View {
    @State private var text = CreditCardInputText()
    @ObservedObject var viewModel: CreditCardEditViewModel

    let removeButtonColor: Color
    let borderColor: Color
    let colors = CreditCardInputField.Colors(errorColor: .red,
                                             titleColor: .gray,
                                             textFieldColor: .gray)

    var body: some View {
        VStack(spacing: 11) {
            CreditCardInputField(creditCardInputType: .name,
                                 text: $text.name,
                                 colors: colors)
            Divider().frame(height: 0.7)
            CreditCardInputField(creditCardInputType: .number,
                                 text: $text.number,
                                 colors: colors)
            Divider().frame(height: 0.7)
            CreditCardInputField(creditCardInputType: .expiration,
                                 text: $text.expiration,
                                 colors: colors)
            Divider().frame(height: 0.7)

            Spacer().frame(height: 4)

            RemoveCardButton(
                removeButtonColor: removeButtonColor,
                borderColor: borderColor,
                alertDetails: viewModel.removeButtonDetails
            )
        }
        .padding(.top, 20)
        Spacer()
    }
}

struct CreditCardEditView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCreditCard = CreditCard(guid: "12345678",
                                          ccName: "Tim Apple",
                                          ccNumberEnc: "12345678",
                                          ccNumberLast4: "4321",
                                          ccExpMonth: 1234,
                                          ccExpYear: 2026,
                                          ccType: "Discover",
                                          timeCreated: 1234,
                                          timeLastUsed: nil,
                                          timeLastModified: 1234,
                                          timesUsed: 1234)

        let viewModel = CreditCardEditViewModel(firstName: "Mike",
                                                lastName: "Simmons",
                                                errorState: "Temp",
                                                enteredValue: "",
                                                creditCard: sampleCreditCard)

        CreditCardEditView(viewModel: viewModel,
                           removeButtonColor: .blue,
                           borderColor: .purple)
    }
}
