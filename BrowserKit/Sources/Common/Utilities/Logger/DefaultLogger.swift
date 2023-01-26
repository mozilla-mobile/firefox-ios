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

    public func verbose(_ message: String,
                        category: LoggerCategory,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line) {
        logger.verbose(message,
                       file,
                       function,
                       line: line,
                       context: category.rawValue)
    }

    public func debug(_ message: String,
                      category: LoggerCategory,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        logger.debug(message,
                     file,
                     function,
                     line: line,
                     context: category.rawValue)
    }

    public func info(_ message: String,
                     category: LoggerCategory,
                     file: String = #file,
                     function: String = #function,
                     line: Int = #line) {
        logger.info(message,
                    file,
                    function,
                    line: line,
                    context: category.rawValue)
    }

    public func warning(_ message: String,
                        category: LoggerCategory,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line) {
        logger.warning(message,
                       file,
                       function,
                       line: line,
                       context: category.rawValue)
    }

    public func error(_ message: String,
                      category: LoggerCategory,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        logger.error(message,
                     file,
                     function,
                     line: line,
                     context: category.rawValue)
    }

    public func fatal(_ message: String,
                      category: LoggerCategory,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        // Currently no way for Swiftybeaver to have fatal log levels.
        // Let's keep the possibility open in our code since other logger supports this.
        logger.error(message,
                     file,
                     function,
                     line: line,
                     context: category.rawValue)
    }

    public func copyLogsToDocuments() {
        guard let defaultLogDirectoryPath = logger.logFileDirectoryPath(inDocuments: false),
              let documentsLogDirectoryPath = logger.logFileDirectoryPath(inDocuments: true),
              let previousLogFiles = try? FileManager.default.contentsOfDirectory(atPath: defaultLogDirectoryPath) else { return }

        let defaultLogDirectoryURL = URL(fileURLWithPath: defaultLogDirectoryPath, isDirectory: true)
        let documentsLogDirectoryURL = URL(fileURLWithPath: documentsLogDirectoryPath, isDirectory: true)
        for previousLogFile in previousLogFiles {
            let previousLogFileURL = defaultLogDirectoryURL.appendingPathComponent(previousLogFile)
            let targetLogFileURL = documentsLogDirectoryURL.appendingPathComponent(previousLogFile)
            try? FileManager.default.copyItem(at: previousLogFileURL, to: targetLogFileURL)
        }
    }
}
