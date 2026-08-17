// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

enum WebCompatURLValidator {
    /// `URIFixup` alone turns " .com" into `http://.com`, so empty host labels are rejected too.
    static func reportableURL(from text: String) -> URL? {
        guard let url = URIFixup.getURL(text),
              url.isWebPage(includeDataURIs: false),
              let host = url.host,
              host.split(separator: ".", omittingEmptySubsequences: false).allSatisfy({ !$0.isEmpty })
        else { return nil }
        return url
    }
}
