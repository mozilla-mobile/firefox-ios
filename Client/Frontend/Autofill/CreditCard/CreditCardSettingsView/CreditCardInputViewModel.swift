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

class CreditCardInputViewModel: ObservableObject {
    typealias CreditCardText = String.CreditCard.Alert

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

    @Published var state: CreditCardEditState
    @Published var errorState: String = ""
    @Published var enteredValue: String = ""
    @Published var cardType: CreditCardType?
    @Published var nameIsValid = true
    @Published var numberIsValid = true
    @Published var expirationIsValid = true
    @Published var nameOnCard: String = "" {
        didSet (val) {
            nameIsValid = !nameOnCard.isEmpty
        }
    }

    @Published var expirationDate: String = "" {
        didSet {
            expirationIsValid = creditCardValidator.isExpirationValidFor(date: expirationDate)
        }
    }

    @Published var cardNumber: String = "" {
        willSet {
            // Set the card type
            self.cardType = creditCardValidator.cardTypeFor(newValue)
            numberIsValid = creditCardValidator.isCardNumberValidFor(card: newValue)
        }
    }

    var isRightBarButtonEnabled: Bool {
        state.rightBarBtn == .save && (nameIsValid &&
                                       !nameOnCard.isEmpty &&
                                       numberIsValid &&
                                       !cardNumber.isEmpty &&
                                       expirationIsValid &&
                                       !expirationDate.isEmpty)
    }

    var signInRemoveButtonDetails: RemoveCardButton.AlertDetails {
        return RemoveCardButton.AlertDetails(
            alertTitle: Text(CreditCardText.RemoveCardTitle),
            alertBody: Text(CreditCardText.RemoveCardSublabel),
            primaryButtonStyleAndText: .destructive(Text(CreditCardText.RemovedCardLabel)) { [self] in
                guard let creditCard = creditCard else { return }

                removeSelectedCreditCard(creditCardGUID: creditCard.guid)
            },
            secondaryButtonStyleAndText: .cancel(),
            primaryButtonAction: {},
            secondaryButtonAction: {})
    }

    var regularRemoveButtonDetails: RemoveCardButton.AlertDetails {
        return RemoveCardButton.AlertDetails(
            alertTitle: Text(CreditCardText.RemoveCardTitle),
            alertBody: nil,
            primaryButtonStyleAndText: .destructive(Text(CreditCardText.RemovedCardLabel)) { [self] in
                guard let creditCard = creditCard else { return }

                removeSelectedCreditCard(creditCardGUID: creditCard.guid)
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
         creditCardValidator: CreditCardValidator = CreditCardValidator()
    ) {
        self.profile = profile
        self.autofill = profile.autofill
        self.creditCard = creditCard
        self.state = .add
        self.creditCardValidator = creditCardValidator
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
    }

    // MARK: - Helpers

    private func removeSelectedCreditCard(creditCardGUID: String) {
        autofill.deleteCreditCard(id: creditCardGUID) { _, error in
            // no-op
        }
    }

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
        guard let cardType = cardType,
              nameIsValid,
              numberIsValid,
              let month = month,
              let year = year else {
            return
        }

        let creditCard = UnencryptedCreditCardFields(
                         ccName: nameOnCard,
                         ccNumber: cardNumber,
                         ccNumberLast4: String(cardNumber.suffix(4)),
                         ccExpMonth: month,
                         ccExpYear: year,
                         ccType: cardType.rawValue)

        autofill.addCreditCard(creditCard: creditCard, completion: completion)
    }

    public func clearValues() {
        nameOnCard = ""
        cardNumber = ""
        expirationDate = ""
        nameIsValid = true
        expirationIsValid = true
        numberIsValid = true
    }

    public func setupViewValues() {
        guard let creditCard = creditCard else { return }
        nameOnCard = creditCard.ccName
        cardNumber = autofill.decryptCreditCardNumber(
            encryptedCCNum: creditCard.ccNumberEnc) ?? ""
        let month = creditCard.ccExpMonth
        let formattedMonth = month < 10 ? String(format: "%02d", month) : String(month)

        expirationDate = "\(formattedMonth) / \(creditCard.ccExpYear)"
    }
}
