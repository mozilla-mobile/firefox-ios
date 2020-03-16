//
//  XCGLogger.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright © 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

#if os(macOS)
    import AppKit
#elseif os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#endif

// MARK: - XCGLogger
/// The main logging class
open class XCGLogger: CustomDebugStringConvertible {
    // MARK: - Constants
    public struct Constants {
        /// Prefix identifier to use for all other identifiers
        public static let baseIdentifier = "com.cerebralgardens.xcglogger"

        /// Identifier for the default instance of XCGLogger
        public static let defaultInstanceIdentifier = "\(baseIdentifier).defaultInstance"

        /// Identifer for the Xcode console destination
        public static let baseConsoleDestinationIdentifier = "\(baseIdentifier).logdestination.console"

        /// Identifier for the Apple System Log destination
        public static let systemLogDestinationIdentifier = "\(baseIdentifier).logdestination.console.nslog"

        /// Identifier for the file logging destination
        public static let fileDestinationIdentifier = "\(baseIdentifier).logdestination.file"

        /// Identifier for the default dispatch queue
        public static let logQueueIdentifier = "\(baseIdentifier).queue"

        /// UserInfo Key - tags
        public static let userInfoKeyTags = "\(baseIdentifier).tags"

        /// UserInfo Key - devs
        public static let userInfoKeyDevs = "\(baseIdentifier).devs"

        /// UserInfo Key - internal
        public static let userInfoKeyInternal = "\(baseIdentifier).internal"

        /// Library version number
        public static let versionString = "7.0.0"

        /// Internal userInfo
        internal static let internalUserInfo: [String: Any] = [XCGLogger.Constants.userInfoKeyInternal: true]

        /// Extended file attributed key to use when storing the logger's identifier on an archived log file
        public static let extendedAttributeArchivedLogIdentifierKey = "\(baseIdentifier).archived.by"

        /// Extended file attributed key to use when storing the time a log file was archived
        public static let extendedAttributeArchivedLogTimestampKey = "\(baseIdentifier).archived.at"
    }

    // MARK: - Enums
    /// Enum defining our log levels
    public enum Level: Int, CaseIterable, Comparable, CustomStringConvertible {
        case verbose
        case debug
        case info
        case notice
        case warning
        case error
        case severe // aka critical
        case alert
        case emergency
        case none

        public var description: String {
            switch self {
            case .verbose:
                return "Verbose"
            case .debug:
                return "Debug"
            case .info:
                return "Info"
            case .notice:
                return "Notice"
            case .warning:
                return "Warning"
            case .error:
                return "Error"
            case .severe:
                return "Severe"
            case .alert:
                return "Alert"
            case .emergency:
                return "Emergency"
            case .none:
                return "None"
            }
        }

        @available(*, deprecated, renamed: "allCases")
        public static let all: [Level] = [.verbose, .debug, .info, .notice, .warning, .error, .severe, .alert, .emergency]
    }

    // MARK: - Default instance
    /// The default XCGLogger object
    public static let `default`: XCGLogger = XCGLogger(identifier: XCGLogger.Constants.defaultInstanceIdentifier)

    // MARK: - Properties
    /// Identifier for this logger object (should be unique)
    open var identifier: String = ""

    /// The log level of this logger, any logs received at this level or higher will be output to the destinations
    open var outputLevel: Level = .debug {
        didSet {
            for index in 0 ..< destinations.count {
                destinations[index].outputLevel = outputLevel
            }
        }
    }

    /// Option: a closure to execute whenever a logging method is called without a log message
    open var noMessageClosure: () -> Any? = { return "" }

    /// Option: override descriptions of log levels
    open var levelDescriptions: [XCGLogger.Level: String] = [:]

    /// Array of log formatters to apply to messages before they're output
    open var formatters: [LogFormatterProtocol]? = nil

    /// Array of log filters to apply to messages before they're output
    open var filters: [FilterProtocol]? = nil

    /// The default dispatch queue used for logging
    public static let logQueue: DispatchQueue = DispatchQueue(label: XCGLogger.Constants.logQueueIdentifier, attributes: [])

    /// A custom date formatter object to use when displaying the dates of log messages (internal storage)
    internal var _customDateFormatter: DateFormatter? = nil
    /// The date formatter object to use when displaying the dates of log messages
    open var dateFormatter: DateFormatter? {
        get {
            guard _customDateFormatter == nil else { return _customDateFormatter }
            struct Statics {
                static var dateFormatter: DateFormatter = {
                    let defaultDateFormatter = DateFormatter()
                    defaultDateFormatter.locale = NSLocale.current
                    defaultDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
                    return defaultDateFormatter
                }()
            }

            return Statics.dateFormatter
        }
        set {
            _customDateFormatter = newValue
        }
    }

    /// Array containing all of the destinations for this logger
    open var destinations: [DestinationProtocol] = []

    // MARK: - Life Cycle
    public init(identifier: String = "", includeDefaultDestinations: Bool = true) {
        self.identifier = identifier

        if includeDefaultDestinations {
            // Setup a standard console destination
            add(destination: ConsoleDestination(identifier: XCGLogger.Constants.baseConsoleDestinationIdentifier))
        }
    }

    // MARK: - Setup methods
    /// A shortcut method to configure the default logger instance.
    ///
    /// - Note: The function exists to get you up and running quickly, but it's recommended that you use the advanced usage configuration for most projects. See https://github.com/DaveWoodCom/XCGLogger/blob/master/README.md#advanced-usage-recommended
    ///
    /// - Parameters:
    ///     - level: The log level of this logger, any logs received at this level or higher will be output to the destinations. **Default:** Debug
    ///     - showLogIdentifier: Whether or not to output the log identifier. **Default:** false
    ///     - showFunctionName: Whether or not to output the function name that generated the log. **Default:** true
    ///     - showThreadName: Whether or not to output the thread's name the log was created on. **Default:** false
    ///     - showLevel: Whether or not to output the log level of the log. **Default:** true
    ///     - showFileNames: Whether or not to output the fileName that generated the log. **Default:** true
    ///     - showLineNumbers: Whether or not to output the line number where the log was generated. **Default:** true
    ///     - showDate: Whether or not to output the date the log was created. **Default:** true
    ///     - writeToFile: FileURL or path (as String) to a file to log all messages to (this file is overwritten each time the logger is created). **Default:** nil => no log file
    ///     - fileLevel: An alternate log level for the file destination. **Default:** nil => use the same log level as the console destination
    ///
    /// - Returns:  Nothing
    ///
    open class func setup(level: Level = .debug, showLogIdentifier: Bool = false, showFunctionName: Bool = true, showThreadName: Bool = false, showLevel: Bool = true, showFileNames: Bool = true, showLineNumbers: Bool = true, showDate: Bool = true, writeToFile: Any? = nil, fileLevel: Level? = nil) {
        self.default.setup(level: level, showLogIdentifier: showLogIdentifier, showFunctionName: showFunctionName, showThreadName: showThreadName, showLevel: showLevel, showFileNames: showFileNames, showLineNumbers: showLineNumbers, showDate: showDate, writeToFile: writeToFile)
    }

    /// A shortcut method to configure the logger.
    ///
    /// - Note: The function exists to get you up and running quickly, but it's recommended that you use the advanced usage configuration for most projects. See https://github.com/DaveWoodCom/XCGLogger/blob/master/README.md#advanced-usage-recommended
    ///
    /// - Parameters:
    ///     - level: The log level of this logger, any logs received at this level or higher will be output to the destinations. **Default:** Debug
    ///     - showLogIdentifier: Whether or not to output the log identifier. **Default:** false
    ///     - showFunctionName: Whether or not to output the function name that generated the log. **Default:** true
    ///     - showThreadName: Whether or not to output the thread's name the log was created on. **Default:** false
    ///     - showLevel: Whether or not to output the log level of the log. **Default:** true
    ///     - showFileNames: Whether or not to output the fileName that generated the log. **Default:** true
    ///     - showLineNumbers: Whether or not to output the line number where the log was generated. **Default:** true
    ///     - showDate: Whether or not to output the date the log was created. **Default:** true
    ///     - writeToFile: FileURL or path (as String) to a file to log all messages to (this file is overwritten each time the logger is created). **Default:** nil => no log file
    ///     - fileLevel: An alternate log level for the file destination. **Default:** nil => use the same log level as the console destination
    ///
    /// - Returns:  Nothing
    ///
    open func setup(level: Level = .debug, showLogIdentifier: Bool = false, showFunctionName: Bool = true, showThreadName: Bool = false, showLevel: Bool = true, showFileNames: Bool = true, showLineNumbers: Bool = true, showDate: Bool = true, writeToFile: Any? = nil, fileLevel: Level? = nil) {
        outputLevel = level

        if let standardConsoleDestination = destination(withIdentifier: XCGLogger.Constants.baseConsoleDestinationIdentifier) as? ConsoleDestination {
            standardConsoleDestination.showLogIdentifier = showLogIdentifier
            standardConsoleDestination.showFunctionName = showFunctionName
            standardConsoleDestination.showThreadName = showThreadName
            standardConsoleDestination.showLevel = showLevel
            standardConsoleDestination.showFileName = showFileNames
            standardConsoleDestination.showLineNumber = showLineNumbers
            standardConsoleDestination.showDate = showDate
            standardConsoleDestination.outputLevel = level
        }

        if let writeToFile: Any = writeToFile {
            // We've been passed a file to use for logging, set up a file logger
            let standardFileDestination: FileDestination = FileDestination(writeToFile: writeToFile, identifier: XCGLogger.Constants.fileDestinationIdentifier)

            standardFileDestination.showLogIdentifier = showLogIdentifier
            standardFileDestination.showFunctionName = showFunctionName
            standardFileDestination.showThreadName = showThreadName
            standardFileDestination.showLevel = showLevel
            standardFileDestination.showFileName = showFileNames
            standardFileDestination.showLineNumber = showLineNumbers
            standardFileDestination.showDate = showDate
            standardFileDestination.outputLevel = fileLevel ?? level

            add(destination: standardFileDestination)
        }

        logAppDetails()
    }

    // MARK: - Logging methods
    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - level:        Specified log level **Default:** *Debug*.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing
    ///
    open class func logln(_ closure: @autoclosure () -> Any?, level: Level = .debug, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.default.logln(level, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - level:        Specified log level **Default:** *Debug*.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing
    ///
    open class func logln(_ level: Level = .debug, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:], closure: () -> Any?) {
        self.default.logln(level, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - level:        Specified log level **Default:** *Debug*.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing
    ///
    open class func logln(_ level: Level = .debug, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:], closure: () -> Any?) {
        self.default.logln(level, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - level:        Specified log level **Default:** *Debug*.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing
    ///
    open func logln(_ closure: @autoclosure () -> Any?, level: Level = .debug, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.logln(level, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - level:        Specified log level **Default:** *Debug*.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing
    ///
    open func logln(_ level: Level = .debug, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:], closure: () -> Any?) {
        logln(level, functionName: String(describing: functionName), fileName: String(describing: fileName), lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - level:        Specified log level **Default:** *Debug*.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing
    ///
    open func logln(_ level: Level = .debug, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:], closure: () -> Any?) {
        let enabledDestinations = destinations.filter({$0.isEnabledFor(level: level)})
        guard enabledDestinations.count > 0 else { return }
        guard let closureResult = closure() else { return }

        let logDetails: LogDetails = LogDetails(level: level, date: Date(), message: String(describing: closureResult), functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo)
        for destination in enabledDestinations {
            destination.process(logDetails: logDetails)
        }
    }

    /// Execute some code only when at the specified log level.
    ///
    /// - Parameters:
    ///     - level:    Specified log level **Default:** *Debug*.
    ///     - closure:  The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func exec(_ level: Level = .debug, closure: () -> () = {}) {
        self.default.exec(level, closure: closure)
    }

    /// Execute some code only when at the specified log level.
    ///
    /// - Parameters:
    ///     - level:     Specified log level **Default:** *Debug*.
    ///     - closure:   The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func exec(_ level: Level = .debug, closure: () -> () = {}) {
        guard isEnabledFor(level:level) else { return }

        closure()
    }

    /// Generate logs to display your app's vitals (app name, version, etc) as well as XCGLogger's version and log level.
    ///
    /// - Parameters:
    ///     - selectedDestination:     A specific destination to log the vitals on, if omitted, will log to all destinations
    ///
    /// - Returns:  Nothing.
    ///
    open func logAppDetails(selectedDestination: DestinationProtocol? = nil) {
        let date = Date()

        var buildString = ""
        if let infoDictionary = Bundle.main.infoDictionary {
            if let CFBundleShortVersionString = infoDictionary["CFBundleShortVersionString"] as? String {
                buildString = "Version: \(CFBundleShortVersionString) "
            }
            if let CFBundleVersion = infoDictionary["CFBundleVersion"] as? String {
                buildString += "Build: \(CFBundleVersion) "
            }
        }

        let processInfo: ProcessInfo = ProcessInfo.processInfo
        let XCGLoggerVersionNumber = XCGLogger.Constants.versionString

        var logDetails: [LogDetails] = []
        logDetails.append(LogDetails(level: .info, date: date, message: "\(processInfo.processName) \(buildString)PID: \(processInfo.processIdentifier)", functionName: "", fileName: "", lineNumber: 0, userInfo: XCGLogger.Constants.internalUserInfo))
        logDetails.append(LogDetails(level: .info, date: date, message: "XCGLogger Version: \(XCGLoggerVersionNumber) - Level: \(outputLevel)", functionName: "", fileName: "", lineNumber: 0, userInfo: XCGLogger.Constants.internalUserInfo))

        for var destination in (selectedDestination != nil ? [selectedDestination!] : destinations) where !destination.haveLoggedAppDetails {
            for logDetail in logDetails {
                guard destination.isEnabledFor(level:.info) else { continue }

                destination.haveLoggedAppDetails = true
                destination.processInternal(logDetails: logDetail)
            }
        }
    }

    // MARK: - Convenience logging methods
    // MARK: * Verbose
    /// Log something at the Verbose log level. This format of verbose() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open class func verbose(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.default.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: self.default.noMessageClosure)
    }

    /// Log something at the Verbose log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open class func verbose(_ closure: @autoclosure () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.default.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log something at the Verbose log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open class func verbose(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:], closure: () -> Any?) {
        self.default.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log something at the Verbose log level. This format of verbose() isn't provided the object to log, instead the property *`noMessageClosure`* is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open func verbose(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: self.noMessageClosure)
    }

    /// Log something at the Verbose log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open func verbose(_ closure: @autoclosure () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log something at the Verbose log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open func verbose(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:], closure: () -> Any?) {
        self.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    // MARK: * Debug
    /// Log something at the Debug log level. This format of debug() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open class func debug(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.default.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: self.default.noMessageClosure)
    }

    /// Log something at the Debug log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open class func debug(_ closure: @autoclosure () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.default.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log something at the Debug log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open class func debug(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:], closure: () -> Any?) {
        self.default.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log something at the Debug log level. This format of debug() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open func debug(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: self.noMessageClosure)
    }

    /// Log something at the Debug log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open func debug(_ closure: @autoclosure () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log something at the Debug log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open func debug(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:], closure: () -> Any?) {
        self.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    // MARK: * Info
    /// Log something at the Info log level. This format of info() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open class func info(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.default.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: self.default.noMessageClosure)
    }

    /// Log something at the Info log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open class func info(_ closure: @autoclosure () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.default.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log something at the Info log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open class func info(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:], closure: () -> Any?) {
        self.default.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log something at the Info log level. This format of info() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open func info(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: self.noMessageClosure)
    }

    /// Log something at the Info log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open func info(_ closure: @autoclosure () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log something at the Info log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open func info(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:], closure: () -> Any?) {
        self.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    // MARK: * Warning
    /// Log something at the Warning log level. This format of warning() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open class func warning(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.default.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: self.default.noMessageClosure)
    }

    /// Log something at the Warning log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open class func warning(_ closure: @autoclosure () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.default.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log something at the Warning log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open class func warning(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:], closure: () -> Any?) {
        self.default.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log something at the Warning log level. This format of warning() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open func warning(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: self.noMessageClosure)
    }

    /// Log something at the Warning log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open func warning(_ closure: @autoclosure () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log something at the Warning log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open func warning(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:], closure: () -> Any?) {
        self.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    // MARK: * Error
    /// Log something at the Error log level. This format of error() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open class func error(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.default.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: self.default.noMessageClosure)
    }

    /// Log something at the Error log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open class func error(_ closure: @autoclosure () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.default.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log something at the Error log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open class func error(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:], closure: () -> Any?) {
        self.default.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log something at the Error log level. This format of error() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open func error(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: self.noMessageClosure)
    }

    /// Log something at the Error log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open func error(_ closure: @autoclosure () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log something at the Error log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open func error(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:], closure: () -> Any?) {
        self.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    // MARK: * Severe
    /// Log something at the Severe log level. This format of severe() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open class func severe(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.default.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: self.default.noMessageClosure)
    }

    /// Log something at the Severe log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open class func severe(_ closure: @autoclosure () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.default.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log something at the Severe log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open class func severe(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:], closure: () -> Any?) {
        self.default.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log something at the Severe log level. This format of severe() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open func severe(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: self.noMessageClosure)
    }

    /// Log something at the Severe log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///
    /// - Returns:  Nothing.
    ///
    open func severe(_ closure: @autoclosure () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    /// Log something at the Severe log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - userInfo:     Dictionary for adding arbitrary data to the log message, can be used by filters/formatters etc
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open func severe(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:], closure: () -> Any?) {
        self.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

    // MARK: - Exec Methods
    // MARK: * Verbose
    /// Execute some code only when at the Verbose log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func verboseExec(_ closure: () -> () = {}) {
        self.default.exec(XCGLogger.Level.verbose, closure: closure)
    }

    /// Execute some code only when at the Verbose log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func verboseExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.Level.verbose, closure: closure)
    }

    // MARK: * Debug
    /// Execute some code only when at the Debug or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func debugExec(_ closure: () -> () = {}) {
        self.default.exec(XCGLogger.Level.debug, closure: closure)
    }

    /// Execute some code only when at the Debug or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func debugExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.Level.debug, closure: closure)
    }

    // MARK: * Info
    /// Execute some code only when at the Info or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func infoExec(_ closure: () -> () = {}) {
        self.default.exec(XCGLogger.Level.info, closure: closure)
    }

    /// Execute some code only when at the Info or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func infoExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.Level.info, closure: closure)
    }

    // MARK: * Warning
    /// Execute some code only when at the Warning or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func warningExec(_ closure: () -> () = {}) {
        self.default.exec(XCGLogger.Level.warning, closure: closure)
    }

    /// Execute some code only when at the Warning or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func warningExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.Level.warning, closure: closure)
    }

    // MARK: * Error
    /// Execute some code only when at the Error or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func errorExec(_ closure: () -> () = {}) {
        self.default.exec(XCGLogger.Level.error, closure: closure)
    }

    /// Execute some code only when at the Error or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func errorExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.Level.error, closure: closure)
    }

    // MARK: * Severe
    /// Execute some code only when at the Severe log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func severeExec(_ closure: () -> () = {}) {
        self.default.exec(XCGLogger.Level.severe, closure: closure)
    }

    /// Execute some code only when at the Severe log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func severeExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.Level.severe, closure: closure)
    }

    // MARK: - Log destination methods
    /// Get the destination with the specified identifier.
    ///
    /// - Parameters:
    ///     - identifier:   Identifier of the destination to return.
    ///
    /// - Returns:  The destination with the specified identifier, if one exists, nil otherwise.
    /// 
    open func destination(withIdentifier identifier: String) -> DestinationProtocol? {
        for destination in destinations {
            if destination.identifier == identifier {
                return destination
            }
        }

        return nil
    }

    /// Add a new destination to the logger.
    ///
    /// - Parameters:
    ///     - destination:   The destination to add.
    ///
    /// - Returns:
    ///     - true:     Log destination was added successfully.
    ///     - false:    Failed to add the destination.
    ///
    @discardableResult open func add(destination: DestinationProtocol) -> Bool {
        var destination = destination

        let existingDestination: DestinationProtocol? = self.destination(withIdentifier: destination.identifier)
        if existingDestination != nil {
            return false
        }

        if let previousOwner = destination.owner {
            previousOwner.remove(destination: destination)
        }

        destination.owner = self
        destinations.append(destination)
        return true
    }

    /// Remove the destination from the logger.
    ///
    /// - Parameters:
    ///     - destination:   The destination to remove.
    ///
    /// - Returns:
    ///     - true:     Log destination was removed successfully.
    ///     - false:    Failed to remove the destination.
    ///
    @discardableResult open func remove(destination: DestinationProtocol) -> Bool {
        guard destination.owner === self else { return false }

        let existingDestination: DestinationProtocol? = self.destination(withIdentifier: destination.identifier)
        guard existingDestination != nil else { return false }

        // Make our parameter mutable
        var destination = destination
        destination.owner = nil

        destinations = destinations.filter({$0.owner != nil})
        return true
    }

    /// Remove the destination with the specified identifier from the logger.
    ///
    /// - Parameters:
    ///     - identifier:   The identifier of the destination to remove.
    ///
    /// - Returns:
    ///     - true:     Log destination was removed successfully.
    ///     - false:    Failed to remove the destination.
    ///
    @discardableResult open func remove(destinationWithIdentifier identifier: String) -> Bool {
        guard let destination = destination(withIdentifier: identifier) else { return false }
        return remove(destination: destination)
    }

    // MARK: - Misc methods
    /// Check if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - level: The log level to check.
    ///
    /// - Returns:
    ///     - true:     Logger is at the log level specified or lower.
    ///     - false:    Logger is at a higher log levelss.
    ///
    open func isEnabledFor(level: XCGLogger.Level) -> Bool {
        return level >= self.outputLevel
    }

    // MARK: - Private methods
    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - message:   Message to log.
    ///     - level:     Specified log level.
    ///     - source:    The destination calling this method
    ///
    /// - Returns:  Nothing
    ///
    internal func _logln(_ message: String, level: Level = .debug, source sourceDestination: DestinationProtocol? = nil) {
        let logDetails: LogDetails = LogDetails(level: level, date: Date(), message: message, functionName: "", fileName: "", lineNumber: 0, userInfo: XCGLogger.Constants.internalUserInfo)
        for destination in self.destinations {
            if level >= .error && sourceDestination?.identifier == destination.identifier { continue }
            if (destination.isEnabledFor(level: level)) {
                destination.processInternal(logDetails: logDetails)
            }
        }
    }

    // MARK: - DebugPrintable
    open var debugDescription: String {
        get {
            var description: String = "\(extractTypeName(self)): \(identifier) - destinations: \r"
            for destination in destinations {
                description += "\t \(destination.debugDescription)\r"
            }

            return description
        }
    }
}

// Implement Comparable for XCGLogger.Level
public func < (lhs: XCGLogger.Level, rhs: XCGLogger.Level) -> Bool {
    return lhs.rawValue < rhs.rawValue
}
