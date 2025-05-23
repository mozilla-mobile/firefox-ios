// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

struct PageZoomSettingsView: View {
    private let windowUUID: WindowUUID
    @ObservedObject var viewModel: PageZoomSettingsViewModel
    @Environment(\.themeManager)
    var themeManager
    @State private var themeColors: ThemeColourPalette = LightTheme().colors

    private struct UX {
        static var dividerHeight: CGFloat = 0.7
        static var sectionPadding: CGFloat = 16
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

    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        self.viewModel = PageZoomSettingsViewModel(zoomManager: ZoomPageManager(windowUUID: windowUUID))
    }

    var theme: Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Default zoom level section
                VStack {
                    // Header
                    GenericSectionHeaderView(title: .Settings.Appearance.PageZoom.DefaultSectionHeader.uppercased(),
                                             sectionTitleColor: theme.colors.textSecondary.color)
                        .padding([.leading, .trailing, .top], UX.sectionPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(viewBackground)

                    // Picker
                    ZoomLevelPickerView(theme: theme, zoomManager: viewModel.zoomManager)
                        .background(theme.colors.layer5.color)
                }

                if !viewModel.domainZoomLevels.isEmpty {
                    // Specific site zoom level section
                    VStack {
                        ZoomSiteListView(theme: theme,
                                         domainZoomLevels: $viewModel.domainZoomLevels,
                                         onDelete: viewModel.deleteZoomLevel,
                                         resetDomain: viewModel.resetDomainZoomLevel)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .background(viewBackground)
        .onAppear {
            themeColors = themeManager.getCurrentTheme(for: windowUUID).colors
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            themeColors = themeManager.getCurrentTheme(for: windowUUID).colors
        }
    }
}
