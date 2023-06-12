// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Storage
import Shared

enum SingleCreditCardViewState: String, Equatable, CaseIterable {
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

struct SingleCreditCardViewModel {
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

    var state: SingleCreditCardViewState

    init(profile: Profile,
         creditCard: CreditCard?,
         decryptedCreditCard: UnencryptedCreditCardFields?,
         logger: Logger = DefaultLogger.shared,
         state: SingleCreditCardViewState) {
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
        let decryptedCard = getPlainCreditCardValues()
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
    func getPlainCreditCardValues() -> UnencryptedCreditCardFields? {
        switch state {
        case .save:
            guard let plainCard = decryptedCreditCard else { return nil }
            return plainCard
        case .update:
            guard let creditCard = creditCard,
                  let ccNumberDecrypted = autofill.decryptCreditCardNumber(encryptedCCNum: creditCard.ccNumberEnc) else {
                return nil
            }

            let plainCard = UnencryptedCreditCardFields(
                ccName: creditCard.ccName,
                ccNumber: ccNumberDecrypted,
                ccNumberLast4: creditCard.ccNumberLast4,
                ccExpMonth: creditCard.ccExpMonth,
                ccExpYear: creditCard.ccExpYear,
                ccType: creditCard.ccType)

            return plainCard
        }
    }
}
