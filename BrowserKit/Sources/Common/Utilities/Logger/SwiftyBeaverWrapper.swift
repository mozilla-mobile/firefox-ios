// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftyBeaver

protocol SwiftyBeaverWrapper {
    static func verbose(_ message: @autoclosure () -> Any,
                        _ file: String,
                        _ function: String,
                        line: Int,
                        context: Any?)

    static func debug(_ message: @autoclosure () -> Any,
                      _ file: String,
                      _ function: String,
                      line: Int,
                      context: Any?)

    static func info(_ message: @autoclosure () -> Any,
                     _ file: String,
                     _ function: String,
                     line: Int,
                     context: Any?)

    static func warning(_ message: @autoclosure () -> Any,
                        _ file: String,
                        _ function: String,
                        line: Int,
                        context: Any?)

    static func error(_ message: @autoclosure () -> Any,
                      _ file: String,
                      _ function: String,
                      line: Int,
                      context: Any?)

    static func logFileDirectoryPath(inDocuments: Bool) -> String?
    static var fileDestination: URL? { get }
}

extension SwiftyBeaver: SwiftyBeaverWrapper {
    static func logFileDirectoryPath(inDocuments: Bool) -> String? {
        let searchPathDirectory: FileManager.SearchPathDirectory = inDocuments ? .documentDirectory : .cachesDirectory
        guard let targetDirectory = NSSearchPathForDirectoriesInDomains(searchPathDirectory,
                                                                        .userDomainMask,
                                                                        true).first
        else { return nil }

        let logsDirectory = "\(targetDirectory)/Logs"
        if !FileManager.default.fileExists(atPath: logsDirectory) {
            try? FileManager.default.createDirectory(atPath: logsDirectory,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
        }
        return logsDirectory
    }

    static var fileDestination: URL? {
        guard let path = SwiftyBeaver.logFileDirectoryPath(inDocuments: false) else { return nil }

        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let date = dateFormatterGet.string(from: Date())
        return URL(fileURLWithPath: path, isDirectory: true).appendingPathComponent("Firefox-\(date).log")
    }
}

struct DefaultSwiftyBeaver {
    /// Setup SwiftyBeaver as our basic logger for console and file destination.
    ///
    /// Note that filters can be added here on the different destinations like the following:
    ///     `console.addFilter(Filters.Path.contains("BrowserViewController", minLevel: .debug))`
    ///     `console.addFilter(Filters.Function.contains("viewDidLoad", required: true))`
    ///     `console.addFilter(Filters.Path.excludes("Sync", required: true))`
    ///     `console.addFilter(Filters.Message.contains("HTTP", caseSensitive: true, required: true))`
    static let implementation: SwiftyBeaverWrapper.Type = {
        let console = ConsoleDestination()
        // Format has full date/time, colored log level, tag, file name and message
        console.format = "$Dyyyy-MM-dd HH:mm:ss.SSS$d $C$L$c [$X] $N - $M"
        console.minLevel = .debug

        let file = FileDestination(logFileURL: SwiftyBeaver.fileDestination)
        // Format has full date/time, colored log level, tag, file name and message
        file.format = "$Dyyyy-MM-dd HH:mm:ss.SSS$d $C$L$c [$X] $N - $M"
        file.minLevel = .info

        let logger = SwiftyBeaver.self
        logger.removeAllDestinations()
        logger.addDestination(console)
        logger.addDestination(file)

        return logger
    }()
}
