/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class SearchEngine {
    private let template = "https://search.yahoo.com/yhs/search?ei=UTF-8&hspart=mozilla&hsimp=yhsm-002&p=%s&type=ios"

    func urlForQuery(_ query: String) -> URL? {
        guard let escaped = query.addingPercentEncoding(withAllowedCharacters: .urlQueryParameterAllowed),
              let url = URL(string: template.replacingOccurrences(of: "%s", with: escaped)) else {
            assertionFailure("Invalid search URL")
            return nil
        }

        return url
    }

    func isSearchURL(url: URL) -> Bool {
        return url.host == "search.yahoo.com"
    }
}
