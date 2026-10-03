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

    /// When `false`, the view uses any override declared by an ancestor view instead.
    var shouldUsePrivateOverride: Bool { get }
    var shouldBeInPrivateTheme: Bool { get }
}

public extension ThemeableView {
    var shouldUsePrivateOverride: Bool { return false }
    var shouldBeInPrivateTheme: Bool { return false }
}

public extension View {
    /// The view's private theme override, if any, is also published to its descendants.
    @MainActor
    func listenToThemeChanges(in view: some ThemeableView, theme: Binding<Theme>) -> some View {
        ThemeChangeListener(
            content: self,
            theme: theme,
            manager: view.themeManager,
            windowUUID: view.windowUUID,
            declaredPrivacyOverride: view.shouldUsePrivateOverride ? view.shouldBeInPrivateTheme : nil
        )
    }

    /// Adds theme change listening capabilities to any SwiftUI view.
    /// - Parameters:
    ///   - theme: A binding to the theme that will be updated when theme changes occur
    ///   - manager: The theme manager to listen for theme changes from
    ///   - windowUUID: The window identifier to filter theme change notifications
    /// - Returns: A view wrapped with theme change listening functionality
    func listenToThemeChanges(theme: Binding<Theme>, manager: ThemeManager, windowUUID: WindowUUID) -> some View {
        ThemeChangeListener(content: self,
                            theme: theme,
                            manager: manager,
                            windowUUID: windowUUID,
                            declaredPrivacyOverride: nil)
    }
}

/// A view modifier that listens for theme changes and updates the bound theme accordingly.
/// In Xcode previews, responds to the light/dark mode toggle instead, since theme change notifications
/// are never posted there.
struct ThemeChangeListener<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.themePrivacyOverride) private var inheritedPrivacyOverride

    let content: Content
    @Binding var theme: Theme
    let manager: ThemeManager
    let windowUUID: WindowUUID
    let declaredPrivacyOverride: Bool?

    /// An override declared by the view itself takes precedence over one inherited from an ancestor.
    var privacyOverride: Bool? { declaredPrivacyOverride ?? inheritedPrivacyOverride }

    var body: some View {
        themedContent
            .themePrivacyOverride(shouldUsePrivateOverride: privacyOverride != nil,
                                  shouldBeInPrivateTheme: privacyOverride ?? false)
            // Resolves the theme once the environment is available, which it isn't in a view's initializer.
            .onAppear { updateTheme() }
    }

    private var themedContent: some View {
        #if DEBUG
        debugThemeHandler(for: themeChangeObserver)
        #else
        themeChangeObserver
        #endif
    }

    private var themeChangeObserver: some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
                // Only update theme if the notification is for this specific window
                guard notification.windowUUID == windowUUID else { return }
                updateTheme()
            }
    }

    func updateTheme() {
        theme = manager.resolveTheme(for: windowUUID, privateOverride: privacyOverride)
    }
}
