// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension Locale {
    func possibilitiesForLanguageIdentifier() -> [String] {
        var possibilities: [String] = []
        let components = identifier.components(separatedBy: "-")

        possibilities.append(identifier)

        if components.count == 3,
           let first = components.first,
           let last = components.last {
            possibilities.append("\(first)-\(last)")
        }
        if components.count >= 2,
            let first = components.first {
            possibilities.append("\(first)")
        }

        return possibilities
    }
}
