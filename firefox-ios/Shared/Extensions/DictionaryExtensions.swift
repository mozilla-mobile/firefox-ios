// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

extension Dictionary {
    public var asString: String? {
        guard let jsonData = try? JSONSerialization.data(
            withJSONObject: self,
            options: .prettyPrinted
        ) else { return nil }

        let jsonString = String(data: jsonData, encoding: .utf8)
        return jsonString
    }
}
