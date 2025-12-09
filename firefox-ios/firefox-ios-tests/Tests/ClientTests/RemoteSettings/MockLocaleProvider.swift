// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

struct MockLocaleProvider: LocaleProvider {
    let current: Locale
    let preferredLanguages: [String]
    let localeRegionCode: String?
    let searchRegionCode: String

    init(
        current: Locale = Locale(identifier: "en-US"),
        preferredLanguages: [String] = ["en-US"],
        localeRegionCode: String? = nil,
        searchRegionCode: String = "US"
    ) {
        self.current = current
        self.preferredLanguages = preferredLanguages
        self.localeRegionCode = localeRegionCode
        self.searchRegionCode = searchRegionCode
    }

    static func defaultEN() -> MockLocaleProvider {
        MockLocaleProvider()
    }
}
