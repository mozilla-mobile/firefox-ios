// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftyBeaver

public class DefaultLogger: Logger {
    public static let shared = DefaultLogger()
    private var log: SwiftyBeaver.Type!

    private init() {
        self.setupLogger()
    }

    public func verbose(message: String,
                        category: LoggerCategory,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line) {
        log.verbose(message,
                    file,
                    function,
                    line: line,
                    context: category.rawValue)
    }

    public func debug(message: String,
                      category: LoggerCategory,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        log.debug(message,
                  file,
                  function,
                  line: line,
                  context: category.rawValue)
    }

    public func info(message: String,
                     category: LoggerCategory,
                     file: String = #file,
                     function: String = #function,
                     line: Int = #line) {
        log.info(message,
                 file,
                 function,
                 line: line,
                 context: category.rawValue)
    }

    public func warning(message: String,
                        category: LoggerCategory,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line) {
        log.warning(message,
                    file,
                    function,
                    line: line,
                    context: category.rawValue)
    }

    public func error(message: String,
                      category: LoggerCategory,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        log.error(message,
                  file,
                  function,
                  line: line,
                  context: category.rawValue)
    }

    // TODO: Laurie doc
    /// Filters can be added here on the console or file destination.
    ///        console.addFilter(Filters.Path.contains("BrowserViewController", minLevel: .debug))
    ///        console.addFilter(Filters.Function.contains("viewDidLoad", required: true))
    ///        console.addFilter(Filters.Path.excludes("Sync", required: true))
    ///        console.addFilter(Filters.Message.contains("HTTP", caseSensitive: true, required: true))
    private func setupLogger() {
        let console = ConsoleDestination()
        // Format has full date/time, colored log level, tag, file name and message
        console.format = "$Dyyyy-MM-dd HH:mm:ss.SSS$d $C$L$c [$X] [$N] $M"
        console.minLevel = .debug

        let file = FileDestination()
        // Format has full date/time, colored log level, tag, file name and message
        file.format = "$Dyyyy-MM-dd HH:mm:ss.SSS$d $C$L$c [$X] [$N] $M"
        file.minLevel = .info

        let log = SwiftyBeaver.self
        log.addDestination(console)
        log.addDestination(file)
        self.log = log
    }
}
