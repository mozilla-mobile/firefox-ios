// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import Shared

enum CreditCardInputType {
    case name, number, expiration
}

struct CreditCardInputField: View {
    var fieldHeadline: String
    var errorString: String
    var delimiterCharacter: String?
    var userInputLimit: Int
    var formattedTextLimit: Int
    var keyboardType: UIKeyboardType

    @Binding var text: String
    let inputType: CreditCardInputType
    let editViewModel: CreditCardEditViewModel
    var showError: Bool = false

    // Theming
    @Environment(\.themeType) var themeVal
    @State var errorColor: Color = .clear
    @State var titleColor: Color = .clear
    @State var textFieldColor: Color = .clear
    @State var backgroundColor: Color = .clear

    init(inputType: CreditCardInputType,
         text: Binding<String>,
         showError: Bool,
         editViewModel: CreditCardEditViewModel
    ) {
        self.inputType = inputType
        self._text = text
        self.showError = showError
        self.editViewModel = editViewModel

        switch self.inputType {
        case .name:
            fieldHeadline = .CreditCard.EditCard.NameOnCardTitle
            errorString = .CreditCard.ErrorState.NameOnCardSublabel
            delimiterCharacter = nil
            userInputLimit = 100
            formattedTextLimit = 100
            keyboardType = .alphabet
        case .number:
            fieldHeadline = .CreditCard.EditCard.CardNumberTitle
            errorString = .CreditCard.ErrorState.CardNumberSublabel
            delimiterCharacter = "-"
            userInputLimit = 19
            formattedTextLimit = 23
            keyboardType = .numberPad
        case .expiration:
            fieldHeadline = .CreditCard.EditCard.CardExpirationDateTitle
            errorString = .CreditCard.ErrorState.CardExpirationDateSublabel
            delimiterCharacter = " / "
            userInputLimit = 4
            formattedTextLimit = 7
            keyboardType = .numberPad
        }
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                provideInputField()

                if showError {
                    errorViewWith(errorString: errorString)
                }
            }
            .background(backgroundColor.edgesIgnoringSafeArea(.bottom))
        }
        .padding(.leading, 20)
        .onAppear {
            applyTheme(theme: themeVal.theme)
        }
        .onChange(of: themeVal) { val in
            applyTheme(theme: val.theme)
        }
    }

    func applyTheme(theme: Theme) {
        let color = theme.colors
        errorColor = Color(color.textWarning)
        titleColor = Color(color.textPrimary)
        textFieldColor = Color(color.textSecondary)
        backgroundColor = Color(color.layer2)
    }

    @ViewBuilder private func provideInputField() -> some View {
        Text(fieldHeadline)
            .font(.subheadline)
            .foregroundColor(titleColor)
        TextField("", text: $text)
            .font(.body)
            .padding(.top, 7.5)
            .foregroundColor(textFieldColor)
            .keyboardType(keyboardType)
            .onChange(of: text) { [oldValue = text] newValue in
                switch inputType {
                case .name:
                    print()
                case .number:
                    print()
                case .expiration:
                    guard newValue.removingOccurrences(of: " / ") != oldValue else { return }

                    let numbersCount = countNumbersIn(text: text)

                    guard !(text.count > formattedTextLimit) || !(numbersCount > 4) else {
                        text = oldValue
                        return
                    }

                    guard numbersCount % 4 == 0 else {
                        text = text.removingOccurrences(of: " / ")
                        return
                    }

                    editViewModel.expirationDate = text.removingOccurrences(of: " / ")

                    guard let formattedText = separate(inputType: inputType,
                                                       for: text.removingOccurrences(of: " / ")) else { return }
                    text = formattedText
                }
            }
    }

    @ViewBuilder private func errorViewWith(errorString: String) -> some View {
        HStack(spacing: 0) {
            Image(ImageIdentifiers.errorAutofill)
                .renderingMode(.template)
                .foregroundColor(errorColor)
                .accessibilityHidden(true)
            Text(errorString)
                .errorTextStyle(color: errorColor)
        }
        .padding(.top, 7.4)
    }

    private func countNumbersIn(text: String) -> Int {
        var numbersCount = 0
        text.forEach { character in
            character.isNumber ? numbersCount += 1 : nil
        }

        return numbersCount
    }

    /// This function takes a credit card input string and returns it in a user readable format.
    /// - Parameters:
    ///   - inputType: The `CreditCardInputType`.
    ///   - textInput: The user inputted string.
    /// - Returns: The string in the expected and readable format for that `inputType`.
    func separate(inputType: CreditCardInputType, for textInput: String) -> String? {
        guard let delimiterCharacter = delimiterCharacter, textInput.count <= formattedTextLimit else { return nil }

        var formattedText = ""
        switch inputType {
        case .number:
            formattedText = textInput.enumerated().map {
                $0.isMultiple(of: 4) && ($0 != 0) ? "\(delimiterCharacter)\($1)" : String($1)
            }.joined()
        case .expiration:
            formattedText = textInput.enumerated().map {
                $0.isMultiple(of: 2) && ($0 != 0) ? "\(delimiterCharacter)\($1)" : String($1)
            }.joined()

        default: break
        }

        return formattedText
    }
}
