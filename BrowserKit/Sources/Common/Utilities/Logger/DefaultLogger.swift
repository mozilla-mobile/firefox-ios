// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public class DefaultLogger: Logger {
    public static let shared = DefaultLogger()
    private var logger: SwiftyBeaverWrapper.Type

    init(swiftyBeaver: SwiftyBeaverWrapper.Type = DefaultSwiftyBeaver.implementation) {
        self.logger = swiftyBeaver
    }

    public func log(_ message: String,
                    level: LoggerLevel,
                    category: LoggerCategory,
                    sendToSentry: Bool = false,
                    file: String = #file,
                    function: String = #function,
                    line: Int = #line) {
        switch level {
        case .info:
            logger.info(message, file, function, line: line, context: category)
        case .warning:
            logger.warning(message, file, function, line: line, context: category)
        case .fatal:
            logger.error(message, file, function, line: line, context: category)
        }
    }

    public func copyLogsToDocuments() {
        guard let defaultLogDirectoryPath = logger.logFileDirectoryPath(inDocuments: false),
              let documentsLogDirectoryPath = logger.logFileDirectoryPath(inDocuments: true),
              let previousLogFiles = try? FileManager.default.contentsOfDirectory(atPath: defaultLogDirectoryPath)
        else { return }

        let defaultLogDirectoryURL = URL(fileURLWithPath: defaultLogDirectoryPath, isDirectory: true)
        let documentsLogDirectoryURL = URL(fileURLWithPath: documentsLogDirectoryPath, isDirectory: true)
        for previousLogFile in previousLogFiles {
            let previousLogFileURL = defaultLogDirectoryURL.appendingPathComponent(previousLogFile)
            let targetLogFileURL = documentsLogDirectoryURL.appendingPathComponent(previousLogFile)
            try? FileManager.default.copyItem(at: previousLogFileURL, to: targetLogFileURL)
        }
    }
}
