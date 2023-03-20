// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import SwiftUI

struct CreditCardEditView: View {
    @ObservedObject var viewModel: CreditCardEditViewModel
    let removeButtonColor: Color
    let borderColor: Color

    var body: some View {
        VStack(spacing: 11) {
            let colors = FloatingTextField.Colors(
                errorColor: .red,
                titleColor: .gray,
                textFieldColor: .gray)

            FloatingTextField(label: String.CreditCard.EditCard.NameOnCardTitle,
                              textVal: $viewModel.nameOnCard,
                              errorString: String.CreditCard.ErrorState.NameOnCardSublabel,
                              showError: !viewModel.nameIsValid,
                              colors: colors)
            Divider()
                .frame(height: 0.7)

            FloatingTextField(label: String.CreditCard.EditCard.CardNumberTitle,
                              textVal: $viewModel.cardNumber,
                              errorString: String.CreditCard.ErrorState.CardNumberSublabel,
                              showError: !viewModel.numberIsValid,
                              colors: colors)
            Divider()
                .frame(height: 0.7)

            FloatingTextField(label: String.CreditCard.EditCard.CardExpirationDateTitle,
                              textVal: $viewModel.expirationDate,
                              errorString: String.CreditCard.ErrorState.CardExpirationDateSublabel,
                              showError: !viewModel.expirationIsValid,
                              colors: colors)
            Divider()
                .frame(height: 0.7)

            Spacer()
                .frame(height: 4)

            RemoveCardButton(
                removeButtonColor: removeButtonColor,
                borderColor: borderColor,
                alertDetails: viewModel.removeButtonDetails
            )
            Spacer()
        }
        .padding(.top, 20)
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
                           removeButtonColor: .gray,
                           borderColor: .gray)
    }
}
