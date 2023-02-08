// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public class DefaultLogger: Logger {
    public static let shared = DefaultLogger()

    private var logger: SwiftyBeaverWrapper.Type
    private var sentry: SentryWrapper
    private var fileManager: LoggerFileManager

    public var crashedLastLaunch: Bool {
        return sentry.crashedLastLaunch
    }

    init(swiftyBeaverBuilder: SwiftyBeaverBuilder = DefaultSwiftyBeaverBuilder(),
         sentryWrapper: SentryWrapper = DefaultSentryWrapper(),
         fileManager: LoggerFileManager = DefaultLoggerFileManager()) {
        self.fileManager = fileManager
        self.logger = swiftyBeaverBuilder.setup(with: fileManager.getLogDestination())
        self.sentry = sentryWrapper
    }

    public func setup(sendUsageData: Bool) {
        sentry.setup(sendUsageData: sendUsageData)
    }

    public func log(_ message: String,
                    level: LoggerLevel,
                    category: LoggerCategory,
                    extra: [String: String]? = nil,
                    description: String? = nil,
                    file: String = #file,
                    function: String = #function,
                    line: Int = #line) {
        // Prepare messages
        let reducedExtra = reduce(extraEvents: extra)
        let loggerMessage = "\(message) - \(description ?? "")\(reducedExtra)"

        // Log locally and in console
        switch level {
        case .debug:
            logger.debug(loggerMessage, file, function, line: line, context: category)
        case .info:
            logger.info(loggerMessage, file, function, line: line, context: category)
        case .warning:
            logger.warning(loggerMessage, file, function, line: line, context: category)
        case .fatal:
            logger.error(loggerMessage, file, function, line: line, context: category)
        }

        // Log to sentry
        let extraEvents = bundleExtraEvents(extra: extra,
                                            description: description)
        sentry.send(message: message,
                    category: category,
                    level: level,
                    extraEvents: extraEvents)
    }

    public func copyLogsToDocuments() {
        fileManager.copyLogsToDocuments()
    }

    // MARK: - Private

    private func bundleExtraEvents(extra: [String: String]?,
                                   description: String?) -> [String: String] {
        var extraEvents: [String: String] = [:]
        if let paramEvents = extra {
            extraEvents = extraEvents.merge(with: paramEvents)
        }
        if let extraString = description {
            extraEvents = extraEvents.merge(with: ["errorDescription": extraString])
        }

        return extraEvents
    }

    private func reduce(extraEvents: [String: String]?) -> String {
        guard let extras = extraEvents else { return "" }

        return extras.reduce("") { (result: String, arg1) in
            let (key, value) = arg1
            return "\(result), \(key): \(value)"
        }
    }
}
