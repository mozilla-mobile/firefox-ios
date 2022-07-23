// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import XCGLogger

protocol Loggable {
    var browserLog: RollingFileLogger { get }
    var keychainLog: XCGLogger { get }
    var syncLog: RollingFileLogger { get }
}

extension Loggable {
    var browserLog: RollingFileLogger {
        Logger.browserLogger
    }

    var keychainLog: XCGLogger {
        Logger.keychainLogger
    }

    var syncLog: RollingFileLogger {
        Logger.syncLogger
    }
}
