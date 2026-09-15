// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class MockBrowserProfile: BrowserProfile, @unchecked Sendable {
    /// Closes the stores and deletes the on-disk profile directory this instance created.
    func removeDirectory() {
        shutdown()
        try? FileManager.default.removeItem(atPath: files.rootPath)
    }
}

extension XCTestCase {
    /// A `MockBrowserProfile` whose directory is removed when the current test finishes.
    func makeBrowserProfile(localName: String) -> MockBrowserProfile {
        let profile = MockBrowserProfile(localName: localName)
        addTeardownBlock { profile.removeDirectory() }
        return profile
    }
}
