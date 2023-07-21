// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import Common
import Storage

enum CreditCardLeftBarButton: String, Equatable, CaseIterable {
    case close
    case cancel

    var title: String {
        switch self {
        case .cancel:
            return .CreditCard.EditCard.CancelNavBarButtonLabel
        case .close:
            return .CreditCard.EditCard.CloseNavBarButtonLabel
        }
    }
}

enum CreditCardRightBarButton: String, Equatable, CaseIterable {
    case save
    case edit

    var title: String {
        switch self {
        case .save:
            return .CreditCard.EditCard.SaveNavBarButtonLabel
        case .edit:
            return .CreditCard.EditCard.EditNavBarButtonLabel
        }
    }
}

enum CreditCardEditState: String, Equatable, CaseIterable {
    case add
    case edit
    case view

    var title: String {
        switch self {
        case .add:
            return .CreditCard.EditCard.AddCreditCardTitle
        case .view:
            return .CreditCard.EditCard.ViewCreditCardTitle
        case .edit:
            return .CreditCard.EditCard.EditCreditCardTitle
        }
    }

    var leftBarBtn: CreditCardLeftBarButton {
        switch self {
        case .add, .view:
            return .close
        case .edit:
            return .cancel
        }
    }

    var rightBarBtn: CreditCardRightBarButton {
        switch self {
        case .add, .edit:
            return .save
        case .view:
            return .edit
        }
    }
}

enum InputVMError: Error {
    case unableToSaveCC
    case unableToUpdateCC
}

enum CreditCardModifiedStatus {
    case savedCard
    case updatedCard
    case removedCard
    case none

    var message: String {
        switch self {
        case .savedCard: return String.CreditCard.SnackBar.SavedCardLabel
        case .updatedCard: return String.CreditCard.SnackBar.UpdatedCardLabel
        case .removedCard: return String.CreditCard.SnackBar.RemovedCardLabel
        default: return ""
        }
    }
}

class CreditCardInputViewModel: ObservableObject {
    typealias CreditCardText = String.CreditCard.Alert
    var logger: Logger?
    let profile: Profile
    let autofill: RustAutofill
    var creditCard: CreditCard?
    let creditCardValidator: CreditCardValidator

    var month: Int64? {
        Int64(expirationDate.prefix(2))
    }

    var year: Int64? {
        Int64(expirationDate.suffix(2))
    }

    // MARK: View

    var dismiss: ((_ modifiedStatus: CreditCardModifiedStatus,
                   _ successVal: Bool) -> Void)?

    @Published var state: CreditCardEditState
    @Published var errorState: String = ""
    @Published var enteredValue: String = ""
    @Published var cardType: CreditCardType?
    @Published var nameIsValid = true
    @Published var numberIsValid = true
    @Published var expirationIsValid = true
    @Published var nameOnCard: String = ""

    @Published var expirationDate: String = "" {
        didSet {
            var dateVal = expirationDate
            if state == .view {
                // We should cleanup the date before passing for validity check
                dateVal = dateVal.filter { "0123456789".contains($0) }
            }
        }
    }

    @Published var cardNumber: String = "" {
        willSet {
            // Set the card type
            self.cardType = creditCardValidator.cardTypeFor(newValue)
        }
    }

    // MARK: Business logic
    func areFieldValuesValid() -> Bool {
        let isExpirationValid = creditCardValidator.isExpirationValidFor(date: getCopyValueFor(.expiration))
        let numberIsValid = creditCardValidator.isCardNumberValidFor(card: getCopyValueFor(.number))
        let nameIsValid = !getCopyValueFor(.name).isEmpty

        return isExpirationValid && numberIsValid && nameIsValid
    }

    @Published var isRightBarButtonEnabled = false

    var signInRemoveButtonDetails: RemoveCardButton.AlertDetails {
        return RemoveCardButton.AlertDetails(
            alertTitle: Text(CreditCardText.RemoveCardTitle),
            alertBody: Text(CreditCardText.RemoveCardSublabel),
            primaryButtonStyleAndText: .destructive(Text(CreditCardText.RemovedCardLabel)) {
                [unowned self] in
                self.removeCreditCard(creditCard: creditCard) { status, successVal in
                    self.dismiss?(status, successVal)
                }
            },
            secondaryButtonStyleAndText: .cancel(),
            primaryButtonAction: {},
            secondaryButtonAction: {})
    }

    var regularRemoveButtonDetails: RemoveCardButton.AlertDetails {
        return RemoveCardButton.AlertDetails(
            alertTitle: Text(CreditCardText.RemoveCardTitle),
            alertBody: nil,
            primaryButtonStyleAndText: .destructive(Text(CreditCardText.RemovedCardLabel)) {
                [unowned self] in
                self.removeCreditCard(creditCard: creditCard) { status, successVal in
                    self.dismiss?(status, successVal)
                }
            },
            secondaryButtonStyleAndText: .cancel(),
            primaryButtonAction: {},
            secondaryButtonAction: {}
        )
    }

    var removeButtonDetails: RemoveCardButton.AlertDetails {
        return profile.hasSyncableAccount() ? signInRemoveButtonDetails : regularRemoveButtonDetails
    }

    init(profile: Profile,
         creditCard: CreditCard? = nil,
         creditCardValidator: CreditCardValidator = CreditCardValidator(),
         logger: Logger = DefaultLogger.shared
    ) {
        self.profile = profile
        self.autofill = profile.autofill
        self.creditCard = creditCard
        self.state = .add
        self.creditCardValidator = creditCardValidator
        self.logger = logger
        self.isRightBarButtonEnabled = initialStateToEnableTopRightButton()
    }

    init(profile: Profile = AppContainer.shared.resolve(),
         firstName: String,
         lastName: String,
         errorState: String,
         enteredValue: String,
         creditCard: CreditCard? = nil,
         state: CreditCardEditState,
         creditCardValidator: CreditCardValidator = CreditCardValidator()
    ) {
        self.profile = profile
        self.errorState = errorState
        self.enteredValue = enteredValue
        self.autofill = profile.autofill
        self.creditCard = creditCard
        self.state = state
        self.creditCardValidator = creditCardValidator
        self.isRightBarButtonEnabled = initialStateToEnableTopRightButton()
    }

    // MARK: - Helpers

    public func updateState(state: CreditCardEditState) {
        self.state = state
        switch state {
        case .view:
            setupViewValues()
        default:
            break
        }
    }

    public func saveCreditCard(completion: @escaping (CreditCard?, Error?) -> Void) {
        guard let plainCreditCard = getDisplayedCCValues() else {
            completion(nil, InputVMError.unableToSaveCC)
            return
        }

        autofill.addCreditCard(creditCard: plainCreditCard,
                               completion: completion)
    }

    func updateCreditCard(completion: @escaping (Bool, Error?) -> Void) {
        guard let creditCard = creditCard,
              let plainCreditCard = getDisplayedCCValues() else {
            completion(true, InputVMError.unableToUpdateCC)
            return
        }

        autofill.updateCreditCard(id: creditCard.guid,
                                  creditCard: plainCreditCard,
                                  completion: completion)
    }

    func removeCreditCard(creditCard: CreditCard?,
                          completion: @escaping (CreditCardModifiedStatus, Bool) -> Void) {
        guard let currentCreditCard = creditCard,
              !currentCreditCard.guid.isEmpty else {
            completion(.none, false)
            return
        }

        autofill.deleteCreditCard(id: currentCreditCard.guid) {
            status, error in
            guard let error = error, status else {
                completion(.removedCard, true)
                return
            }
            self.logger?.log("Unable to remove credit card: \(error)",
                             level: .warning,
                             category: .storage)
            completion(.none, false)
        }
    }

    public func clearValues() {
        nameOnCard = ""
        cardNumber = ""
        expirationDate = ""
        nameIsValid = true
        expirationIsValid = true
        numberIsValid = true
        creditCard = nil
    }

    public func setupViewValues() {
        guard let creditCard = creditCard else { return }
        nameOnCard = creditCard.ccName
        cardNumber = autofill.decryptCreditCardNumber(
            encryptedCCNum: creditCard.ccNumberEnc) ?? ""
        let month = creditCard.ccExpMonth
        isRightBarButtonEnabled = initialStateToEnableTopRightButton()
        let formattedMonth = month < 10 ? String(format: "%02d", month) : String(month)

        expirationDate = "\(formattedMonth) / \(creditCard.ccExpYear % 100)"
    }

    func initialStateToEnableTopRightButton() -> Bool {
        switch state {
        case .add:
            return false
        case .edit:
            return areFieldValuesValid()
        case .view:
            return true
        }
    }

    func updateRightButtonState() {
        isRightBarButtonEnabled = areFieldValuesValid()
    }

    func getDisplayedCCValues() -> UnencryptedCreditCardFields? {
        guard let cardType = cardType,
              nameIsValid,
              numberIsValid,
              let month = month,
              let year = year else {
            return nil
        }

        // We need to show only 2 digits but save full year for sync
        let period = Int64(Date.getCurrentPeriod())
        let yearVal = year < 1000 ? year + period : year

        let plainCreditCard = UnencryptedCreditCardFields(
                         ccName: nameOnCard,
                         ccNumber: cardNumber,
                         ccNumberLast4: String(cardNumber.suffix(4)),
                         ccExpMonth: month,
                         ccExpYear: yearVal,
                         ccType: cardType.rawValue)

        return plainCreditCard
    }

    func getCopyValueFor(_ inputType: CreditCardInputType) -> String {
        switch inputType {
        case .name:
            return nameOnCard
        case .number:
            return cardNumber
        case .expiration:
            return expirationDate.removingOccurrences(of: " / ")
        }
    }
}
