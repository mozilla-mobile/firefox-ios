// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

public struct ReaderModeStyle {
    let windowUUID: WindowUUID?
    public var theme: ReaderModeTheme
    public var fontType: ReaderModeFontType
    public var fontSize: ReaderModeFontSize

    /// Encode the style to a JSON dictionary that can be passed to ReaderMode.js
    public func encode() -> String {
        return encodeAsDictionary().asString ?? ""
    }

    /// Encode the style to a dictionary that can be stored in the profile
    public func encodeAsDictionary() -> [String: Any] {
        return ["theme": theme.rawValue, "fontType": fontType.rawValue, "fontSize": fontSize.rawValue]
    }

    public init(windowUUID: WindowUUID?,
                theme: ReaderModeTheme,
                fontType: ReaderModeFontType,
                fontSize: ReaderModeFontSize) {
        self.windowUUID = windowUUID
        self.theme = theme
        self.fontType = fontType
        self.fontSize = fontSize
    }

    /// Initialize the style from a dictionary, taken from the profile. Returns nil if the object cannot be decoded.
    public init?(windowUUID: WindowUUID?, dict: [String: Any]) {
        let themeRawValue = dict["theme"] as? String
        let fontTypeRawValue = dict["fontType"] as? String
        let fontSizeRawValue = dict["fontSize"] as? Int
        if themeRawValue == nil || fontTypeRawValue == nil || fontSizeRawValue == nil {
            return nil
        }

        let theme = ReaderModeTheme(rawValue: themeRawValue!)
        let fontType = ReaderModeFontType(type: fontTypeRawValue!)
        let fontSize = ReaderModeFontSize(rawValue: fontSizeRawValue!)
        if theme == nil || fontSize == nil {
            return nil
        }

        self.windowUUID = windowUUID
        self.theme = theme ?? ReaderModeTheme.preferredTheme(window: windowUUID)
        self.fontType = fontType
        self.fontSize = fontSize!
    }

    public mutating func ensurePreferredColorThemeIfNeeded() {
        self.theme = ReaderModeTheme.preferredTheme(for: self.theme, window: windowUUID)
    }

    public static func defaultStyle(for window: WindowUUID? = nil) -> ReaderModeStyle {
        return ReaderModeStyle(
            windowUUID: window,
            theme: .light,
            fontType: .sansSerif,
            fontSize: ReaderModeFontSize.defaultSize
        )
    }
}
