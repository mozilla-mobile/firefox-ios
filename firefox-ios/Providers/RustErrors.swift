// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

import enum MozillaAppServices.Level
import func MozillaAppServices.setApplicationErrorReporter
import protocol MozillaAppServices.ApplicationErrorReporter
import protocol MozillaAppServices.AppServicesLogger
import struct MozillaAppServices.Record

public func initializeRustErrors(logger: Logger) {
    setApplicationErrorReporter(errorReporter: FirefoxIOSErrorReporter(logger: logger))
}

/// The `AppServicesErrorReport` class (with its inheritance from `CustomCrashReport`) exists
/// to distinguish native Sentry reports from reports originating in A-S
private class AppServicesErrorReport: Error, CustomCrashReport {
    var typeName: String
    var message: String

    init(typeName: String, message: String) {
        self.typeName = typeName
        self.message = message
    }
}

/// The `FirefoxIOSErrorReporter` class contains the callbacks A-S uses to report Sentry errors and
/// breadcrumbs. These functions are not intended to be explicitly called in this repo.
private class FirefoxIOSErrorReporter: ApplicationErrorReporter {
    var logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    func reportError(typeName: String, message: String) {
        logger.logCustomError(error: AppServicesErrorReport(typeName: typeName, message: message))
    }

    func reportBreadcrumb(message: String, module: String, line: UInt32, column: UInt32) {
        logger.log("\(module)[\(line)]: \(message)",
                   level: .info,
                   category: .sync)
    }
}

/// The `ForwardOnLog` class exists to support the rust-log-forwarder `setLogger` function.
internal class ForwardOnLog: AppServicesLogger {
    var logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    func log(record: Record) {
        self.logger.log(record.message,
                        level: rustLevelToLoggerLevel(level: record.level),
                        category: LoggerCategory.sync,
                        extra: ["target": record.target])
    }

    private func rustLevelToLoggerLevel(level: Level) -> LoggerLevel {
        switch level {
        case .trace:
            return LoggerLevel.debug
        case .debug:
            return LoggerLevel.debug
        case .info:
            return LoggerLevel.info
        case .warn:
            return LoggerLevel.warning
        case .error:
            // TODO: FXIOS-7819 need to rethink if this should go to Sentry, setting as warning to bypass for now
            return LoggerLevel.warning
        }
    }
}
