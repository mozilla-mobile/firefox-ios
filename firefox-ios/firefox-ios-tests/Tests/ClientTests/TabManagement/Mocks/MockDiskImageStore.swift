// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

final class MockDiskImageStore: DiskImageStore, @unchecked Sendable {
    private let lock = NSLock()
    var getImageForKeyCallCount = 0
    var getImageForKeyCalls: [String] = []
    var onGetImageForKey: (() -> Void)?
    var saveImageForKeyCallCount = 0
    var deleteImageForKeyCallCount = 0

    func getImageForKey(_ key: String) async throws -> UIImage {
        recordGetImageForKey(key)?()
        return UIImage()
    }

    private func recordGetImageForKey(_ key: String) -> (() -> Void)? {
        lock.lock()
        defer { lock.unlock() }
        getImageForKeyCallCount += 1
        getImageForKeyCalls.append(key)
        return onGetImageForKey
    }

    func saveImageForKey(_ key: String, image: UIImage) async throws {
        saveImageForKeyCallCount += 1
    }

    func clearAllScreenshotsExcluding(_ keys: Set<String>) async throws {}

    func deleteImageForKey(_ key: String) async {
        deleteImageForKeyCallCount += 1
    }
}
