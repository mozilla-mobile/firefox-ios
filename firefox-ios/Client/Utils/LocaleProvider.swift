// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol LocaleProvider {
    var current: Locale { get }
    var preferredLanguages: [String] { get }
    var localeRegionCode: String? { get }
    var searchRegionCode: String { get }
}

struct SystemLocaleProvider: LocaleProvider {
    var current: Locale {
        return Locale.current
    }

    var preferredLanguages: [String] {
        return Locale.preferredLanguages
    }

    var localeRegionCode: String? {
        return Locale.current.regionCode
    }
    // The locale handling for our Remote Settings search engines had some additional requirements
    // that was needed in addition to existing `Locale.current.regionCode` so we add an extension that
    // satisfy the requirements and allows us to be consistent with Android and Desktop. FXSuggest also
    // adapted this requirement because it is related to search.
    var searchRegionCode: String {
        return Locale.current.regionCode()
    }
}
