// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebEngine

/// Minimal in-memory `ReaderModeCache` mock for unit tests. Backed by a `[URL: ReadabilityResult]`
/// dictionary. Throws `NSError(domain: ReaderModeError.domain, code: noPathsFound)` on miss to
/// match what the disk and memory caches return, so error-handling code paths exercise the same
/// shape they would in production.
final class MockReaderModeCache: ReaderModeCache, @unchecked Sendable {
    private var storage: [URL: ReadabilityResult] = [:]

    init(_ initial: [URL: ReadabilityResult] = [:]) {
        self.storage = initial
    }

    func put(_ url: URL, _ readabilityResult: ReadabilityResult) throws {
        storage[url] = readabilityResult
    }

    func get(_ url: URL) throws -> ReadabilityResult {
        guard let result = storage[url] else {
            throw NSError(domain: "com.mozilla.client.readermodecache.", code: 0, userInfo: nil)
        }
        return result
    }

    func delete(_ url: URL, error: NSErrorPointer) {
        storage.removeValue(forKey: url)
    }

    func contains(_ url: URL) -> Bool {
        return storage[url] != nil
    }

    func clear() {
        storage.removeAll()
    }
}
