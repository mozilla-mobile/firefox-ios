// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// For the Credit Card feature, this enum holds four cases that describe different parts of a credit card.
enum CreditCardInputType {
    case name, number, expiration
}

struct CreditCardInputField: View {
    struct Colors {
        let errorColor: Color
        let titleColor: Color
        let textFieldColor: Color
    }

    @Binding var text: String
    @ObservedObject var viewModel: CreditCardInputViewModel
    let creditCardInputType: CreditCardInputType
    var colors: Colors

    init(creditCardInputType: CreditCardInputType,
         text: Binding<String>,
         colors: Colors) {
        self.creditCardInputType = creditCardInputType
        self.viewModel = CreditCardInputViewModel(fieldType: creditCardInputType)
        self._text = text
        self.colors = colors
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            getInputFieldViewWith(inputType: creditCardInputType)
        }
        .padding(.leading, 16)
    }

    @ViewBuilder private func getInputFieldViewWith(inputType: CreditCardInputType) -> some View {
        Text(viewModel.fieldHeadline)
            .font(.subheadline)
            .foregroundColor(colors.titleColor)
        TextField("", text: $text)
            .font(.body)
            .foregroundColor(colors.textFieldColor)
            .keyboardType(viewModel.keyboardType)
            .onChange(of: text) { [oldValue = text] newValue in
                switch inputType {
                case .name:
                    viewModel.updateNameValidity(userInputtedText: text)
                case .number:
                    viewModel.updateCardNumberValidity(userInputtedText: text)
                case .expiration:
                    var numbersCount = 0
                    text.forEach { character in
                        character.isNumber ? numbersCount += 1 : nil
                    }

                    guard !(text.count > viewModel.formattedTextLimit) || !(numbersCount > 5) else {
                        text = oldValue
                        return
                    }

                    guard text.count % 4 == 0 else {
                        text = text.removingOccurrences(of: " / ")
                        return
                    }

                    viewModel.updateExpirationValidity(userInputtedText: text)

                    guard let formattedText = viewModel.separate(inputType: inputType, for: text) else { return }
                    text = formattedText
                }
            }
        if !viewModel.isValid {
            errorViewWith(errorString: viewModel.errorString)
        }
    }

    @ViewBuilder private func errorViewWith(errorString: String) -> some View {
        HStack(spacing: 0) {
            Image(ImageIdentifiers.errorAutofill)
                .renderingMode(.template)
                .foregroundColor(colors.errorColor)
            Text(errorString)
                .errorTextStyle(color: colors.errorColor)
        }
        .padding(.top, 7.4)
    }
}
