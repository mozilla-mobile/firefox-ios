// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import TabDataStore
import Common

class TabFileManagerMock: TabFileManager {
    func tabDataDirectory() -> URL? {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    }

    func contentsOfDirectory(at path: URL) -> [URL] {
        return []
    }
}
