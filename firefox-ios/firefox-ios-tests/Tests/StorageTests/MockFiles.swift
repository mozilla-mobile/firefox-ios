// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Storage
import XCTest

class MockFiles: FileAccessor {
    var rootPath: String

    init() {
        let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        rootPath = (docPath as NSString).appendingPathComponent("testing")
    }
}

class SupportingFiles: FileAccessor {
    var rootPath: String

    init() {
        rootPath = Bundle.main.bundlePath + "/PlugIns/StorageTests.xctest/"
    }
}
