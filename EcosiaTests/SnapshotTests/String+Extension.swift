// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension String {
    static func cleanFunctionName(_ name: String) -> String {
        return name.replaceFirstOccurrence(of: "()", with: "")
    }

    func camelCaseToSnakeCase() -> String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: self.utf16.count)
        let result = regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
        return result?.lowercased() ?? ""
    }
}
