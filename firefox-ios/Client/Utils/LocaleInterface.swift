// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// TODO: FXIOS-14268 - Clean up locale interfaces + extensions
protocol LocaleInterface {
    var localeRegionCode: String? { get }
}

extension Locale: LocaleInterface {
    var localeRegionCode: String? {
        return self.regionCode
    }
}

protocol LocaleProvider {
    var current: Locale { get }
    var preferredLanguages: [String] { get }
    var regionCode: String { get }
}

struct SystemLocaleProvider: LocaleProvider {
    var current: Locale {
        .current
    }

    var preferredLanguages: [String] {
        Locale.preferredLanguages
    }

    var regionCode: String {
        Locale.current.regionCode()
    }
}
