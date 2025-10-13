// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension Locale {

    var identifierWithDashedLanguageAndRegion: String {
        identifier.replacingOccurrences(of: "_", with: "-").lowercased()
    }

    var regionIdentifier: String? {
        if #available(iOS 16, macOS 13, *) {
            return region?.identifier
        } else {
            return regionCode
        }
    }

    public var regionIdentifierLowercasedWithFallbackValue: String {
        regionIdentifier?.lowercased() ?? "us"
    }

    public var englishLocalizedCountryName: String? {
        guard let regionIdentifier = regionIdentifier else { return nil }
        return Locale(identifier: "en_US").localizedString(forRegionCode: regionIdentifier)
    }
}

extension Locale: RegionLocatable {}
