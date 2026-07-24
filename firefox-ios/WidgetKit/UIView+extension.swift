// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common

private struct WidgetThemeKey: EnvironmentKey {
    static var defaultValue: Theme { NovaLightTheme() }
}

extension EnvironmentValues {
    /// The Nova theme resolved for the current widget appearance. Injected by `widgetTheme()`
    /// and read by widget views to pull palette colors.
    var theme: Theme {
        get { self[WidgetThemeKey.self] }
        set { self[WidgetThemeKey.self] = newValue }
    }
}

/// Resolves the widget theme from the current `ColorScheme` and injects it into the
/// environment. Because widgets re-render on device appearance changes, reading `colorScheme`
/// here is what makes the theme reactive — mirroring how the main app reacts to theme changes.
private struct WidgetThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.environment(\.theme, WidgetKitThemeManager().theme(for: colorScheme))
    }
}

extension View {
    /// Injects the reactive Nova theme into the environment for the widget subtree.
    func widgetTheme() -> some View {
        modifier(WidgetThemeModifier())
    }

    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }

    @ViewBuilder
    func widgetAccentableCompat() -> some View {
        if #available(iOSApplicationExtension 16.0, *) {
            self.widgetAccentable()
        } else {
            self
        }
    }
}
