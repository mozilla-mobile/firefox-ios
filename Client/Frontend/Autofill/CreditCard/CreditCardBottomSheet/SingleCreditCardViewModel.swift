// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Storage

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
            return .CreditCard.RememberCreditCard.Header
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
    var creditCard: CreditCard

    var state: SingleCreditCardViewState

    init(profile: Profile,
         creditCard: CreditCard,
         logger: Logger = DefaultLogger.shared,
         state: SingleCreditCardViewState) {
        self.profile = profile
        self.autofill = profile.autofill
        self.creditCard = creditCard
        self.state = state
        self.logger = logger
    }

    public func didTapMainButton(completion: @escaping (Error?) -> Void) {
        switch state {
        case .save:
            saveCreditCard { _, error in
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
            updateCreditCard { _, error in
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

    public func saveCreditCard(completion: @escaping (CreditCard?, Error?) -> Void) {
        let plainCreditCard = getCCValues()
        autofill.addCreditCard(creditCard: plainCreditCard,
                               completion: completion)
    }

    func updateCreditCard(completion: @escaping (Bool, Error?) -> Void) {
        let plainCreditCard = getCCValues()
        autofill.updateCreditCard(id: creditCard.guid,
                                  creditCard: plainCreditCard,
                                  completion: completion)
    }

    func getCCValues() -> UnencryptedCreditCardFields {
        let plainCreditCard = UnencryptedCreditCardFields(
            ccName: creditCard.ccName,
            ccNumber: creditCard.ccNumberEnc,
            ccNumberLast4: creditCard.ccNumberLast4,
            ccExpMonth: creditCard.ccExpMonth,
            ccExpYear: creditCard.ccExpYear,
            ccType: creditCard.ccType)

        return plainCreditCard
    }
}
