//
//  ANSIColorLogFormatter.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2016-08-30.
//  Copyright © 2016 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

// MARK: - ANSIColorLogFormatter
/// A log formatter that will add ANSI colour codes to the message
open class ANSIColorLogFormatter: LogFormatterProtocol, CustomDebugStringConvertible {

    /// ANSI Escape code
    public static let escape: String = "\u{001b}["

    /// ANSI Reset colours code
    public static let reset: String = "\(escape)m"

    /// Enum to specify ANSI colours
    public enum ANSIColor: CustomStringConvertible {
        case black
        case red
        case green
        case yellow
        case blue
        case magenta
        case cyan
        case lightGrey, lightGray
        case darkGrey, darkGray
        case lightRed
        case lightGreen
        case lightYellow
        case lightBlue
        case lightMagenta
        case lightCyan
        case white
        case `default`
        case rgb(red: Int, green: Int, blue: Int)
        case colorIndex(number: Int)

        public var foregroundCode: String {
            switch self {
            case .black:
                return "30"
            case .red:
                return "31"
            case .green:
                return "32"
            case .yellow:
                return "33"
            case .blue:
                return "34"
            case .magenta:
                return "35"
            case .cyan:
                return "36"
            case .lightGrey, .lightGray:
                return "37"
            case .darkGrey, .darkGray:
                return "90"
            case .lightRed:
                return "91"
            case .lightGreen:
                return "92"
            case .lightYellow:
                return "93"
            case .lightBlue:
                return "94"
            case .lightMagenta:
                return "95"
            case .lightCyan:
                return "96"
            case .white:
                return "97"
            case .default: // Note: Different from the default: at the end of a switch, this is the `default` colour
                return "39"
            case .rgb(let red, let green, let blue):
                return "38;2;\(min(max(0, red), 255));\(min(max(0, green), 255));\(min(max(0, blue), 255))"
            case .colorIndex(let number):
                return "38;5;\(min(max(0, number), 255))"
            }
        }

        public var backgroundCode: String {
            switch self {
            case .black:
                return "40"
            case .red:
                return "41"
            case .green:
                return "42"
            case .yellow:
                return "43"
            case .blue:
                return "44"
            case .magenta:
                return "45"
            case .cyan:
                return "46"
            case .lightGrey, .lightGray:
                return "47"
            case .darkGrey, .darkGray:
                return "100"
            case .lightRed:
                return "101"
            case .lightGreen:
                return "102"
            case .lightYellow:
                return "103"
            case .lightBlue:
                return "104"
            case .lightMagenta:
                return "105"
            case .lightCyan:
                return "106"
            case .white:
                return "107"
            case .default: // Note: Different from the default: at the end of a switch, this is the `default` colour
                return "49"
            case .rgb(let red, let green, let blue):
                return "48;2;\(min(max(0, red), 255));\(min(max(0, green), 255));\(min(max(0, blue), 255))"
            case .colorIndex(let number):
                return "48;5;\(min(max(0, number), 255))"
            }
        }

        /// Human readable description of this colour (CustomStringConvertible)
        public var description: String {
            switch self {
            case .black:
                return "Black"
            case .red:
                return "Red"
            case .green:
                return "Green"
            case .yellow:
                return "Yellow"
            case .blue:
                return "Blue"
            case .magenta:
                return "Magenta"
            case .cyan:
                return "Cyan"
            case .lightGrey, .lightGray:
                return "Light Grey"
            case .darkGrey, .darkGray:
                return "Dark Grey"
            case .lightRed:
                return "Light Red"
            case .lightGreen:
                return "Light Green"
            case .lightYellow:
                return "Light Yellow"
            case .lightBlue:
                return "Light Blue"
            case .lightMagenta:
                return "Light Magenta"
            case .lightCyan:
                return "Light Cyan"
            case .white:
                return "White"
            case .default: // Note: Different from the default: at the end of a switch, this is the `default` colour
                return "Default"
            case .rgb(let red, let green, let blue):
                return String(format: "(r: %d, g: %d, b: %d) #%02X%02X%02X", red, green, blue, red, green, blue)
            case .colorIndex(let number):
                return "ANSI color index: \(number)"
            }
        }
    }

    /// Enum to specific ANSI options
    public enum ANSIOption: CustomStringConvertible {
        case bold
        case faint
        case italic
        case underline
        case blink
        case blinkFast
        case strikethrough

        public var code: String {
            switch self {
            case .bold:
                return "1"
            case .faint:
                return "2"
            case .italic:
                return "3"
            case .underline:
                return "4"
            case .blink:
                return "5"
            case .blinkFast:
                return "6"
            case .strikethrough:
                return "9"
            }
        }

        public var description: String {
            switch self {
            case .bold:
                return "Bold"
            case .faint:
                return "Faint"
            case .italic:
                return "Italic"
            case .underline:
                return "Underline"
            case .blink:
                return "Blink"
            case .blinkFast:
                return "Blink Fast"
            case .strikethrough:
                return "Strikethrough"
            }
        }
    }

    /// Internal cache of the ANSI codes for each log level
    internal var formatStrings: [XCGLogger.Level: String] = [:]

    /// Internal cache of the description for each log level
    internal var descriptionStrings: [XCGLogger.Level: String] = [:]

    public init() {
        resetFormatting()
    }

    /// Set the colours and/or options for a specific log level.
    ///
    /// - Parameters:
    ///     - level:            The log level.
    ///     - foregroundColor:  The text colour of the message. **Default:** Restore default text colour
    ///     - backgroundColor:  The background colour of the message. **Default:** Restore default background colour
    ///     - options:          Array of ANSIOptions to apply to the message. **Default:** No options
    ///
    /// - Returns:  Nothing
    ///
    open func colorize(level: XCGLogger.Level, with foregroundColor: ANSIColor = .default, on backgroundColor: ANSIColor = .default, options: [ANSIOption] = []) {
        var codes: [String] = [foregroundColor.foregroundCode, backgroundColor.backgroundCode]
        var description: String = "\(foregroundColor) on \(backgroundColor)"

        for option in options {
            codes.append(option.code)
            description += "/\(option)"
        }

        formatStrings[level] = ANSIColorLogFormatter.escape + codes.joined(separator: ";") + "m"
        descriptionStrings[level] = description
    }

    /// Set the colours and/or options for a specific log level.
    ///
    /// - Parameters:
    ///     - level:    The log level.
    ///     - custom:   A specific ANSI code to use.
    ///
    /// - Returns:  Nothing
    ///
    open func colorize(level: XCGLogger.Level, custom: String) {
        if custom.hasPrefix(ANSIColorLogFormatter.escape) {
            formatStrings[level] = "\(custom)"
            descriptionStrings[level] = "Custom: \(custom[custom.index(custom.startIndex, offsetBy: ANSIColorLogFormatter.escape.lengthOfBytes(using: .utf8)) ..< custom.endIndex])"
        }
        else {
            formatStrings[level] = ANSIColorLogFormatter.escape + "\(custom)"
            descriptionStrings[level] = "Custom: \(custom)"
        }
    }

    /// Get the cached ANSI codes for the specified log level.
    ///
    /// - Parameters:
    ///     - level:            The log level.
    ///
    /// - Returns:  The ANSI codes for the specified log level.
    ///
    internal func formatString(for level: XCGLogger.Level) -> String {
        return formatStrings[level] ?? ANSIColorLogFormatter.reset
    }

    /// Apply a default set of colours.
    ///
    /// - Parameters:   None
    ///
    /// - Returns:  Nothing
    ///
    open func resetFormatting() {
        colorize(level: .verbose, with: .white, options: [.bold])
        colorize(level: .debug, with: .black)
        colorize(level: .info, with: .blue)
        colorize(level: .warning, with: .yellow)
        colorize(level: .error, with: .red, options: [.bold])
        colorize(level: .severe, with: .white, on: .red)
        colorize(level: .none)
    }

    /// Clear all previously set colours. (Sets each log level back to default)
    ///
    /// - Parameters:   None
    ///
    /// - Returns:  Nothing
    ///
    open func clearFormatting() {
        colorize(level: .verbose)
        colorize(level: .debug)
        colorize(level: .info)
        colorize(level: .warning)
        colorize(level: .error)
        colorize(level: .severe)
        colorize(level: .none)
    }

    // MARK: - LogFormatterProtocol
    /// Apply some additional formatting to the message if appropriate.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:      Formatted/processed message ready for output.
    ///
    /// - Returns:  message with the additional formatting
    ///
    @discardableResult open func format(logDetails: inout LogDetails, message: inout String) -> String {
        message = "\(formatString(for: logDetails.level))\(message)\(ANSIColorLogFormatter.reset)"
        return message
    }

    // MARK: - CustomDebugStringConvertible
    open var debugDescription: String {
        get {
            var description: String = "\(extractTypeName(self)): "
            for level in XCGLogger.Level.allCases {
                description += "\n\t- \(level) > \(descriptionStrings[level] ?? "None")"
            }

            return description
        }
    }
}
