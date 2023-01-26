// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol Logger {
    /// The TRACE log level captures all the details about the behavior of the application. It is mostly diagnostic and is more granular and finer than DEBUG
    /// log level. This log level is used in situations where you need to see what happened in your application or what happened in the third-party libraries used.
    /// You can use the TRACE log level to query parameters in the code or interpret the algorithm’s steps.
    func verbose(_ message: String,
                 category: LoggerCategory,
                 sendToSentry: Bool,
                 file: String,
                 function: String,
                 line: Int)

    /// With DEBUG, you are giving diagnostic information in a detailed manner. It is verbose and has more information than you would need when using the
    /// application. DEBUG logging level is used to fetch information needed to diagnose, troubleshoot, or test an application. This ensures a smooth
    /// running application.
    func debug(_ message: String,
               category: LoggerCategory,
               sendToSentry: Bool,
               file: String,
               function: String,
               line: Int)

    /// INFO messages are like the normal behavior of applications. They state what happened. For example, if a particular service stopped or started or you
    /// added something to the database. These entries are nothing to worry about during usual operations. The information logged using the INFO log is
    /// usually informative, and it does not necessarily require you to follow up on it.
    func info(_ message: String,
              category: LoggerCategory,
              sendToSentry: Bool,
              file: String,
              function: String,
              line: Int)

    /// The WARNING log level is used when you have detected an unexpected application problem. This means you are not quite sure whether the problem
    /// will recur or remain. You may not notice any harm to your application at this point. This issue is usually a situation that stops specific processes from
    /// running. Yet it does not mean that the application has been harmed. In fact, the code should continue to work as usual. You should eventually check
    /// these warnings just in case the problem reoccurs.
    func warning(_ message: String,
                 category: LoggerCategory,
                 sendToSentry: Bool,
                 file: String,
                 function: String,
                 line: Int)

    /// Unlike the FATAL logging level, error does not mean your application is aborting. Instead, there is just an inability to access a service or a file.
    /// This ERROR shows a failure of something important in your application. This log level is used when a severe issue is stopping functions within the
    /// application from operating efficiently. Most of the time, the application will continue to run, but eventually, it will need to be addressed.
    func error(_ message: String,
               category: LoggerCategory,
               sendToSentry: Bool,
               file: String,
               function: String,
               line: Int)

    /// FATAL means that the application is about to stop a serious problem or corruption from happening. The FATAL level of logging shows that the
    /// application’s situation is catastrophic, such that an important function is not working. For example, you can use FATAL log level if the application is
    /// unable to connect to the data store.
    func fatal(_ message: String,
               category: LoggerCategory,
               sendToSentry: Bool,
               file: String,
               function: String,
               line: Int)
}

public extension Logger {
    func verbose(_ message: String,
                 category: LoggerCategory,
                 sendToSentry: Bool = false,
                 file: String = #file,
                 function: String = #function,
                 line: Int = #line) {
        self.verbose(message, category: category, sendToSentry: sendToSentry, file: file, function: function, line: line)
    }

    func debug(_ message: String,
               category: LoggerCategory,
               sendToSentry: Bool = false,
               file: String = #file,
               function: String = #function,
               line: Int = #line) {
        self.debug(message, category: category, sendToSentry: sendToSentry, file: file, function: function, line: line)
    }

    func info(_ message: String,
              category: LoggerCategory,
              sendToSentry: Bool = false,
              file: String = #file,
              function: String = #function,
              line: Int = #line) {
        self.info(message, category: category, sendToSentry: sendToSentry, file: file, function: function, line: line)
    }

    func warning(_ message: String,
                 category: LoggerCategory,
                 sendToSentry: Bool = false,
                 file: String = #file,
                 function: String = #function,
                 line: Int = #line) {
        self.warning(message, category: category, sendToSentry: sendToSentry, file: file, function: function, line: line)
    }

    func error(_ message: String,
               category: LoggerCategory,
               sendToSentry: Bool = false,
               file: String = #file,
               function: String = #function,
               line: Int = #line) {
        self.error(message, category: category, sendToSentry: sendToSentry, file: file, function: function, line: line)
    }

    func fatal(_ message: String,
               category: LoggerCategory,
               sendToSentry: Bool = false,
               file: String = #file,
               function: String = #function,
               line: Int = #line) {
        self.fatal(message, category: category, sendToSentry: sendToSentry, file: file, function: function, line: line)
    }
}
