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

    /// Whether we should override / force the theme to be private or not private. Goes against the basic
    /// theme set up. When `false`, the view uses any override declared by an ancestor view.
    var shouldUsePrivateOverride: Bool { get }

    /// Determines if we want views to be in private theme or not. Only used when
    /// `shouldUsePrivateOverride` is `true`.
    var shouldBeInPrivateTheme: Bool { get }
}

public extension ThemeableView {
    var shouldUsePrivateOverride: Bool { return false }
    var shouldBeInPrivateTheme: Bool { return false }
}

public extension View {
    /// Adds theme change listening capabilities to a `ThemeableView`, using the window, theme manager and
    /// private theme override that the view declares.
    ///
    /// The view's override is also published to its descendants, so nested views that don't declare one of
    /// their own inherit it.
    /// - Parameters:
    ///   - view: The `ThemeableView` this modifier is applied within, usually `self`.
    ///   - theme: A binding to the theme that will be updated when theme changes occur
    /// - Returns: A view wrapped with theme change listening functionality
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
    ///
    /// Prefer `listenToThemeChanges(in:theme:)` in views conforming to `ThemeableView`, so that the private
    /// theme override the view declares is taken into account. Views using this variant only pick up an
    /// override inherited from an ancestor.
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
