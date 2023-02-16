// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
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
                              errorString: String.CreditCard.ErrorState.CardNumberTitle,
                              showError: !viewModel.numberIsValid,
                              colors: colors)
            Divider()
                .frame(height: 0.7)

            FloatingTextField(label: String.CreditCard.EditCard.CardExpirationDateTitle,
                              textVal: $viewModel.expirationDate,
                              errorString: String.CreditCard.ErrorState.CardExpirationDateTitle,
                              showError: !viewModel.expirationIsValid,
                              colors: colors)
            Divider()
                .frame(height: 0.7)

            Spacer()

            RemoveCardButton(
                removeButtonColor: removeButtonColor,
                borderColor: borderColor,
                alertDetails: viewModel.removeButtonDetails
            )
        }
        .padding(.top, 20)
    }
}

struct CreditCardEditView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CreditCardEditViewModel(firstName: "Mike", lastName: "Simmons", errorState: "Temp", enteredValue: "")
        CreditCardEditView(viewModel: viewModel,
                           removeButtonColor: .gray,
                           borderColor: .gray)
    }
}
