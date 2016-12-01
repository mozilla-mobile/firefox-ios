/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class SearchEngine {
    let name: String
    let image: UIImage?

    private let searchTemplate: String
    private let suggestionsTemplate: String?

    init(name: String, image: UIImage?, searchTemplate: String, suggestionsTemplate: String?) {
        self.name = name
        self.image = image
        self.searchTemplate = searchTemplate
        self.suggestionsTemplate = suggestionsTemplate
    }

    func urlForQuery(_ query: String) -> URL? {
        guard let escaped = query.addingPercentEncoding(withAllowedCharacters: .urlQueryParameterAllowed) else {
            assertionFailure("Invalid search URL")
            return nil
        }

        let localeString = NSLocale.current.identifier
        guard let urlString = searchTemplate.replacingOccurrences(of: "{searchTerms}", with: escaped)
            .replacingOccurrences(of: "{moz:locale}", with: localeString)
            .addingPercentEncoding(withAllowedCharacters: .urlAllowed) else
        {
            assertionFailure("Invalid search URL")
            return nil
        }

        return URL(string: urlString)
    }
}
