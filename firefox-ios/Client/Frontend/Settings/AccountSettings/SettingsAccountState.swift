// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Redux

struct SettingsAccountState: ScreenState, Equatable {
    private(set) var bookmarks: Bool
    private(set) var history: Bool
    private(set) var tabs: Bool
    private(set) var passwords: Bool
    private(set) var creditCards: Bool
    private(set) var adresses: Bool
    private(set) var deviceName: String

    init(_ appState: AppState) {
        guard let accountSettingsState = appState.screenState(SettingsAccountState.self, for: .accountSettings)
        else {
            self.init()
            return
        }
        self = accountSettingsState
    }

    init() {
        // initialize state with default values
        self.init(bookmarks: true,
                  history: true,
                  tabs: true,
                  passwords: true,
                  creditCards: true,
                  adresses: true,
                  deviceName: DeviceInfo.defaultClientName())
    }

    init(bookmarks: Bool,
         history: Bool,
         tabs: Bool,
         passwords: Bool,
         creditCards: Bool,
         adresses: Bool,
         deviceName: String) {
        self.bookmarks = bookmarks
        self.history = history
        self.tabs = tabs
        self.passwords = passwords
        self.creditCards = creditCards
        self.adresses = adresses
        self.deviceName = deviceName
    }

    static let reducer: Reducer<Self> = { state, action in
        return state
    }
}
