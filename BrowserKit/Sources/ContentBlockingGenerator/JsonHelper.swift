// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

struct JsonHelper {
    private let logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    func jsonEntityListFrom(filename: String) -> [String: Any] {
        let file = URL(fileURLWithPath: filename)
        
        do {
            let data = try Data(contentsOf: file)
            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                return jsonObject
            } else {
                logger.log("Invalid JSON format for parsing entity list as dictionary from the file \(filename)",
                           level: .fatal,
                           category: .storage)
            }
        } catch {
            fatalError("Could not find entity file \(filename) at file \(file)")
        }
        return [:]
    }

    func jsonListFrom(filename: String) -> [String] {
        let file = URL(fileURLWithPath: filename)
        
        do {
            let data = try Data(contentsOf: file)
            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String] {
                return jsonObject
            } else {
                logger.log("Invalid JSON format for parsing entity list as array from the file \(filename)",
                           level: .info,
                           category: .storage)
            }
        } catch {
            fatalError("Could not find list file \(filename) at file \(file)")
        }
        return []
    }
}
