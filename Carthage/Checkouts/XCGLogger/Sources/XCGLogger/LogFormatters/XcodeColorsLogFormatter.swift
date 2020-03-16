//
//  XcodeColorsLogFormatter.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2016-08-30.
//  Copyright © 2016 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

#if os(macOS)
    import AppKit
#elseif os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#endif

// MARK: - XcodeColorsLogFormatter
/// A log formatter that will add colour codes for the [XcodeColor plug-in](https://github.com/robbiehanson/XcodeColors) to the message
open class XcodeColorsLogFormatter: LogFormatterProtocol, CustomDebugStringConvertible {

    /// XcodeColors escape code
    public static let escape: String = "\u{001b}["

    /// XcodeColors code to reset the foreground colour
    public static let resetForeground = "\(escape)fg;"

    /// XcodeColors code to reset the background colour
    public static let resetBackground = "\(escape)bg;"

    /// XcodeColors code to reset both the foreground and background colours
    public static let reset: String = "\(escape);"

    /// Struct to store RGB values
    public struct XcodeColor: CustomStringConvertible {
        /// Red component
        public var red: Int = 0 {
            didSet {
                guard red < 0 || red > 255 else { return }
                red = 0
            }
        }

        /// Green component
        public var green: Int = 0 {
            didSet {
                guard green < 0 || green > 255 else { return }
                green = 0
            }
        }

        /// Blue component
        public var blue: Int = 0 {
            didSet {
                guard blue < 0 || blue > 255 else { return }
                blue = 0
            }
        }

        /// Foreground code
        public var foregroundCode: String {
            return "fg\(red),\(green),\(blue)"
        }

        /// Background code
        public var backgroundCode: String {
            return "bg\(red),\(green),\(blue)"
        }

        public init(red: Int, green: Int, blue: Int) {
            self.red = red
            self.green = green
            self.blue = blue
        }

        public init(_ red: Int, _ green: Int, _ blue: Int) {
            self.red = red
            self.green = green
            self.blue = blue
        }

#if os(macOS)
        public init(color: NSColor) {
            if let colorSpaceCorrected = color.usingColorSpaceName(NSColorSpaceName.calibratedRGB) {
                self.red = Int(colorSpaceCorrected.redComponent * 255)
                self.green = Int(colorSpaceCorrected.greenComponent * 255)
                self.blue = Int(colorSpaceCorrected.blueComponent * 255)
            }
        }
#elseif os(iOS) || os(tvOS) || os(watchOS)
        public init(color: UIColor) {
            var redComponent: CGFloat = 0
            var greenComponent: CGFloat = 0
            var blueComponent: CGFloat = 0
            var alphaComponent: CGFloat = 0

            color.getRed(&redComponent, green: &greenComponent, blue: &blueComponent, alpha:&alphaComponent)

            self.red = Int(redComponent * 255)
            self.green = Int(greenComponent * 255)
            self.blue = Int(blueComponent * 255)
        }
#endif

        /// Human readable description of this colour (CustomStringConvertible)
        public var description: String {
            return String(format: "(r: %d, g: %d, b: %d) #%02X%02X%02X", red, green, blue, red, green, blue)
        }

        /// Preset colour: Red
        public static let red: XcodeColor = { return XcodeColor(red: 255, green: 0, blue: 0) }()

        /// Preset colour: Green
        public static let green: XcodeColor = { return XcodeColor(red: 0, green: 255, blue: 0) }()

        /// Preset colour: Blue
        public static let blue: XcodeColor = { return XcodeColor(red: 0, green: 0, blue: 255) }()

        /// Preset colour: Black
        public static let black: XcodeColor = { return XcodeColor(red: 0, green: 0, blue: 0) }()

        /// Preset colour: White
        public static let white: XcodeColor = { return XcodeColor(red: 255, green: 255, blue: 255) }()

        /// Preset colour: Light Grey
        public static let lightGrey: XcodeColor = { return XcodeColor(red: 211, green: 211, blue: 211) }()

        /// Preset colour: Dark Grey
        public static let darkGrey: XcodeColor = { return XcodeColor(red: 169, green: 169, blue: 169) }()

        /// Preset colour: Orange
        public static let orange: XcodeColor = { return XcodeColor(red: 255, green: 165, blue: 0) }()

        /// Preset colour: Purple
        public static let purple: XcodeColor = { return XcodeColor(red: 170, green: 0, blue: 170) }()

        /// Preset colour: Dark Green
        public static let darkGreen: XcodeColor = { return XcodeColor(red: 0, green: 128, blue: 0) }()

        /// Preset colour: Cyan
        public static let cyan: XcodeColor = { return XcodeColor(red: 0, green: 170, blue: 170) }()
    }

    /// Internal cache of the XcodeColors codes for each log level
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
    ///
    /// - Returns:  Nothing
    ///
    open func colorize(level: XCGLogger.Level, with foregroundColor: XcodeColor? = nil, on backgroundColor: XcodeColor? = nil) {
        guard foregroundColor != nil || backgroundColor != nil else {
            // neither set, use reset code
            formatStrings[level] = XcodeColorsLogFormatter.reset
            descriptionStrings[level] = "None"
            return
        }

        var formatString: String = ""

        if let foregroundColor = foregroundColor {
            formatString += "\(XcodeColorsLogFormatter.escape)fg\(foregroundColor.red),\(foregroundColor.green),\(foregroundColor.blue);"
        }
        else {
            formatString += XcodeColorsLogFormatter.resetForeground
        }

        if let backgroundColor = backgroundColor {
            formatString += "\(XcodeColorsLogFormatter.escape)bg\(backgroundColor.red),\(backgroundColor.green),\(backgroundColor.blue);"
        }
        else {
            formatString += XcodeColorsLogFormatter.resetBackground
        }

        formatStrings[level] = formatString
        descriptionStrings[level] = "\(foregroundColor?.description ?? "Default") on \(backgroundColor?.description ?? "Default")"
    }

    /// Get the cached XcodeColors codes for the specified log level.
    ///
    /// - Parameters:
    ///     - level:            The log level.
    ///
    /// - Returns:  The XcodeColors codes for the specified log level.
    ///
    internal func formatString(for level: XCGLogger.Level) -> String {
        return formatStrings[level] ?? XcodeColorsLogFormatter.reset
    }

    /// Apply a default set of colours.
    ///
    /// - Parameters:   None
    ///
    /// - Returns:  Nothing
    ///
    open func resetFormatting() {
        colorize(level: .verbose, with: .lightGrey)
        colorize(level: .debug, with: .darkGrey)
        colorize(level: .info, with: .blue)
        colorize(level: .warning, with: .orange)
        colorize(level: .error, with: .red)
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
        message = "\(formatString(for: logDetails.level))\(message)\(XcodeColorsLogFormatter.reset)"
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
