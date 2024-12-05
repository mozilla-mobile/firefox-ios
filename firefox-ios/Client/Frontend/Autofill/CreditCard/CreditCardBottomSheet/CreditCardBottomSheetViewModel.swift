// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Storage
import Shared

import enum MozillaAppServices.AutofillApiError
import struct MozillaAppServices.CreditCard

enum CreditCardBottomSheetState: String, Equatable, CaseIterable {
    case save
    case update
    case selectSavedCard

    var title: String {
        switch self {
        case .save:
            return .CreditCard.RememberCreditCard.MainTitle
        case .update:
            return .CreditCard.UpdateCreditCard.MainTitle
        case .selectSavedCard:
            return .CreditCard.SelectCreditCard.MainTitle
        }
    }

    var header: String? {
        switch self {
        case .save:
            return String(
                format: String.CreditCard.RememberCreditCard.Header,
                AppName.shortName.rawValue)
        case .selectSavedCard, .update:
            return nil
        }
    }

    var yesButtonTitle: String {
        switch self {
        case .save:
            return .CreditCard.RememberCreditCard.MainButtonTitle
        case .update:
            return .CreditCard.UpdateCreditCard.MainButtonTitle
        case .selectSavedCard:
            return ""
        }
    }

    var notNowButtonTitle: String {
        switch self {
        case .save:
            return .CreditCard.RememberCreditCard.SecondaryButtonTitle
        case .update:
            return .CreditCard.UpdateCreditCard.SecondaryButtonTitle
        case .selectSavedCard:
            return ""
        }
    }
}

class CreditCardBottomSheetViewModel {
    private var logger: Logger
    let autofill: CreditCardProvider
    var creditCard: CreditCard? {
        didSet {
            didUpdateCreditCard?()
        }
    }

    var creditCards: [CreditCard]? {
        didSet {
            didUpdateCreditCard?()
        }
    }

    var didUpdateCreditCard: (() -> Void)?
    var decryptedCreditCard: UnencryptedCreditCardFields?
    var storedCreditCards = [CreditCard]()
    var state: CreditCardBottomSheetState

    init(creditCardProvider: CreditCardProvider,
         creditCard: CreditCard?,
         decryptedCreditCard: UnencryptedCreditCardFields?,
         logger: Logger = DefaultLogger.shared,
         state: CreditCardBottomSheetState) {
        self.autofill = creditCardProvider
        self.state = state
        self.logger = logger
        creditCards = [CreditCard]()
        updateCreditCardList { _ in }
        if creditCard != nil {
            self.creditCard = creditCard
            self.decryptedCreditCard = decryptedCreditCard
        } else {
            self.decryptedCreditCard = decryptedCreditCard
            self.creditCard = decryptedCreditCard?.convertToTempCreditCard()
        }
    }

    // MARK: Main Button Action
    public func didTapMainButton(queue: DispatchQueueInterface = DispatchQueue.main,
                                 completion: @escaping (Error?) -> Void) {
        let decryptedCard = getPlainCreditCardValues(bottomSheetState: state)
        switch state {
        case .save:
            saveCreditCard(with: decryptedCard) { _, error in
                queue.async {
                    guard let error = error else {
                        completion(nil)
                        return
                    }
                    self.logger.log("Unable to save credit card with error: \(error)",
                                    level: .fatal,
                                    category: .autofill)
                    completion(error)
                }
            }
        case .update:
            updateCreditCard(for: creditCard?.guid,
                             with: decryptedCard) { _, error in
                queue.async {
                    guard let error = error else {
                        completion(nil)
                        return
                    }
                    self.logger.log("Unable to save credit card with error: \(error)",
                                    level: .fatal,
                                    category: .autofill)
                    completion(error)
                }
            }
        case .selectSavedCard:
            break
        }
    }

    // MARK: Save Credit Card
    public func saveCreditCard(with decryptedCard: UnencryptedCreditCardFields?,
                               completion: @escaping (CreditCard?, Error?) -> Void) {
        guard let decryptedCard = decryptedCard else {
            completion(
                nil,
                AutofillApiError.UnexpectedAutofillApiError(reason: "SaveCreditCard: nil decryptedCreditCard card")
            )
            return
        }
        autofill.addCreditCard(creditCard: decryptedCard,
                               completion: completion)
    }

    // MARK: Update Credit Card
    func updateCreditCard(for creditCardGUID: String?,
                          with decryptedCard: UnencryptedCreditCardFields?,
                          completion: @escaping (Bool?, Error?) -> Void) {
        guard let creditCardGUID = creditCardGUID else {
            completion(false, AutofillApiError.UnexpectedAutofillApiError(reason: "nil credit card GUID"))
            return
        }
        guard let decryptedCard = decryptedCard else {
            completion(
                false,
                AutofillApiError.UnexpectedAutofillApiError(reason: "UpdateCreditCard: nil decryptedCreditCard card")
            )
            return
        }
        autofill.updateCreditCard(id: creditCardGUID,
                                  creditCard: decryptedCard,
                                  completion: completion)
    }

    // MARK: Helper Methods
    func getPlainCreditCardValues(bottomSheetState: CreditCardBottomSheetState,
                                  row: Int? = nil) -> UnencryptedCreditCardFields? {
        switch bottomSheetState {
        case .save:
            guard let plainCard = decryptedCreditCard else { return nil }
            return plainCard
        case .update:
            guard let creditCard = creditCard,
                  let ccNumberDecrypted = autofill.decryptCreditCardNumber(encryptedCCNum: creditCard.ccNumberEnc)
            else {
                return nil
            }
            let updatedDecryptedCreditCard = updateDecryptedCreditCard(from: creditCard,
                                                                       with: ccNumberDecrypted,
                                                                       fieldValues: decryptedCreditCard)
            return updatedDecryptedCreditCard
        case .selectSavedCard:
            guard let row = row,
                  let selectedCreditCard = getSavedCreditCard(for: row)
            else {
                return nil
            }

            let decryptedCreditCardNum = decryptCreditCardNumber(card: selectedCreditCard)

            guard !decryptedCreditCardNum.isEmpty else {
                return nil
            }
            // We need to show only 2 digits but save full year for sync
            let period = Int64(Date.getCurrentPeriod())
            let selectedExpYear = selectedCreditCard.ccExpYear
            let yearVal = selectedExpYear < 1000 ? selectedExpYear + period : selectedExpYear
            let plainTextCard = UnencryptedCreditCardFields(ccName: selectedCreditCard.ccName,
                                                            ccNumber: decryptedCreditCardNum,
                                                            ccNumberLast4: selectedCreditCard.ccNumberLast4,
                                                            ccExpMonth: selectedCreditCard.ccExpMonth,
                                                            ccExpYear: yearVal,
                                                            ccType: selectedCreditCard.ccType)
            return plainTextCard
        }
    }

    func getConvertedCreditCardValues(bottomSheetState: CreditCardBottomSheetState,
                                      ccNumberDecrypted: String,
                                      row: Int? = nil) -> CreditCard? {
        switch bottomSheetState {
        case .save:
            guard let plainCard = decryptedCreditCard else { return nil }
            return plainCard.convertToTempCreditCard()
        case .update:
            guard let creditCard = creditCard, !ccNumberDecrypted.isEmpty,
                  let updatedDecryptedCreditCard = updateDecryptedCreditCard(
                    from: creditCard,
                    with: ccNumberDecrypted,
                    fieldValues: decryptedCreditCard)
            else {
                return nil
            }
            return updatedDecryptedCreditCard.convertToTempCreditCard()
        case .selectSavedCard:
            guard let row = row else { return nil }
            return getSavedCreditCard(for: row)
        }
    }

    private func getSavedCreditCard(for row: Int) -> CreditCard? {
        guard row > -1,
              let creditCards = creditCards,
              !creditCards.isEmpty,
              row < creditCards.count
        else {
            return nil
        }
        return creditCards[row]
    }

    func updateDecryptedCreditCard(
        from originalCreditCard: CreditCard,
        with ccNumberDecrypted: String,
        fieldValues decryptedCard: UnencryptedCreditCardFields?
    ) -> UnencryptedCreditCardFields? {
        guard var decryptedCreditCardVal = decryptedCard,
              !ccNumberDecrypted.isEmpty
        else {
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
        let isValidMonth = (1...12).contains(Int(month))
        decryptedCreditCardVal.ccExpMonth = isValidMonth ? month : originalCreditCard.ccExpMonth

        // Year
        var decryptedYearVal = decryptedCreditCardVal.ccExpYear
        var originalYearVal = originalCreditCard.ccExpYear
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let isValidYear = (currentYear...99).contains(Int(decryptedYearVal) % 100)
        // We need to show only 2 digits but save full year for sync
        let period = Int64(Date.getCurrentPeriod())
        decryptedYearVal = decryptedYearVal < 1000 ? decryptedYearVal + period : decryptedYearVal
        originalYearVal = originalYearVal < 1000 ? originalYearVal + period : originalYearVal
        decryptedCreditCardVal.ccExpYear = isValidYear ? decryptedYearVal : originalYearVal

        return decryptedCreditCardVal
    }

    func decryptCreditCardNumber(card: CreditCard?) -> String {
        guard let card = card else { return "" }
        let decryptedCardNum = autofill.decryptCreditCardNumber(encryptedCCNum: card.ccNumberEnc)
        return decryptedCardNum ?? ""
    }

    private func listStoredCreditCards(completionHandler: @escaping ([CreditCard]?) -> Void) {
        autofill.listCreditCards(completion: { creditCards, error in
            guard let creditCards = creditCards,
                  error == nil else {
                completionHandler(nil)
                return
            }
            completionHandler(creditCards)
        })
    }

    func updateCreditCardList(queue: DispatchQueueInterface = DispatchQueue.main,
                              completionHandler: @escaping ([CreditCard]?) -> Void) {
        if state == .selectSavedCard {
            listStoredCreditCards { [weak self] cards in
                queue.async {
                    self?.creditCards = cards
                    completionHandler(cards)
                }
            }
        }
    }

    // MARK: Accessibility
    func a11yLabel(for creditCard: CreditCard) -> NSAttributedString {
        let localizedDate = localizedDate(year: Int(creditCard.ccExpYear), month: Int(creditCard.ccExpMonth)) ?? ""
        let string = String(format: .CreditCard.Settings.ListItemA11y,
                            creditCard.ccType,
                            creditCard.ccName,
                            creditCard.ccNumberLast4,
                            localizedDate)
        let attributedString = NSMutableAttributedString(string: string)
        if let range = attributedString.string.range(of: creditCard.ccNumberLast4) {
            attributedString.addAttributes([.accessibilitySpeechSpellOut: true],
                                           range: NSRange(range, in: attributedString.string))
        }

        return attributedString
    }

    func localizedDate(year: Int, month: Int) -> String? {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1

        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: dateComponents) else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: date)
    }
}
