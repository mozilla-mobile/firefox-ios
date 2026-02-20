// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// Styles available for the page control indicators.
public enum PageControlStyle {
    /// Indicator size class: regular
    case regular
    /// Indicator size class: compact
    case compact

    /// Returns the primary and secondary colors for this style from the given palette.
    ///
    /// - Parameters:
    ///   - palette: The theme palette to pull colors from.
    ///   - isBrandRefresh: Whether this is for the brand refresh variant.
    /// - Returns: A tuple containing `(primary: UIColor, secondary: UIColor)`.
    func colors(from palette: ThemeColourPalette, isBrandRefresh: Bool = false) -> (primary: UIColor, secondary: UIColor) {
        if isBrandRefresh {
            return (palette.iconPrimary, palette.iconDisabled)
        }

        switch self {
        case .regular:
            return (palette.actionPrimary, palette.iconDisabled)
        case .compact:
            return (palette.layer1, palette.iconDisabled)
        }
    }
}

/// A customizable SwiftUI page control that adapts to theme changes.
public struct CustomPageControl: ThemeableView {
    @State public var theme: Theme
    @Binding var currentPage: Int
    public let windowUUID: WindowUUID
    public var themeManager: ThemeManager
    let numberOfPages: Int
    let style: PageControlStyle
    let isBrandRefresh: Bool
    let accessibilityIdentifier: String

    /// Creates a new page control.
    ///
    /// - Parameters:
    ///   - currentPage: Binding to the currently selected page index.
    ///   - numberOfPages: Total number of pages.
    ///   - windowUUID: The window identifier for theme updates.
    ///   - themeManager: Provides theme info.
    ///   - style: Visual style (regular or compact). Defaults to `.regular`.
    ///   - isBrandRefresh: Whether this is for the brand refresh variant. Defaults to `false`.
    ///   - accessibilityIdentifier: The accessibility identifier for the page control.
    public init(
        currentPage: Binding<Int>,
        numberOfPages: Int,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        style: PageControlStyle = .regular,
        isBrandRefresh: Bool = false,
        accessibilityIdentifier: String
    ) {
        self._currentPage = currentPage
        self.numberOfPages = numberOfPages
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.style = style
        self.isBrandRefresh = isBrandRefresh
        self.accessibilityIdentifier = accessibilityIdentifier
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
    }

    public var body: some View {
        let colors = style.colors(from: theme.colors, isBrandRefresh: isBrandRefresh)
        let primaryActionColor = Color(colors.primary)
        let secondaryActionColor = Color(colors.secondary)

        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? primaryActionColor : secondaryActionColor)
                    .frame(width: 6, height: 6)
                    .scaleEffect(index == currentPage ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(accessibilityIdentifier)
        .listenToThemeChanges(
            theme: $theme,
            manager: themeManager,
            windowUUID: windowUUID
        )
    }
}
