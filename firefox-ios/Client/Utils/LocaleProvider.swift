// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

protocol LocaleProvider {
    var current: Locale { get }
    var preferredLanguages: [String] { get }
    func regionCode(fallback: String?) -> String
}

extension LocaleProvider {
    // Default usage of region code that should be used unless
    // we explicitly want to set a specific fallback (rare cases).
    func regionCode() -> String {
        return regionCode(fallback: nil)
    }
}

struct SystemLocaleProvider: LocaleProvider {
    private let logger: Logger
    private let injectedLocale: Locale

    init(
        logger: Logger = DefaultLogger.shared,
        injectedLocale: Locale = Locale.current
    ) {
        self.logger = logger
        self.injectedLocale = injectedLocale
    }

    var current: Locale {
        return injectedLocale
    }

    var preferredLanguages: [String] {
        return Locale.preferredLanguages
    }

    /// Returns the current system region code with a safe fallback.
    ///
    /// This property attempts to retrieve the region code from `Locale` using
    /// the most appropriate API available for the current iOS version:
    /// - On iOS 16 and later, it uses `Locale.region?.identifier`.
    /// - On earlier versions, it falls back to `Locale.regionCode`.
    ///
    /// If all attempts fail, this method logs a fatal error and returns a specified fallback or by default `"und"`,
    /// the BCP-47 primary language subtag for *Undetermined* linguistic content.
    ///
    /// - Returns: A region code string (e.g. `"US"`, `"CA"`), or fallback string or `"und"` if the
    ///   region cannot be determined.
    func regionCode(fallback: String?) -> String {
        let systemRegion: String?
        if #available(iOS 16, *) {
            systemRegion = current.region?.identifier
        } else {
            systemRegion = current.regionCode
        }

        guard let systemRegion else {
            self.logger.log(
                "Unable to retrieve region code from Locale, so return undetermined",
                level: .fatal,
                category: .locale,
                extra: ["Locale identifier": "\(current.identifier)"]
            )

            // The 'und' (Undetermined) primary language subtag
            // identifies linguistic content whose language is not determined.
            // See https://www.ietf.org/rfc/bcp/bcp47.txt
            return fallback ?? "und"
        }

        return systemRegion
    }
}
