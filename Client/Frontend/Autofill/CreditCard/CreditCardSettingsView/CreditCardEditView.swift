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

            FloatingTextField(label: "Name on Card",
                              textVal: $viewModel.nameOnCard,
                              placeHolder: "",
                              errorString: "Add a name",
                              showError: !viewModel.nameIsValid,
                              colors: colors)
            Divider()
                .frame(height: 0.7)

            FloatingTextField(label: "Card Number",
                              textVal: $viewModel.cardNumber,
                              placeHolder: "",
                              errorString: "Enter a valid card number",
                              showError: !viewModel.numberIsValid,
                              colors: colors)
            Divider()
                .frame(height: 0.7)

            FloatingTextField(label: "Expiration MM / YY",
                              textVal: $viewModel.expirationDate,
                              placeHolder: "",
                              errorString: "Enter a valid expiration date",
                              showError: !viewModel.expirationIsValid,
                              colors: colors)
            Divider()
                .frame(height: 0.7)

            Spacer()

            RemoveCardButton(removeButtonColor: removeButtonColor,
                             borderColor: borderColor)
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
