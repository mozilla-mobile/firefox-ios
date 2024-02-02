// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import Storage
import Common

final class AppStartupTelemetry {
    let profile: Profile

    // MARK: Init
    required init(profile: Profile = AppContainer.shared.resolve()) {
        self.profile = profile
    }

    // MARK: Logic
    public func sendStartupTelemetry() {
        _ = profile.autofill.reopenIfClosed()
        profile.autofill.listCreditCards(completion: { cards, error in
            guard let cards = cards, error == nil else { return }
            self.sendCreditCardsSavedAllTelemetry(numberOfSavedCreditCards: cards.count)
        })

        let searchController = UISearchController()
        let loginsViewModel = PasswordManagerViewModel(
            profile: profile,
            searchController: searchController,
            theme: LightTheme()
        )
        let dataSource = LoginDataSource(viewModel: loginsViewModel)
        loginsViewModel.loadLogins(loginDataSource: dataSource)

        loginsViewModel.queryLogins("") { logins in
            self.sendLoginsSavedAllTelemetry(numberOfSavedLogins: logins.count)
        }
    }

    // MARK: Telemetry Events
    private func sendLoginsSavedAllTelemetry(numberOfSavedLogins: Int) {
        let savedLoginsExtra = [TelemetryWrapper.EventExtraKey.loginsQuantity.rawValue: Int64(numberOfSavedLogins)]
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .foreground,
                                     object: .loginsSavedAll,
                                     extras: savedLoginsExtra)
    }

    private func sendCreditCardsSavedAllTelemetry(numberOfSavedCreditCards: Int) {
        let savedCardsExtra = [
            TelemetryWrapper.EventExtraKey.creditCardsQuantity.rawValue: Int64(numberOfSavedCreditCards)
        ]
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .foreground,
                                     object: .creditCardSavedAll,
                                     extras: savedCardsExtra)
    }
}
