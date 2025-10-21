// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A protocol for SwiftUI views that can respond to theme changes.
/// Provides the necessary properties for theme management and automatic theme updates.
@MainActor
public protocol ThemeableView: View {
    /// The current theme being used by the view
    var theme: Theme { get set }
    /// Unique identifier for the window containing this view
    var windowUUID: WindowUUID { get }
    /// Manager responsible for handling theme changes across the application
    var themeManager: ThemeManager { get }
}

public extension View {
    /// Adds theme change listening capabilities to any SwiftUI view.
    /// - Parameters:
    ///   - theme: A binding to the theme that will be updated when theme changes occur
    ///   - manager: The theme manager to listen for theme changes from
    ///   - windowUUID: The window identifier to filter theme change notifications
    /// - Returns: A view wrapped with theme change listening functionality
    func listenToThemeChanges(theme: Binding<Theme>, manager: ThemeManager, windowUUID: WindowUUID) -> some View {
        ThemeChangeListener(content: self, theme: theme, manager: manager, windowUUID: windowUUID)
    }
}

/// A view modifier that listens for theme changes and updates the bound theme accordingly.
/// In DEBUG mode, responds to Xcode's light/dark mode toggle for SwiftUI previews.
/// In production, listens to NotificationCenter for theme change notifications.
struct ThemeChangeListener<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme

    let content: Content
    @Binding var theme: Theme
    let manager: ThemeManager
    let windowUUID: WindowUUID

    var body: some View {
        #if DEBUG
        debugThemeHandler
        #else
        content
            .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
                // Only update theme if the notification is for this specific window
                if notification.windowUUID == windowUUID {
                    let newTheme = manager.getCurrentTheme(for: notification.windowUUID)
                    theme = newTheme
                }
            }
        #endif
    }
}
