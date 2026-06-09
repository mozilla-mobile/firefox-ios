// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

import enum MozillaAppServices.Level
import protocol MozillaAppServices.AppServicesLogger
import struct MozillaAppServices.Record

/// The `ForwardOnLog` class exists to support the rust-log-forwarder `setLogger` function.
/// TODO(FXIOS-12942): Implement proper thread-safety
internal final class ForwardOnLog: AppServicesLogger, @unchecked Sendable {
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
