// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

struct DefaultBrowserUtil {
    let userDefault: UserDefaults
    let dmaCountries = ["BE","BG","CZ","DK","DE","EE","IE","EL","ES","FR","HR","IT","CY","LV","LT","LU","HU","MT","NL","AT","PL","PT","RO","SI","SK","FI","SE","GR"]
    init(userDefault: UserDefaults = UserDefaults.standard) {
        self.userDefault = userDefault
    }

    func processUserDefaultState(isFirstRun: Bool) {
        guard #available(iOS 18.2, *),
              let isDefault = UIApplication().isDefaultApplication(for: .webBrowser)
        else { return }

        trackIfUserIsDefault(isDefault)

        if isDefault && isFirstRun {
            trackIfUserIsComingFromBrowserChoiceScreen(isDefault)
            // If the user is set to default don't ask on the home page later
            // This is temporary until we can refactor set to default now that we have the ability to check
            UserDefaults.standard.set(true, forKey: PrefsKeys.DidDismissDefaultBrowserMessage)
        }

        UserDefaults.standard.set(isDefault, forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser)
    }

    private func trackIfUserIsDefault(_ isDefault: Bool) {
        // TODO: Track an event
    }

    private func trackIfUserIsComingFromBrowserChoiceScreen(_ isDefault: Bool) {
        // User is in a DMA effective region
        if dmaCountries(contains: Locale.current.regionCode) {
            // TODO: Track an event
        }
    }
}
