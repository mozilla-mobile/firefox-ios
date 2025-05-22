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
        VStack {
            List {
                // Default level picker
                ZoomLevelPickerView(theme: theme, zoomManager: viewModel.zoomManager)
                    .listRowInsets(EdgeInsets())

                if !viewModel.domainZoomLevels.isEmpty {
                    // Specific site zoom levels
                    ZoomSiteListView(theme: theme,
                                     domainZoomLevels: $viewModel.domainZoomLevels,
                                     onDelete: viewModel.deleteZoomLevel)
                        .listRowInsets(EdgeInsets())

                    // Reset Zoom
                    GenericButtonCellView(theme: theme,
                                          title: String.Settings.Appearance.PageZoom.ResetButtonTitle,
                                          onTap: viewModel.resetDomainZoomLevel)
                        .listRowInsets(EdgeInsets())
                }
            }
            .background(viewBackground)
            .listStyle(.inset)
        }
        .onAppear {
            themeColors = themeManager.getCurrentTheme(for: windowUUID).colors
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            themeColors = themeManager.getCurrentTheme(for: windowUUID).colors
        }
    }
}
