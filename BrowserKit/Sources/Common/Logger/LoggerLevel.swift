// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Sentry

// Log levels are kept to a minimum to make sure they are relevant and useful. If your log isn't important enough
// to make it to this list, then it shouldn't be logged.
public enum LoggerLevel: String {
    // Less granular compared to the VERBOSE level, but it is more than you will need in everyday use. The
    // DEBUG log level should be used for information that may be needed for diagnosing issues and troubleshooting or
    // when running application in the test environment for the purpose of making sure everything is running correctly.
    case debug

    // INFO messages are like the normal behavior of applications. They state what happened. For example, if a
    // particular service stopped or started or you added something to the database, or a view was shown or hidden.
    // These entries are nothing to worry about during usual operations. The information logged using the INFO log is
    // usually informative, and it does not necessarily require you to follow up on it.
    case info

    // The WARNING log level is used when you have detected an unexpected application problem. This means you are not
    // quite sure whether the problem will recur or remain. You may not notice any harm to your application at this
    // point. This issue is usually a situation that stops specific processes from running. This log level is used when
    // a severe issue is stopping functions within the application from operating efficiently. Most of the time, the
    // application will continue to run, but eventually, it will need to be addressed by creating a ticket for it.
    case warning

    // FATAL means that the application is about to stop a serious problem or corruption from happening. The FATAL
    // level of logging shows that the application’s situation is catastrophic, such that an important function is not
    // working. For example, you can use FATAL log level if the application is unable to connect to the data store.
    case fatal

    private var value: Int {
        switch self {
        case .debug:
            return 0
        case .info:
            return 1
        case .warning:
            return 2
        case .fatal:
            return 3
        }
    }

    func isGreaterOrEqualThanLevel(_ level: LoggerLevel) -> Bool {
        return value >= level.value
    }

    var sentryLevel: SentryLevel {
        switch self {
        case .debug:
            return SentryLevel.debug
        case .info:
            return SentryLevel.info
        case .warning:
            return SentryLevel.error
        case .fatal:
            return SentryLevel.fatal
        }
    }
}
