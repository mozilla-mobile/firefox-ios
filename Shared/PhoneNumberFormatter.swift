/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import libPhoneNumber

public class PhoneNumberFormatter {

    private let util: NBPhoneNumberUtil

    // MARK: - Object Lifecycle

    public convenience init() {
        self.init(util: NBPhoneNumberUtil.sharedInstance())
    }

    init(util: NBPhoneNumberUtil) {
        self.util = util
    }

    // MARK: Formatting

    /// Tries to convert a phone number to a region-specific format. For national numbers the country code is guessed from the current carrier and
    /// region settings. If parsing, validating or formatting fails, the input string is returned.
    public func formatPhoneNumber(rawNumber: String, fallbackLocale: NSLocale = NSLocale.currentLocale()) -> String {
        let countryCode = guessCurrentCountryCode(fallbackLocale)

        guard let parsedNumber = try? util.parseAndKeepRawInput(rawNumber, defaultRegion: countryCode) where util.isValidNumber(parsedNumber) else {
            return rawNumber
        }

        let format = formatForNumber(parsedNumber)

        if let formattedNumber = try? util.format(parsedNumber, numberFormat: format) {
            return formattedNumber
        }

        return rawNumber
    }

    // MARK: - Helpers

    func guessCurrentCountryCode(fallbackLocale: NSLocale) -> String {
        if let carrierCode = util.countryCodeByCarrier() where !carrierCode.isEmpty && carrierCode != NB_UNKNOWN_REGION {
            return carrierCode
        }
        return fallbackLocale.objectForKey(NSLocaleCountryCode) as! String
    }

    func formatForNumber(number: NBPhoneNumber) -> NBEPhoneNumberFormat {
        assert(number.countryCodeSource != nil, "The phone number's country code source must be filled during parsing")
        if NBECountryCodeSource(rawValue: number.countryCodeSource.integerValue) == .FROM_DEFAULT_COUNTRY {
            return .NATIONAL
        }
        return .INTERNATIONAL
    }

}
