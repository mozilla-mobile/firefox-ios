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
    /// - Parameter palette: The theme palette to pull colors from.
    /// - Returns: A tuple containing `(primary: UIColor, secondary: UIColor)`.
    func colors(from palette: ThemeColourPalette) -> (primary: UIColor, secondary: UIColor) {
        switch self {
        case .regular:
            return (palette.actionPrimary, palette.iconDisabled)
        case .compact:
            return (palette.layer1, palette.iconDisabled)
        }
    }
}

/// A customizable SwiftUI page control that adapts to theme changes.
public struct CustomPageControl: View {
    @State private var primaryActionColor: Color = .clear
    @State private var secondaryActionColor: Color = .clear
    @Binding var currentPage: Int
    let windowUUID: WindowUUID
    let themeManager: ThemeManager
    let numberOfPages: Int
    let style: PageControlStyle

    /// Creates a new page control.
    ///
    /// - Parameters:
    ///   - currentPage: Binding to the currently selected page index.
    ///   - numberOfPages: Total number of pages.
    ///   - windowUUID: The window identifier for theme updates.
    ///   - themeManager: Provides theme info.
    ///   - style: Visual style (regular or compact). Defaults to `.regular`.
    public init(
        currentPage: Binding<Int>,
        numberOfPages: Int,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        style: PageControlStyle = .regular
    ) {
        self._currentPage = currentPage
        self.numberOfPages = numberOfPages
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.style = style
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? primaryActionColor : secondaryActionColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentPage ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
        .onAppear {
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) {
            guard let uuid = $0.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
    }

    private func applyTheme(theme: Theme) {
        let colors = style.colors(from: theme.colors)
        primaryActionColor = Color(colors.primary)
        secondaryActionColor = Color(colors.secondary)
    }
}
