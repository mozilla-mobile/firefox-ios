// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftyBeaver

// MARK: - SwiftyBeaverWrapper
protocol SwiftyBeaverWrapper {
    static func debug(_ message: @autoclosure () -> Any,
                      file: String,
                      function: String,
                      line: Int,
                      context: Any?)

    static func info(_ message: @autoclosure () -> Any,
                     file: String,
                     function: String,
                     line: Int,
                     context: Any?)

    static func warning(_ message: @autoclosure () -> Any,
                        file: String,
                        function: String,
                        line: Int,
                        context: Any?)

    static func error(_ message: @autoclosure () -> Any,
                      file: String,
                      function: String,
                      line: Int,
                      context: Any?)
}

extension SwiftyBeaver: SwiftyBeaverWrapper {}

// MARK: - SwiftyBeaverBuilder
protocol SwiftyBeaverBuilder {
    func setup(with destination: URL?) -> SwiftyBeaverWrapper.Type
}

struct DefaultSwiftyBeaverBuilder: SwiftyBeaverBuilder {
    // Format has full date/time, colored log level, tag, file name and message
    // https://docs.swiftybeaver.com/article/20-custom-format
    private let defaultFormat = "$Dyyyy-MM-dd HH:mm:ss.SSS$d $C$L$c [$X] $N - $M"

    /// Setup SwiftyBeaver as our basic logger for console and file destination.
    ///
    /// Note that filters can be added here on the different destinations like the following:
    ///     `console.addFilter(Filters.Path.contains("BrowserViewController", minLevel: .debug))`
    ///     `console.addFilter(Filters.Function.contains("viewDidLoad", required: true))`
    ///     `console.addFilter(Filters.Path.excludes("Sync", required: true))`
    ///     `console.addFilter(Filters.Message.contains("HTTP", caseSensitive: true, required: true))`
    func setup(with destination: URL?) -> SwiftyBeaverWrapper.Type {
        let console = ConsoleDestination()
        console.format = defaultFormat
        console.minLevel = .info
        console.levelString.error = "FATAL"

        let file = FileDestination(logFileURL: destination)
        file.format = defaultFormat
        file.minLevel = .debug
        file.levelString.error = "FATAL"
        file.logFileAmount = 2

        let logger = SwiftyBeaver.self
        logger.removeAllDestinations()
        logger.addDestination(console)
        logger.addDestination(file)

        return logger
    }
}
