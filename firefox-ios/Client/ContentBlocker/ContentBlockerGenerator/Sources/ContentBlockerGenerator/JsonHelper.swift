// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct JsonHelper {
    func jsonEntityListFrom(filename: String) -> [String: Any] {
        let file = URL(fileURLWithPath: filename)

        do {
            let data = try Data(contentsOf: file)
            return try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        } catch {
            fatalError("Could not find entity file \(filename) at file \(file)")
        }
    }

    func jsonListFrom(filename: String) -> [String] {
        let file = URL(fileURLWithPath: filename)

        do {
            let data = try Data(contentsOf: file)
            return try JSONSerialization.jsonObject(with: data, options: []) as! [String]
        } catch {
            fatalError("Could not find list file \(filename) at file \(file)")
        }
    }
}
