// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct Tab: Codable, Identifiable {
    public var page: Page?
    public let id: UUID

    public init(page: Page?) {
        self.page = page
        id = .init()
    }
}

public extension Tab {
    var snapshot: Data? {
        return try? Data(contentsOf: FileManager.snapshots.appendingPathComponent(id.uuidString))
    }
}
