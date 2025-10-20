// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

@MainActor
public protocol ThemeableView: View {
    var theme: Theme { get set }
    var windowUUID: WindowUUID { get }
    var themeManager: ThemeManager { get }
}

public extension View {
    func listenToThemeChanges(theme: Binding<Theme>, manager: ThemeManager) -> some View {
        ThemeChangeListener(content: self, theme: theme, manager: manager)
    }
}

struct ThemeChangeListener<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme

    let content: Content
    @Binding var theme: Theme
    let manager: ThemeManager

    var body: some View {
        content
           #if DEBUG
            // For SwiftUI previews: responds to Xcode's light/dark mode toggle since NotificationCenter doesn't work in preview environment
            .onChange(of: colorScheme) { newScheme in
                let newTheme: any Theme = newScheme == .dark ? DarkTheme() : LightTheme()
                theme = newTheme
            }
            #else
            .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
                let newTheme = manager.getCurrentTheme(for: notification.windowUUID)
                theme = newTheme
            }
            #endif
    }
}
