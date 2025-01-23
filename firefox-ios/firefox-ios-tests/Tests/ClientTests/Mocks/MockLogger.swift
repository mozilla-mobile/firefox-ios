// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

class MockLogger: Logger {
    var crashedLastLaunch = false
    var savedMessage: String?
    var savedLevel: LoggerLevel?
    var savedCategory: LoggerCategory?

    func setup(sendCrashReports: Bool) {}
    func configure(crashManager: Common.CrashManager) {}
    func copyLogsToDocuments() {}
    func logCustomError(error: Error) {}
    func deleteCachedLogFiles() {}

    func log(_ message: String,
             level: LoggerLevel,
             category: LoggerCategory,
             extra: [String: String]? = nil,
             description: String? = nil,
             file: String = #file,
             function: String = #function,
             line: Int = #line) {
        savedMessage = message
        savedLevel = level
        savedCategory = category
    }
}
