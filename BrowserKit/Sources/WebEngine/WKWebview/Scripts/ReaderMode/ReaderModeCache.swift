// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol ReaderModeCache {
    func put(_ url: URL, _ readabilityResult: ReadabilityResult) throws

    func get(_ url: URL) throws -> ReadabilityResult

    func delete(_ url: URL, error: NSErrorPointer)

    func contains(_ url: URL) -> Bool

    func clear()
}
