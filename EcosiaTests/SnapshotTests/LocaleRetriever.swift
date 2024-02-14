// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct LocaleRetriever {

    private init() {}

    // Function to get locales from the JSON file
    static func getLocales() -> [Locale] {
        // Load the JSON file from the app bundle
        guard let testBundle = Bundle(identifier: "com.ecosia.ecosiaapp.EcosiaSnapshotTests"),
              let path = testBundle.path(forResource: "environment", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let dict = json as? [String: String],
              let localesString = dict["LOCALES"] else {
            // Fallback to default locale if the JSON file is not found or cannot be parsed
            return [Locale(identifier: "en")]
        }
        let localeIdentifiers = localesString.split(separator: ",").map({ String($0) })
        return localeIdentifiers.map { Locale(identifier: $0) }
    }
}
