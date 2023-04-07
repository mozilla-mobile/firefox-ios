// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

class MockDiskImageStore: DiskImageStore {
    func getImageForKey(_ key: String) async throws -> UIImage {
        return UIImage()
    }

    func saveImageForKey(_ key: String, image: UIImage) async throws {}

    func clearAllScreenshotsExcluding(_ keys: Set<String>) async throws {}

    func deleteImageForKey(_ key: String) async {}
}
