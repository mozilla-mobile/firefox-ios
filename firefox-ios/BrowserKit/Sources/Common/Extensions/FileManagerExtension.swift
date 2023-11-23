// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public extension FileManager {
    func contentsOfDirectoryAtPath(_ path: String, withFilenamePrefix prefix: String) throws -> [String] {
        return try FileManager.default.contentsOfDirectory(atPath: path)
            .filter { $0.hasPrefix("\(prefix).") }
            .sorted { $0 < $1 }
    }

    static var documentsDirectoryURL: URL {
      return `default`.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
