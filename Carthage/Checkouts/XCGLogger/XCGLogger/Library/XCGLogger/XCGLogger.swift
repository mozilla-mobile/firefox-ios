//
//  XCGLogger.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright (c) 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import Foundation
import SwiftTryCatch
#if os(OSX)
    import AppKit
#elseif os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#endif

// MARK: - XCGLogDetails
// - Data structure to hold all info about a log message, passed to log destination classes
public struct XCGLogDetails {
    public var logLevel: XCGLogger.LogLevel
    public var date: NSDate
    public var logMessage: String
    public var functionName: String
    public var fileName: String
    public var lineNumber: Int

    public init(logLevel: XCGLogger.LogLevel, date: NSDate, logMessage: String, functionName: String, fileName: String, lineNumber: Int) {
        self.logLevel = logLevel
        self.date = date
        self.logMessage = logMessage
        self.functionName = functionName
        self.fileName = fileName
        self.lineNumber = lineNumber
    }
}

// MARK: - XCGLogDestinationProtocol
// - Protocol for output classes to conform to
public protocol XCGLogDestinationProtocol: CustomDebugStringConvertible {
    var owner: XCGLogger {get set}
    var identifier: String {get set}
    var outputLogLevel: XCGLogger.LogLevel {get set}

    func processLogDetails(logDetails: XCGLogDetails)
    func processInternalLogDetails(logDetails: XCGLogDetails) // Same as processLogDetails but should omit function/file/line info
    func isEnabledForLogLevel(logLevel: XCGLogger.LogLevel) -> Bool
}

// MARK: - XCGBaseLogDestination
// - A base class log destination that doesn't actually output the log anywhere and is intented to be subclassed
public class XCGBaseLogDestination: XCGLogDestinationProtocol, CustomDebugStringConvertible {
    // MARK: - Properties
    public var owner: XCGLogger
    public var identifier: String
    public var outputLogLevel: XCGLogger.LogLevel = .Debug

    public var showLogIdentifier: Bool = false
    public var showFunctionName: Bool = true
    public var showThreadName: Bool = false
    public var showFileName: Bool = true
    public var showLineNumber: Bool = true
    public var showLogLevel: Bool = true
    public var showDate: Bool = true

    // MARK: - CustomDebugStringConvertible
    public var debugDescription: String {
        get {
            return "\(extractClassName(self)): \(identifier) - LogLevel: \(outputLogLevel) showLogIdentifier: \(showLogIdentifier) showFunctionName: \(showFunctionName) showThreadName: \(showThreadName) showLogLevel: \(showLogLevel) showFileName: \(showFileName) showLineNumber: \(showLineNumber) showDate: \(showDate)"
        }
    }

    // MARK: - Life Cycle
    public init(owner: XCGLogger, identifier: String = "") {
        self.owner = owner
        self.identifier = identifier
    }

    // MARK: - Methods to Process Log Details
    public func processLogDetails(logDetails: XCGLogDetails) {
        var extendedDetails: String = ""

        if showDate {
            var formattedDate: String = logDetails.date.description
            if let dateFormatter = owner.dateFormatter {
                formattedDate = dateFormatter.stringFromDate(logDetails.date)
            }

            extendedDetails += "\(formattedDate) "
        }

        if showLogLevel {
            extendedDetails += "[\(logDetails.logLevel)] "
        }

        if showLogIdentifier {
            extendedDetails += "[\(owner.identifier)] "
        }

        if showThreadName {
            if NSThread.isMainThread() {
                extendedDetails += "[main] "
            }
            else {
                if let threadName = NSThread.currentThread().name where !threadName.isEmpty {
                    extendedDetails += "[" + threadName + "] "
                }
                else if let queueName = String(UTF8String: dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)) where !queueName.isEmpty {
                    extendedDetails += "[" + queueName + "] "
                }
                else {
                    extendedDetails += "[" + String(format:"%p", NSThread.currentThread()) + "] "
                }
            }
        }

        if showFileName {
            extendedDetails += "[" + (logDetails.fileName as NSString).lastPathComponent + (showLineNumber ? ":" + String(logDetails.lineNumber) : "") + "] "
        }
        else if showLineNumber {
            extendedDetails += "[" + String(logDetails.lineNumber) + "] "
        }

        if showFunctionName {
            extendedDetails += "\(logDetails.functionName) "
        }

        output(logDetails, text: "\(extendedDetails)> \(logDetails.logMessage)")
    }

    public func processInternalLogDetails(logDetails: XCGLogDetails) {
        var extendedDetails: String = ""

        if showDate {
            var formattedDate: String = logDetails.date.description
            if let dateFormatter = owner.dateFormatter {
                formattedDate = dateFormatter.stringFromDate(logDetails.date)
            }

            extendedDetails += "\(formattedDate) "
        }

        if showLogLevel {
            extendedDetails += "[\(logDetails.logLevel)] "
        }

        if showLogIdentifier {
            extendedDetails += "[\(owner.identifier)] "
        }

        output(logDetails, text: "\(extendedDetails)> \(logDetails.logMessage)")
    }

    // MARK: - Misc methods
    public func isEnabledForLogLevel (logLevel: XCGLogger.LogLevel) -> Bool {
        return logLevel >= self.outputLogLevel
    }

    // MARK: - Methods that must be overriden in subclasses
    public func output(logDetails: XCGLogDetails, text: String) {
        // Do something with the text in an overridden version of this method
        precondition(false, "Must override this")
    }
}

// MARK: - XCGConsoleLogDestination
// - A standard log destination that outputs log details to the console
public class XCGConsoleLogDestination: XCGBaseLogDestination {
    // MARK: - Properties
    public var logQueue: dispatch_queue_t? = nil
    public var xcodeColors: [XCGLogger.LogLevel: XCGLogger.XcodeColor]? = nil

    // MARK: - Misc Methods
    public override func output(logDetails: XCGLogDetails, text: String) {

        let outputClosure = {
            let adjustedText: String
            if let xcodeColor = (self.xcodeColors ?? self.owner.xcodeColors)[logDetails.logLevel] where self.owner.xcodeColorsEnabled {
                adjustedText = "\(xcodeColor.format())\(text)\(XCGLogger.XcodeColor.reset)"
            }
            else {
                adjustedText = text
            }

            print("\(adjustedText)")
        }

        if let logQueue = logQueue {
            dispatch_async(logQueue, outputClosure)
        }
        else {
            outputClosure()
        }
    }
}

// MARK: - XCGNSLogDestination
// - A standard log destination that outputs log details to the console using NSLog instead of println
public class XCGNSLogDestination: XCGBaseLogDestination {
    // MARK: - Properties
    public var logQueue: dispatch_queue_t? = nil
    public var xcodeColors: [XCGLogger.LogLevel: XCGLogger.XcodeColor]? = nil

    public override var showDate: Bool {
        get {
            return false
        }
        set {
            // ignored, NSLog adds the date, so we always want showDate to be false in this subclass
        }
    }

    // MARK: - Misc Methods
    public override func output(logDetails: XCGLogDetails, text: String) {

        let outputClosure = {
            let adjustedText: String
            if let xcodeColor = (self.xcodeColors ?? self.owner.xcodeColors)[logDetails.logLevel] where self.owner.xcodeColorsEnabled {
                adjustedText = "\(xcodeColor.format())\(text)\(XCGLogger.XcodeColor.reset)"
            }
            else {
                adjustedText = text
            }

            NSLog("%@", adjustedText)
        }

        if let logQueue = logQueue {
            dispatch_async(logQueue, outputClosure)
        }
        else {
            outputClosure()
        }
    }
}

// MARK: - XCGFileLogDestination
// - A standard log destination that outputs log details to a file
public class XCGFileLogDestination: XCGBaseLogDestination {
    // MARK: - Properties
    public var logQueue: dispatch_queue_t? = nil
    private var writeToFileURL: NSURL? = nil {
        didSet {
            openFile()
        }
    }
    private var logFileHandle: NSFileHandle? = nil

    // MARK: - Life Cycle
    public init(owner: XCGLogger, writeToFile: AnyObject, identifier: String = "") {
        super.init(owner: owner, identifier: identifier)

        if writeToFile is NSString {
            writeToFileURL = NSURL.fileURLWithPath(writeToFile as! String)
        }
        else if writeToFile is NSURL {
            writeToFileURL = writeToFile as? NSURL
        }
        else {
            writeToFileURL = nil
        }

        openFile()
    }

    deinit {
        // close file stream if open
        closeFile()
    }

    // MARK: - File Handling Methods
    private func openFile() {
        if logFileHandle != nil {
            closeFile()
        }

        if let writeToFileURL = writeToFileURL,
          let path = writeToFileURL.path {

            NSFileManager.defaultManager().createFileAtPath(path, contents: nil, attributes: nil)
            do {
                logFileHandle = try NSFileHandle(forWritingToURL: writeToFileURL)
            }
            catch let error as NSError {
                owner._logln("Attempt to open log file for writing failed: \(error.localizedDescription)", logLevel: .Error)
                logFileHandle = nil
                return
            }

            owner.logAppDetails(self)

            let logDetails = XCGLogDetails(logLevel: .Info, date: NSDate(), logMessage: "XCGLogger writing to log to: \(writeToFileURL)", functionName: "", fileName: "", lineNumber: 0)
            owner._logln(logDetails.logMessage, logLevel: logDetails.logLevel)
            processInternalLogDetails(logDetails)
        }
    }

    private func closeFile() {
        logFileHandle?.closeFile()
        logFileHandle = nil
    }

    // MARK: - Misc Methods
    public override func output(logDetails: XCGLogDetails, text: String) {
        let outputClosure = {
            if let encodedData = "\(text)\n".dataUsingEncoding(NSUTF8StringEncoding) {
                SwiftTryCatch.tryBlock({
                    self.logFileHandle?.writeData(encodedData)
                }, catch: { (error) in
                    print("Attempt to write to log file failed: \(error.description)")
                }, finally: {})
            }
        }

        if let logQueue = logQueue {
            dispatch_async(logQueue, outputClosure)
        }
        else {
            outputClosure()
        }
    }
}

// MARK: - XCGLogger
// - The main logging class
public class XCGLogger: CustomDebugStringConvertible {
    // MARK: - Constants
    public struct Constants {
        public static let defaultInstanceIdentifier = "com.cerebralgardens.xcglogger.defaultInstance"
        public static let baseConsoleLogDestinationIdentifier = "com.cerebralgardens.xcglogger.logdestination.console"
        public static let nslogDestinationIdentifier = "com.cerebralgardens.xcglogger.logdestination.console.nslog"
        public static let baseFileLogDestinationIdentifier = "com.cerebralgardens.xcglogger.logdestination.file"
        public static let logQueueIdentifier = "com.cerebralgardens.xcglogger.queue"
        public static let nsdataFormatterCacheIdentifier = "com.cerebralgardens.xcglogger.nsdataFormatterCache"
        public static let versionString = "3.3"
    }
    public typealias constants = Constants // Preserve backwards compatibility: Constants should be capitalized since it's a type

    // MARK: - Enums
    public enum LogLevel: Int, Comparable, CustomStringConvertible {
        case Verbose
        case Debug
        case Info
        case Warning
        case Error
        case Severe
        case None

        public var description: String {
            switch self {
            case .Verbose:
                return "Verbose"
            case .Debug:
                return "Debug"
            case .Info:
                return "Info"
            case .Warning:
                return "Warning"
            case .Error:
                return "Error"
            case .Severe:
                return "Severe"
            case .None:
                return "None"
            }
        }
    }

    public struct XcodeColor {
        public static let escape = "\u{001b}["
        public static let resetFg = "\u{001b}[fg;"
        public static let resetBg = "\u{001b}[bg;"
        public static let reset = "\u{001b}[;"

        public var fg: (Int, Int, Int)? = nil
        public var bg: (Int, Int, Int)? = nil

        public func format() -> String {
            guard fg != nil || bg != nil else {
                // neither set, return reset value
                return XcodeColor.reset
            }

            var format: String = ""

            if let fg = fg {
                format += "\(XcodeColor.escape)fg\(fg.0),\(fg.1),\(fg.2);"
            }
            else {
                format += XcodeColor.resetFg
            }

            if let bg = bg {
                format += "\(XcodeColor.escape)bg\(bg.0),\(bg.1),\(bg.2);"
            }
            else {
                format += XcodeColor.resetBg
            }

            return format
        }

        public init(fg: (Int, Int, Int)? = nil, bg: (Int, Int, Int)? = nil) {
            self.fg = fg
            self.bg = bg
        }

#if os(OSX)
        public init(fg: NSColor, bg: NSColor? = nil) {
            if let fgColorSpaceCorrected = fg.colorUsingColorSpaceName(NSCalibratedRGBColorSpace) {
                self.fg = (Int(fgColorSpaceCorrected.redComponent * 255), Int(fgColorSpaceCorrected.greenComponent * 255), Int(fgColorSpaceCorrected.blueComponent * 255))
            }
            else {
                self.fg = nil
            }

            if let bg = bg,
                let bgColorSpaceCorrected = bg.colorUsingColorSpaceName(NSCalibratedRGBColorSpace) {

                    self.bg = (Int(bgColorSpaceCorrected.redComponent * 255), Int(bgColorSpaceCorrected.greenComponent * 255), Int(bgColorSpaceCorrected.blueComponent * 255))
            }
            else {
                self.bg = nil
            }
        }
#elseif os(iOS) || os(tvOS) || os(watchOS)
        public init(fg: UIColor, bg: UIColor? = nil) {
            var redComponent: CGFloat = 0
            var greenComponent: CGFloat = 0
            var blueComponent: CGFloat = 0
            var alphaComponent: CGFloat = 0

            fg.getRed(&redComponent, green: &greenComponent, blue: &blueComponent, alpha:&alphaComponent)
            self.fg = (Int(redComponent * 255), Int(greenComponent * 255), Int(blueComponent * 255))
            if let bg = bg {
                bg.getRed(&redComponent, green: &greenComponent, blue: &blueComponent, alpha:&alphaComponent)
                self.bg = (Int(redComponent * 255), Int(greenComponent * 255), Int(blueComponent * 255))
            }
            else {
                self.bg = nil
            }
        }
#endif

        public static let red: XcodeColor = {
            return XcodeColor(fg: (255, 0, 0))
        }()

        public static let green: XcodeColor = {
            return XcodeColor(fg: (0, 255, 0))
        }()

        public static let blue: XcodeColor = {
            return XcodeColor(fg: (0, 0, 255))
        }()

        public static let black: XcodeColor = {
            return XcodeColor(fg: (0, 0, 0))
        }()

        public static let white: XcodeColor = {
            return XcodeColor(fg: (255, 255, 255))
        }()

        public static let lightGrey: XcodeColor = {
            return XcodeColor(fg: (211, 211, 211))
        }()

        public static let darkGrey: XcodeColor = {
            return XcodeColor(fg: (169, 169, 169))
        }()

        public static let orange: XcodeColor = {
            return XcodeColor(fg: (255, 165, 0))
        }()

        public static let whiteOnRed: XcodeColor = {
            return XcodeColor(fg: (255, 255, 255), bg: (255, 0, 0))
        }()

        public static let darkGreen: XcodeColor = {
            return XcodeColor(fg: (0, 128, 0))
        }()
    }

    // MARK: - Properties (Options)
    public var identifier: String = ""
    public var outputLogLevel: LogLevel = .Debug {
        didSet {
            for index in 0 ..< logDestinations.count {
                logDestinations[index].outputLogLevel = outputLogLevel
            }
        }
    }

    public var xcodeColorsEnabled: Bool = false
    public var xcodeColors: [XCGLogger.LogLevel: XCGLogger.XcodeColor] = [
        .Verbose: .lightGrey,
        .Debug: .darkGrey,
        .Info: .blue,
        .Warning: .orange,
        .Error: .red,
        .Severe: .whiteOnRed
    ]

    // MARK: - Properties
    public class var logQueue: dispatch_queue_t {
        struct Statics {
            static var logQueue = dispatch_queue_create(XCGLogger.Constants.logQueueIdentifier, nil)
        }

        return Statics.logQueue
    }

    private var _dateFormatter: NSDateFormatter? = nil
    public var dateFormatter: NSDateFormatter? {
        get {
            if _dateFormatter != nil {
                return _dateFormatter
            }

            let defaultDateFormatter = NSDateFormatter()
            defaultDateFormatter.locale = NSLocale.currentLocale()
            defaultDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            _dateFormatter = defaultDateFormatter

            return _dateFormatter
        }
        set {
            _dateFormatter = newValue
        }
    }

    public var logDestinations: Array<XCGLogDestinationProtocol> = []

    // MARK: - Life Cycle
    public init(identifier: String = "", includeDefaultDestinations: Bool = true) {
        self.identifier = identifier

        // Check if XcodeColors is installed and enabled
        if let xcodeColors = NSProcessInfo.processInfo().environment["XcodeColors"] {
            xcodeColorsEnabled = xcodeColors == "YES"
        }

        if includeDefaultDestinations {
            // Setup a standard console log destination
            addLogDestination(XCGConsoleLogDestination(owner: self, identifier: XCGLogger.Constants.baseConsoleLogDestinationIdentifier))
        }
    }

    // MARK: - Default instance
    public class func defaultInstance() -> XCGLogger {
        struct Statics {
            static let instance: XCGLogger = XCGLogger(identifier: XCGLogger.Constants.defaultInstanceIdentifier)
        }

        return Statics.instance
    }

    // MARK: - Setup methods
    public class func setup(logLevel: LogLevel = .Debug, showLogIdentifier: Bool = false, showFunctionName: Bool = true, showThreadName: Bool = false, showLogLevel: Bool = true, showFileNames: Bool = true, showLineNumbers: Bool = true, showDate: Bool = true, writeToFile: AnyObject? = nil, fileLogLevel: LogLevel? = nil) {
        defaultInstance().setup(logLevel, showLogIdentifier: showLogIdentifier, showFunctionName: showFunctionName, showThreadName: showThreadName, showLogLevel: showLogLevel, showFileNames: showFileNames, showLineNumbers: showLineNumbers, showDate: showDate, writeToFile: writeToFile)
    }

    public func setup(logLevel: LogLevel = .Debug, showLogIdentifier: Bool = false, showFunctionName: Bool = true, showThreadName: Bool = false, showLogLevel: Bool = true, showFileNames: Bool = true, showLineNumbers: Bool = true, showDate: Bool = true, writeToFile: AnyObject? = nil, fileLogLevel: LogLevel? = nil) {
        outputLogLevel = logLevel;

        if let standardConsoleLogDestination = logDestination(XCGLogger.Constants.baseConsoleLogDestinationIdentifier) as? XCGConsoleLogDestination {
            standardConsoleLogDestination.showLogIdentifier = showLogIdentifier
            standardConsoleLogDestination.showFunctionName = showFunctionName
            standardConsoleLogDestination.showThreadName = showThreadName
            standardConsoleLogDestination.showLogLevel = showLogLevel
            standardConsoleLogDestination.showFileName = showFileNames
            standardConsoleLogDestination.showLineNumber = showLineNumbers
            standardConsoleLogDestination.showDate = showDate
            standardConsoleLogDestination.outputLogLevel = logLevel
        }

        logAppDetails()

        if let writeToFile: AnyObject = writeToFile {
            // We've been passed a file to use for logging, set up a file logger
            let standardFileLogDestination: XCGFileLogDestination = XCGFileLogDestination(owner: self, writeToFile: writeToFile, identifier: XCGLogger.Constants.baseFileLogDestinationIdentifier)

            standardFileLogDestination.showLogIdentifier = showLogIdentifier
            standardFileLogDestination.showFunctionName = showFunctionName
            standardFileLogDestination.showThreadName = showThreadName
            standardFileLogDestination.showLogLevel = showLogLevel
            standardFileLogDestination.showFileName = showFileNames
            standardFileLogDestination.showLineNumber = showLineNumbers
            standardFileLogDestination.showDate = showDate
            standardFileLogDestination.outputLogLevel = fileLogLevel ?? logLevel

            addLogDestination(standardFileLogDestination)
        }
    }

    // MARK: - Logging methods
    public class func logln(@autoclosure closure: () -> String?, logLevel: LogLevel = .Debug, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public class func logln(logLevel: LogLevel = .Debug, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, @noescape closure: () -> String?) {
        self.defaultInstance().logln(logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func logln(@autoclosure closure: () -> String?, logLevel: LogLevel = .Debug, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func logln(logLevel: LogLevel = .Debug, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, @noescape closure: () -> String?) {
        var logDetails: XCGLogDetails? = nil
        for logDestination in self.logDestinations {
            if (logDestination.isEnabledForLogLevel(logLevel)) {
                if logDetails == nil {
                    if let logMessage = closure() {
                        logDetails = XCGLogDetails(logLevel: logLevel, date: NSDate(), logMessage: logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
                    }
                    else {
                        break
                    }
                }

                logDestination.processLogDetails(logDetails!)
            }
        }
    }

    public class func exec(logLevel: LogLevel = .Debug, closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel, closure: closure)
    }

    public func exec(logLevel: LogLevel = .Debug, closure: () -> () = {}) {
        if (!isEnabledForLogLevel(logLevel)) {
            return
        }

        closure()
    }

    public func logAppDetails(selectedLogDestination: XCGLogDestinationProtocol? = nil) {
        let date = NSDate()

        var buildString = ""
        if let infoDictionary = NSBundle.mainBundle().infoDictionary {
            if let CFBundleShortVersionString = infoDictionary["CFBundleShortVersionString"] as? String {
                buildString = "Version: \(CFBundleShortVersionString) "
            }
            if let CFBundleVersion = infoDictionary["CFBundleVersion"] as? String {
                buildString += "Build: \(CFBundleVersion) "
            }
        }

        let processInfo: NSProcessInfo = NSProcessInfo.processInfo()
        let XCGLoggerVersionNumber = XCGLogger.Constants.versionString

        let logDetails: Array<XCGLogDetails> = [XCGLogDetails(logLevel: .Info, date: date, logMessage: "\(processInfo.processName) \(buildString)PID: \(processInfo.processIdentifier)", functionName: "", fileName: "", lineNumber: 0),
            XCGLogDetails(logLevel: .Info, date: date, logMessage: "XCGLogger Version: \(XCGLoggerVersionNumber) - LogLevel: \(outputLogLevel)", functionName: "", fileName: "", lineNumber: 0)]

        for logDestination in (selectedLogDestination != nil ? [selectedLogDestination!] : logDestinations) {
            for logDetail in logDetails {
                if !logDestination.isEnabledForLogLevel(.Info) {
                    continue;
                }

                logDestination.processInternalLogDetails(logDetail)
            }
        }
    }

    // MARK: - Convenience logging methods
    // MARK: * Verbose
    public class func verbose(@autoclosure closure: () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public class func verbose(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, @noescape closure: () -> String?) {
        self.defaultInstance().logln(.Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func verbose(@autoclosure closure: () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(.Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func verbose(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, @noescape closure: () -> String?) {
        self.logln(.Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Debug
    public class func debug(@autoclosure closure: () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public class func debug(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, @noescape closure: () -> String?) {
        self.defaultInstance().logln(.Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func debug(@autoclosure closure: () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(.Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func debug(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, @noescape closure: () -> String?) {
        self.logln(.Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Info
    public class func info(@autoclosure closure: () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public class func info(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, @noescape closure: () -> String?) {
        self.defaultInstance().logln(.Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func info(@autoclosure closure: () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(.Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func info(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, @noescape closure: () -> String?) {
        self.logln(.Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Warning
    public class func warning(@autoclosure closure: () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.Warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public class func warning(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, @noescape closure: () -> String?) {
        self.defaultInstance().logln(.Warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func warning(@autoclosure closure: () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(.Warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func warning(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, @noescape closure: () -> String?) {
        self.logln(.Warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Error
    public class func error(@autoclosure closure: () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public class func error(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, @noescape closure: () -> String?) {
        self.defaultInstance().logln(.Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func error(@autoclosure closure: () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(.Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func error(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, @noescape closure: () -> String?) {
        self.logln(.Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Severe
    public class func severe(@autoclosure closure: () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public class func severe(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, @noescape closure: () -> String?) {
        self.defaultInstance().logln(.Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func severe(@autoclosure closure: () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(.Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func severe(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, @noescape closure: () -> String?) {
        self.logln(.Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: - Exec Methods
    // MARK: * Verbose
    public class func verboseExec(closure: () -> () = {}) {
        self.defaultInstance().exec(XCGLogger.LogLevel.Verbose, closure: closure)
    }

    public func verboseExec(closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.Verbose, closure: closure)
    }

    // MARK: * Debug
    public class func debugExec(closure: () -> () = {}) {
        self.defaultInstance().exec(XCGLogger.LogLevel.Debug, closure: closure)
    }

    public func debugExec(closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.Debug, closure: closure)
    }

    // MARK: * Info
    public class func infoExec(closure: () -> () = {}) {
        self.defaultInstance().exec(XCGLogger.LogLevel.Info, closure: closure)
    }

    public func infoExec(closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.Info, closure: closure)
    }

    // MARK: * Warning
    public class func warningExec(closure: () -> () = {}) {
        self.defaultInstance().exec(XCGLogger.LogLevel.Warning, closure: closure)
    }

    public func warningExec(closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.Warning, closure: closure)
    }

    // MARK: * Error
    public class func errorExec(closure: () -> () = {}) {
        self.defaultInstance().exec(XCGLogger.LogLevel.Error, closure: closure)
    }

    public func errorExec(closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.Error, closure: closure)
    }

    // MARK: * Severe
    public class func severeExec(closure: () -> () = {}) {
        self.defaultInstance().exec(XCGLogger.LogLevel.Severe, closure: closure)
    }

    public func severeExec(closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.Severe, closure: closure)
    }

    // MARK: - Misc methods
    public func isEnabledForLogLevel (logLevel: XCGLogger.LogLevel) -> Bool {
        return logLevel >= self.outputLogLevel
    }

    public func logDestination(identifier: String) -> XCGLogDestinationProtocol? {
        for logDestination in logDestinations {
            if logDestination.identifier == identifier {
                return logDestination
            }
        }

        return nil
    }

    public func addLogDestination(logDestination: XCGLogDestinationProtocol) -> Bool {
        let existingLogDestination: XCGLogDestinationProtocol? = self.logDestination(logDestination.identifier)
        if existingLogDestination != nil {
            return false
        }

        logDestinations.append(logDestination)
        return true
    }

    public func removeLogDestination(logDestination: XCGLogDestinationProtocol) {
        removeLogDestination(logDestination.identifier)
    }

    public func removeLogDestination(identifier: String) {
        logDestinations = logDestinations.filter({$0.identifier != identifier})
    }

    // MARK: - Private methods
    private func _logln(logMessage: String, logLevel: LogLevel = .Debug) {

        var logDetails: XCGLogDetails? = nil
        for logDestination in self.logDestinations {
            if (logDestination.isEnabledForLogLevel(logLevel)) {
                if logDetails == nil {
                    logDetails = XCGLogDetails(logLevel: logLevel, date: NSDate(), logMessage: logMessage, functionName: "", fileName: "", lineNumber: 0)
                }

                logDestination.processInternalLogDetails(logDetails!)
            }
        }
    }

    // MARK: - DebugPrintable
    public var debugDescription: String {
        get {
            var description: String = "\(extractClassName(self)): \(identifier) - logDestinations: \r"
            for logDestination in logDestinations {
                description += "\t \(logDestination.debugDescription)\r"
            }

            return description
        }
    }
}

// Implement Comparable for XCGLogger.LogLevel
public func < (lhs:XCGLogger.LogLevel, rhs:XCGLogger.LogLevel) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

func extractClassName(someObject: Any) -> String {
    return (someObject is Any.Type) ? "\(someObject)" : "\(someObject.dynamicType)"
}
