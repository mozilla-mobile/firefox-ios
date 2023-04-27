// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class CreditCardInputFieldHelper {
    let inputType: CreditCardInputType

    init(inputType: CreditCardInputType) {
        self.inputType = inputType
    }

    func sanitizeInputOn(_ newValue: String) -> String {
        switch inputType {
        case .number, .expiration:
            let sanitized = newValue.filter { "0123456789".contains($0) }
            if sanitized != newValue {
                return sanitized
            }

        default: break
        }

        return newValue
    }

    func countNumbersIn(text: String) -> Int {
        var numbersCount = 0
        text.forEach { character in
            character.isNumber ? numbersCount += 1 : nil
        }

        return numbersCount
    }

    func separate(_ inputType: CreditCardInputType,
                  using delimiter: String?,
                  for textInput: String,
                  with formattedTextLimit: Int) -> String? {
        guard let delimiterCharacter = delimiter, textInput.count <= formattedTextLimit else { return nil }

        var formattedText = ""
        switch inputType {
        case .expiration:
            formattedText = textInput.enumerated().map {
                $0.isMultiple(of: 2) && ($0 != 0) ? "\(delimiterCharacter)\($1)" : String($1)
            }.joined()

        default: break
        }

        return formattedText
    }

    func addCreditCardDelimiter(sanitizedCCNum: String) -> String {
        let delimiter = "-"
        let delimiterAfterXChars: Int = 4
        let formattedText = updateStringWithInserting(
            valToUpdate: sanitizedCCNum,
            separator: delimiter,
            every: delimiterAfterXChars)
        return formattedText
    }

    private func updateStringWithInserting(valToUpdate: String,
                                           separator: String,
                                           every n: Int) -> String {
        var result: String = ""
        let characters = Array(valToUpdate)
        stride(from: 0, to: characters.count, by: n).forEach {
            result += String(characters[$0..<min($0+n, characters.count)])
            if $0+n < characters.count {
                result += separator
            }
        }
        return result
    }
}
