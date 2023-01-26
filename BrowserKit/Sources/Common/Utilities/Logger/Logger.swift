// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol Logger {
    func verbose(message: String,
                 category: LoggerCategory,
                 file: String,
                 function: String,
                 line: Int)

    func debug(message: String,
               category: LoggerCategory,
               file: String,
               function: String,
               line: Int)

    func info(message: String,
              category: LoggerCategory,
              file: String,
              function: String,
              line: Int)

    func warning(message: String,
                 category: LoggerCategory,
                 file: String,
                 function: String,
                 line: Int)

    func error(message: String,
               category: LoggerCategory,
               file: String,
               function: String,
               line: Int)
}

public extension Logger {
    func verbose(message: String,
                 category: LoggerCategory,
                 file: String = #file,
                 function: String = #function,
                 line: Int = #line) {
        self.verbose(message: message, category: category, file: file, function: function, line: line)
    }

    func debug(message: String,
               category: LoggerCategory,
               file: String = #file,
               function: String = #function,
               line: Int = #line) {
        self.debug(message: message, category: category, file: file, function: function, line: line)
    }

    func info(message: String,
              category: LoggerCategory,
              file: String = #file,
              function: String = #function,
              line: Int = #line) {
        self.info(message: message, category: category, file: file, function: function, line: line)
    }

    func warning(message: String,
                 category: LoggerCategory,
                 file: String = #file,
                 function: String = #function,
                 line: Int = #line) {
        self.warning(message: message, category: category, file: file, function: function, line: line)
    }

    func error(message: String,
               category: LoggerCategory,
               file: String = #file,
               function: String = #function,
               line: Int = #line) {
        self.error(message: message, category: category, file: file, function: function, line: line)
    }
}
