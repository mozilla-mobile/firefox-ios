// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI

class CreditCardEditViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var errorState: String = ""
    @Published var enteredValue: String = ""
    @Published var nameIsValid = true
    @Published var numberIsValid = true
    @Published var expirationIsValid = true
    @Published var nameOnCard : String = "" {
        didSet (val) {
            nameIsValid = nameOnCard.isEmpty
            print("\(val)")
        }
    }

    @Published var expirationDate : String = "" {
        didSet (val) {
            numberIsValid = true
            print("\(val)")
        }
    }

    @Published var cardNumber : String = "" {
        didSet (val) {
            expirationIsValid = true// !nameOnCard.isEmpty
            print("\(val)")
        }
    }

    init() {}

    init(firstName: String,
         lastName: String,
         errorState: String,
         enteredValue: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.errorState = errorState
        self.enteredValue = enteredValue
    }

}

struct CreditCardEditView: View {
    @ObservedObject var viewModel: CreditCardEditViewModel

        var body: some View {
            VStack(spacing: 11){
                FloatingTextField(label: "Name on Card",
                                  textVal: $viewModel.nameOnCard,
                                  placeHolder: "",
                                  errorString: "Add a name",
                                  showError: !viewModel.nameIsValid)
                Divider()
                    .frame(height: 0.7)

                FloatingTextField(label: "Card Number",
                                  textVal: $viewModel.cardNumber,
                                  placeHolder: "",
                                  errorString: "Enter a valid card number",
                                  showError: !viewModel.numberIsValid)
                Divider()
                    .frame(height: 0.7)

                FloatingTextField(label: "Expiration MM / YY",
                                  textVal: $viewModel.expirationDate,
                                  placeHolder: "",
                                  errorString: "Enter a valid expiration date",
                                  showError: !viewModel.expirationIsValid)
                Divider()
                    .frame(height: 0.7)

                Spacer()
                
                RemoveCardButton()
            }
            .padding(.top, 20)
        }
}

struct CreditCardEditView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = CreditCardEditViewModel(firstName: "Mike", lastName: "Simmons", errorState: "Temp", enteredValue: "")
        CreditCardEditView(viewModel: vm)
    }
}
