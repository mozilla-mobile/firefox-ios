// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class CreditCardInputViewModel: ObservableObject {
    let fieldType: CreditCardInputType
    let fieldHeadline: String
    let errorString: String
    var formattedTextLimit: Int
    var delimiterCharacter: String?
    var keyboardType: UIKeyboardType

    @Published var isValid = true

    init(fieldType: CreditCardInputType) {
        self.fieldType = fieldType

        switch fieldType {
        case .name:
            self.fieldHeadline = .CreditCard.EditCard.NameOnCardTitle
            self.errorString = .CreditCard.ErrorState.NameOnCardSublabel
            self.delimiterCharacter = nil
            self.formattedTextLimit = 100 // TBA
            self.keyboardType = .alphabet
        case .number:
            self.fieldHeadline = .CreditCard.EditCard.CardNumberTitle
            self.errorString = .CreditCard.ErrorState.CardNumberSublabel
            self.formattedTextLimit = 20
            self.delimiterCharacter = "-"
            self.keyboardType = .numberPad
        case .expiration:
            self.fieldHeadline = .CreditCard.EditCard.CardExpirationDateTitle
            self.errorString = .CreditCard.ErrorState.CardExpirationDateSublabel
            self.formattedTextLimit = 7
            self.delimiterCharacter = " / "
            self.keyboardType = .numberPad
        }
    }

    func updateNameValidity(userInputtedText: String) {
        isValid = !userInputtedText.isEmpty
    }

    func updateCardNumberValidity(userInputtedText: String) {
        isValid = userInputtedText.count >= 15 && userInputtedText.count <= 16
    }

    func updateExpirationValidity(userInputtedText: String) {
        let year = Calendar(identifier: .gregorian).dateComponents([.year], from: Date()).year

        guard let month = Int(userInputtedText.prefix(2)),
              let inputYear = Int(userInputtedText.suffix(2)),
              let year = year,
              userInputtedText.count < 5,
              month < 13 && month > 0,
              (inputYear + 2000) < 2099 && (inputYear + 2000) >= year else {
            isValid = false
            return
        }

        isValid = true
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
