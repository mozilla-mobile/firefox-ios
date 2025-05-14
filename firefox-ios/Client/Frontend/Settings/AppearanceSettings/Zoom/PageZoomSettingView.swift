// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct PageZoomSettingsView: View {
    let windowUUID: WindowUUID
    private struct UX {
        static var dividerHeight: CGFloat { 0.7 }
        static var buttonPadding: CGFloat { 4 }
    }

    private var viewBackground: Color {
        return themeColors.layer1.color
    }

    var sectionTitleColor: Color {
        return themeColors.textSecondary.color
    }

    var textColor: Color {
        return themeColors.textPrimary.color
    }

    var descriptionTextColor: Color {
        return themeColors.textSecondary.color
    }

    @Environment(\.themeManager)
    var themeManager
    @State private var themeColors: ThemeColourPalette = LightTheme().colors

    var theme: Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    var body: some View {
        VStack {
            List {
                // Default level picker
                Section {
                    ZoomLevelPickerView(theme: theme)
                        .background(themeColors.layer1.color)
                } header: {
                    GenericSectionHeaderView(title: .Settings.Appearance.PageZoom.DefaultSectionHeader.uppercased(),
                                             sectionTitleColor: sectionTitleColor)
                }

                // Specific site zoom levels
                Section {
                    ZoomSiteListView(theme: theme)
                        .background(themeColors.layer1.color)
                } header: {
                    GenericSectionHeaderView(title: .Settings.Appearance.PageZoom.SpecificSiteSectionHeader.uppercased(),
                                             sectionTitleColor: sectionTitleColor)
                } footer: {
                    Text(String.Settings.Appearance.PageZoom.SpecificSiteFooterTitle)
                        .background(themeColors.layer1.color)
                        .font(.caption)
                        .foregroundColor(descriptionTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .listStyle(.plain)
            .listRowBackground(theme.colors.layer2.color)

            VStack {
                Divider().frame(height: UX.dividerHeight)

                Button(action: {}) {
                    Text(String.Settings.Appearance.PageZoom.ResetButtonTitle)
                        .foregroundColor(theme.colors.textCritical.color)
                }
                .padding([.top, .bottom], UX.buttonPadding)

                Divider().frame(height: UX.dividerHeight)
            }
        }
        .background(themeColors.layer1.color)
        .frame(maxWidth: .infinity)
        .onAppear {
            themeColors = themeManager.getCurrentTheme(for: windowUUID).colors
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            themeColors = themeManager.getCurrentTheme(for: windowUUID).colors
        }
    }
}
