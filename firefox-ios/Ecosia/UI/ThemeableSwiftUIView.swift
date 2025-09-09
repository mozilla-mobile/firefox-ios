// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
// swiftlint:disable orphaned_doc_comment
/// Ecosia SwiftUI Theming Architecture
///
/// Usage:
/// 1. Create a theme container:
///    ```swift
///    struct MyComponentTheme: EcosiaThemeable {
///        var backgroundColor = Color.white
///        var textColor = Color.black
///
///        mutating func applyTheme(theme: Theme) {
///            backgroundColor = Color(theme.colors.ecosia.backgroundPrimary)
///            textColor = Color(theme.colors.ecosia.textPrimary)
///        }
///    }
///    ```
///
/// 2. Use in your view:
///    ```swift
///    struct MyComponent: View {
///        private let windowUUID: WindowUUID
///        @State private var theme = MyComponentTheme()
///
///        var body: some View {
///            Text("Hello")
///                .foregroundColor(theme.textColor)
///                .ecosiaThemed(windowUUID, $theme)
///        }
///    }
///    ```

// MARK: - EcosiaThemeable Protocol

/// Protocol for theme containers that can receive theme updates
public protocol EcosiaThemeable {
    /// Apply the given theme to update the theme properties
    /// - Parameter theme: The theme to apply
    mutating func applyTheme(theme: Theme)
}

// MARK: - Theme Modifier

/// ViewModifier for applying theme updates automatically
struct ThemeModifier<T: EcosiaThemeable>: ViewModifier {
    let windowUUID: WindowUUID?
    @Binding var theme: T

    func body(content: Content) -> some View {
        content
            .onAppear {
                let themeManager = AppContainer.shared.resolve() as ThemeManager
                theme.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            }
            .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
                guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
                let themeManager = AppContainer.shared.resolve() as ThemeManager
                theme.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            }
    }
}

// MARK: - View Extension for Theme Handling

public extension View {
    /// Applies automatic theme handling to a view
    /// - Parameters:
    ///   - windowUUID: The window UUID for theme management
    ///   - theme: A binding to the themeable object
    /// - Returns: A view that automatically updates when theme changes
    func ecosiaThemed<T: EcosiaThemeable>(_ windowUUID: WindowUUID?, _ theme: Binding<T>) -> some View {
        modifier(ThemeModifier(windowUUID: windowUUID, theme: theme))
    }
}
// swiftlint:enable orphaned_doc_comment
