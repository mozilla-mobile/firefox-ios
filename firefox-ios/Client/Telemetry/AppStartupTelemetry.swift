// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import Storage
import Common

import class MozillaAppServices.BookmarkFolderData
import enum MozillaAppServices.BookmarkRoots

final class AppStartupTelemetry {
    let profile: Profile

    // MARK: Init
    required init(profile: Profile = AppContainer.shared.resolve()) {
        self.profile = profile
    }

    // MARK: Logic
    public func sendStartupTelemetry() {
        queryCreditCards()
        queryLogins()
        queryBookmarks()
        queryAddresses()
    }

    // MARK: Credit Cards
    func queryCreditCards() {
        _ = profile.autofill.reopenIfClosed()
        profile.autofill.listCreditCards(completion: { cards, error in
            guard let cards = cards, error == nil else { return }
            self.sendCreditCardsSavedAllTelemetry(numberOfSavedCreditCards: cards.count)
        })
    }

    // MARK: Logins
    func queryLogins() {
        let searchController = UISearchController()
        let loginsViewModel = PasswordManagerViewModel(
            profile: profile,
            searchController: searchController,
            theme: LightTheme(),
            loginProvider: profile.logins
        )
        let dataSource = LoginDataSource(viewModel: loginsViewModel)
        loginsViewModel.loadLogins(loginDataSource: dataSource)

        loginsViewModel.queryLogins("") { logins in
            self.sendLoginsSavedAllTelemetry(numberOfSavedLogins: logins.count)
        }
    }

    func queryAddresses() {
        profile.autofill.listAllAddresses(completion: { [weak self] addresses, error in
            guard let addresses = addresses, error == nil else { return }
            self?.sendAddressAutofillSavedAllTelemetry(numberOfAddresses: addresses.count)
        })
    }

    // MARK: Bookmarks
    func queryBookmarks() {
        profile.places
            .getBookmarksTree(rootGUID: BookmarkRoots.MobileFolderGUID, recursive: false)
            .uponQueue(.main) { result in
                guard let mobileFolder = result.successValue as? BookmarkFolderData else {
                    return
                }

                if let mobileBookmarks = mobileFolder.fxChildren, !mobileBookmarks.isEmpty {
                    self.sendDoesHaveMobileBookmarksTelemetry()
                    self.sendMobileBookmarksCountTelemetry(bookmarksCount: Int64(mobileBookmarks.count))
                } else {
                    self.sendDoesntHaveMobileBookmarksTelemetry()
                }
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

    private func sendAddressAutofillSavedAllTelemetry(numberOfAddresses: Int) {
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .foreground,
            object: .addressAutofillSettings,
            extras: [TelemetryWrapper.EventExtraKey.AddressTelemetry.count.rawValue: Int64(numberOfAddresses)]
        )
    }

    private func sendDoesHaveMobileBookmarksTelemetry() {
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .mobileBookmarks,
                                     value: .doesHaveMobileBookmarks)
    }

    private func sendDoesntHaveMobileBookmarksTelemetry() {
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .mobileBookmarks,
                                     value: .doesNotHaveMobileBookmarks)
    }

    private func sendMobileBookmarksCountTelemetry(bookmarksCount: Int64) {
        let mobileBookmarksExtra = [
            TelemetryWrapper.EventExtraKey.mobileBookmarksQuantity.rawValue: bookmarksCount
        ]

        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .mobileBookmarks,
                                     value: .mobileBookmarksCount,
                                     extras: mobileBookmarksExtra)
    }
}
