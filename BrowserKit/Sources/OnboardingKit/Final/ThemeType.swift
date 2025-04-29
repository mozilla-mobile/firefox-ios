// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

// MARK: - Theme System

public enum ThemeType { case light, dark }

public struct ThemeColourPalette {
    public let textPrimary: Color
    public let background: Color
    public let buttonPrimaryBackground: Color
    public let buttonPrimaryText: Color
    public let buttonSecondaryBorder: Color

    public init(
        textPrimary: Color,
        background: Color,
        buttonPrimaryBackground: Color,
        buttonPrimaryText: Color,
        buttonSecondaryBorder: Color
    ) {
        self.textPrimary = textPrimary
        self.background = background
        self.buttonPrimaryBackground = buttonPrimaryBackground
        self.buttonPrimaryText = buttonPrimaryText
        self.buttonSecondaryBorder = buttonSecondaryBorder
    }
}

public protocol Theme {
    var type: ThemeType { get }
    var colors: ThemeColourPalette { get }
}

/// A default “light” theme
public struct DefaultTheme: Theme {
    public let type: ThemeType = .light
    public let colors = ThemeColourPalette(
        textPrimary: .primary,
        background: .white,
        buttonPrimaryBackground: .blue,
        buttonPrimaryText: .white,
        buttonSecondaryBorder: .blue
    )
    public init() {}
}

/// A trivial ThemeManager; customize as you like
public class ThemeManager {
    public init() {}
    public func getCurrentTheme(for windowUUID: UUID?) -> Theme {
        DefaultTheme()
    }
}

// MARK: - Injecting Theme into SwiftUI

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = DefaultTheme()
}

public extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

public extension View {
    /// Override the theme in this view hierarchy
    func theme(_ theme: Theme) -> some View {
        environment(\.theme, theme)
    }
}
