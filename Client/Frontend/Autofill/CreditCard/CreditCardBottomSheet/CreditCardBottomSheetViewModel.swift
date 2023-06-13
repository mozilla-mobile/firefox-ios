// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Storage
import Shared

enum CreditCardBottomSheetState: String, Equatable, CaseIterable {
    case save
    case update

    var title: String {
        switch self {
        case .save:
            return .CreditCard.RememberCreditCard.MainTitle
        case .update:
            return .CreditCard.UpdateCreditCard.MainTitle
        }
    }

    var header: String? {
        switch self {
        case .save:
            return String(
                format: String.CreditCard.RememberCreditCard.Header,
                AppName.shortName.rawValue)
        case .update:
            return nil
        }
    }

    var yesButtonTitle: String {
        switch self {
        case .save:
            return .CreditCard.RememberCreditCard.MainButtonTitle
        case .update:
            return .CreditCard.UpdateCreditCard.MainButtonTitle
        }
    }

    var notNowButtonTitle: String {
        switch self {
        case .save:
            return .CreditCard.RememberCreditCard.SecondaryButtonTitle
        case .update:
            return .CreditCard.UpdateCreditCard.SecondaryButtonTitle
        }
    }
}

struct CreditCardBottomSheetViewModel {
    private var logger: Logger
    let profile: Profile
    let autofill: RustAutofill
    var creditCard: CreditCard? {
        didSet {
            didUpdateCreditCard?()
        }
    }

    var didUpdateCreditCard: (() -> Void)?
    var decryptedCreditCard: UnencryptedCreditCardFields?

    var state: CreditCardBottomSheetState

    init(profile: Profile,
         creditCard: CreditCard?,
         decryptedCreditCard: UnencryptedCreditCardFields?,
         logger: Logger = DefaultLogger.shared,
         state: CreditCardBottomSheetState) {
        self.profile = profile
        self.autofill = profile.autofill
        if creditCard != nil {
            self.creditCard = creditCard
            self.decryptedCreditCard = decryptedCreditCard
        } else {
            self.decryptedCreditCard = decryptedCreditCard
            self.creditCard = decryptedCreditCard?.convertToTempCreditCard()
        }
        self.state = state
        self.logger = logger
    }

    // MARK: Main Button Action
    public func didTapMainButton(completion: @escaping (Error?) -> Void) {
        let decryptedCard = getPlainCreditCardValues(bottomSheetState: state)
        switch state {
        case .save:
            saveCreditCard(with: decryptedCard) { _, error in
                DispatchQueue.main.async {
                    guard let error = error else {
                        completion(nil)
                        return
                    }
                    logger.log("Unable to save credit card with error: \(error)",
                               level: .fatal,
                               category: .creditcard)
                    completion(error)
                }
            }
        case .update:
            updateCreditCard(for: creditCard?.guid,
                             with: decryptedCard) { _, error in
                DispatchQueue.main.async {
                    guard let error = error else {
                        completion(nil)
                        return
                    }
                    logger.log("Unable to save credit card with error: \(error)",
                               level: .fatal,
                               category: .creditcard)
                    completion(error)
                }
            }
        }
    }

    // MARK: Save Credit Card
    public func saveCreditCard(with decryptedCard: UnencryptedCreditCardFields?,
                               completion: @escaping (CreditCard?, Error?) -> Void) {
        guard let decryptedCard = decryptedCard else {
            completion(nil, AutofillApiError.UnexpectedAutofillApiError(reason: "SaveCreditCard: nil decryptedCreditCard card"))
            return
        }
        autofill.addCreditCard(creditCard: decryptedCard,
                               completion: completion)
    }

    // MARK: Update Credit Card
    func updateCreditCard(for creditCardGUID: String?,
                          with decryptedCard: UnencryptedCreditCardFields?,
                          completion: @escaping (Bool, Error?) -> Void) {
        guard let creditCardGUID = creditCardGUID else {
            completion(false, AutofillApiError.UnexpectedAutofillApiError(reason: "nil credit card GUID"))
            return
        }
        guard let decryptedCard = decryptedCard else {
            completion(false, AutofillApiError.UnexpectedAutofillApiError(reason: "UpdateCreditCard: nil decryptedCreditCard card"))
            return
        }
        autofill.updateCreditCard(id: creditCardGUID,
                                  creditCard: decryptedCard,
                                  completion: completion)
    }

    // MARK: Helper Methods
    func getPlainCreditCardValues(bottomSheetState: CreditCardBottomSheetState) -> UnencryptedCreditCardFields? {
        switch bottomSheetState {
        case .save:
            guard let plainCard = decryptedCreditCard else { return nil }
            return plainCard
        case .update:
            return updateDecryptedCreditCard(from: creditCard, fieldValues: decryptedCreditCard)
        }
    }
    
    func getConvertedCreditCardValues(bottomSheetState: CreditCardBottomSheetState) -> CreditCard? {
        switch bottomSheetState {
        case .save:
            guard let plainCard = decryptedCreditCard else { return nil }
            return plainCard.convertToTempCreditCard()
        case .update:
            let updatedCreditCard = updateDecryptedCreditCard(from: creditCard, fieldValues: decryptedCreditCard)
            return updatedCreditCard?.convertToTempCreditCard()
        }
    }

    func updateDecryptedCreditCard(from originalCreditCard: CreditCard?,
                                   fieldValues decryptedCard: UnencryptedCreditCardFields?) -> UnencryptedCreditCardFields? {
        guard let originalCreditCard = originalCreditCard,
              let ccNumberDecrypted = autofill.decryptCreditCardNumber(encryptedCCNum: originalCreditCard.ccNumberEnc),
              var decryptedCreditCardVal = decryptedCard else {
            return nil
        }

        // Note: For updation we keep the same credit card number, type and last 4 digits
        decryptedCreditCardVal.ccNumber = ccNumberDecrypted
        decryptedCreditCardVal.ccType = originalCreditCard.ccType
        decryptedCreditCardVal.ccNumberLast4 = originalCreditCard.ccNumberLast4

        // Update name, expiry month and expiry year if they are valid
        // Name
        let name = decryptedCreditCardVal.ccName
        decryptedCreditCardVal.ccName = !name.isEmpty ? name : originalCreditCard.ccName

        // Month
        let month = decryptedCreditCardVal.ccExpMonth
        let currentMonth = Calendar.current.component(.month, from: Date())
        let isValidMonth = (currentMonth...12).contains(Int(month))
        decryptedCreditCardVal.ccExpMonth = isValidMonth ? month : Int64(currentMonth)

        // Year
        let yearVal = decryptedCreditCardVal.ccExpYear
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let isValidYear = (currentYear...99).contains(Int(yearVal) % 100)
        decryptedCreditCardVal.ccExpYear = isValidYear ? yearVal : originalCreditCard.ccExpYear

        return decryptedCreditCardVal
    }
}
