// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

public final class MockLogger: Logger, @unchecked Sendable {
    public var crashedLastLaunch = false
    public var savedMessage: String?
    public var savedLevel: LoggerLevel?
    public var savedCategory: LoggerCategory?
    public var savedExtra: [String: String]?

    public init() { }

    public func setup(sendCrashReports: Bool) {}
    public func copyLogsToDocuments() {}
    public func logCustomError(error: Error) {}
    public func deleteCachedLogFiles() {}

    public func log(
        _ message: String,
        level: LoggerLevel,
        category: LoggerCategory,
        extra: [String: String]? = nil,
        description: String? = nil,
        file: String = #filePath,
        function: String = #function,
        line: Int = #line
    ) {
        savedMessage = message
        savedLevel = level
        savedCategory = category
        savedExtra = extra
    }
}
