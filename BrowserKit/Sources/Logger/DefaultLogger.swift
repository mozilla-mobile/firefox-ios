// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public class DefaultLogger: Logger {
    public static let shared = DefaultLogger()
    private var logger: SwiftyBeaverWrapper.Type
    private var fileManager: LoggerFileManager

    init(swiftyBeaverBuilder: SwiftyBeaverBuilder = DefaultSwiftyBeaverBuilder(),
         fileManager: LoggerFileManager = DefaultLoggerFileManager()) {
        self.fileManager = fileManager
        self.logger = swiftyBeaverBuilder.setup(with: fileManager.getLogDestination())
    }

    public func log(_ message: String,
                    level: LoggerLevel,
                    category: LoggerCategory,
                    sendToSentry: Bool = false,
                    file: String = #file,
                    function: String = #function,
                    line: Int = #line) {
        switch level {
        case .debug:
            logger.debug(message, file, function, line: line, context: category)
        case .info:
            logger.info(message, file, function, line: line, context: category)
        case .warning:
            logger.warning(message, file, function, line: line, context: category)
        case .fatal:
            logger.error(message, file, function, line: line, context: category)
        }
    }

    public func copyLogsToDocuments() {
        fileManager.copyLogsToDocuments()
    }
}
