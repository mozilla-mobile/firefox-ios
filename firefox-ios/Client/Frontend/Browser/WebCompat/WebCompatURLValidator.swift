// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

enum WebCompatURLValidator {
    /// `URIFixup` alone turns `.com` into `http://.com` and escapes inner spaces instead of
    /// rejecting them, so hosts carrying an empty or whitespaced label are turned down too.
    static func isReportable(_ text: String) -> Bool {
        guard let url = URIFixup.getURL(text),
              url.isWebPage(includeDataURIs: false),
              let host = url.host
        else { return false }
        return host.split(separator: ".", omittingEmptySubsequences: false)
            .allSatisfy { !$0.isEmpty && !$0.contains(where: \.isWhitespace) }
    }
}
