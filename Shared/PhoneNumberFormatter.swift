/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import libPhoneNumberiOS

open class PhoneNumberFormatter {

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
    open func formatPhoneNumber(_ rawNumber: String, fallbackLocale: Locale = Locale.current) -> String {
        let countryCode = guessCurrentCountryCode(fallbackLocale)

        guard let parsedNumber = try? util.parseAndKeepRawInput(rawNumber, defaultRegion: countryCode), util.isValidNumber(parsedNumber) else {
            return rawNumber
        }

        let format = formatForNumber(parsedNumber)

        if let formattedNumber = try? util.format(parsedNumber, numberFormat: format) {
            return formattedNumber
        }

        return rawNumber
    }

    // MARK: - Helpers

    func guessCurrentCountryCode(_ fallbackLocale: Locale) -> String {
        if let carrierCode = util.countryCodeByCarrier(), !carrierCode.isEmpty && carrierCode != NB_UNKNOWN_REGION {
            return carrierCode
        }
        return (fallbackLocale as NSLocale).object(forKey: NSLocale.Key.countryCode) as! String
    }

    func formatForNumber(_ number: NBPhoneNumber) -> NBEPhoneNumberFormat {
        assert(number.countryCodeSource != nil, "The phone number's country code source must be filled during parsing")
        if NBECountryCodeSource(rawValue: number.countryCodeSource.intValue) == .FROM_DEFAULT_COUNTRY {
            return .NATIONAL
        }
        return .INTERNATIONAL
    }

}
