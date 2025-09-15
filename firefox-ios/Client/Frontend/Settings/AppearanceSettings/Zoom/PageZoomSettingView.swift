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
        static let spacing: CGFloat = 24
        static let cornerRadius: CGFloat = 24
        static let sectionPadding: CGFloat = 16
    }

    var sectionTitleColor: Color {
        return themeColors.textSecondary.color
    }

    var textColor: Color {
        return themeColors.textPrimary.color
    }

    var cellBackground: Color {
        return theme.colors.layer1.color
    }

    init(windowUUID: WindowUUID) {
        if #available(iOS 15, *) {
            UITableView.appearance().backgroundColor = .clear
        }
        self.windowUUID = windowUUID
        self.viewModel = PageZoomSettingsViewModel(zoomManager: ZoomPageManager(windowUUID: windowUUID))
    }

    var theme: Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    var body: some View {
        List {
            // Default zoom level section
            ZoomLevelPickerView(theme: theme,
                                zoomManager: viewModel.zoomManager,
                                onZoomLevelChanged: viewModel.updateDefaultZoomLevel)
            .listRowSeparator(.hidden)
            .listRowInsets(.init())

            // Specific site zoom level section
            if !viewModel.domainZoomLevels.isEmpty {
                ZoomSiteListView(theme: theme,
                                 domainZoomLevels: $viewModel.domainZoomLevels,
                                 onDelete: viewModel.deleteZoomLevel,
                                 resetDomain: viewModel.resetDomainZoomLevel)
                .listRowInsets(.init())
            }
        }
        .modifier(ListSectionSpacing())
        .modifier(ListStyle(theme: theme, cellBackground: cellBackground, viewBackground: themeColors.layer1.color))
        .modifier(ScrollContentBackground(background: themeColors.layer1.color))
        .onAppear {
            themeColors = themeManager.getCurrentTheme(for: windowUUID).colors
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            themeColors = themeManager.getCurrentTheme(for: windowUUID).colors
        }
    }

    private struct ListStyle: ViewModifier {
        let theme: Theme?
        let cellBackground: Color
        let viewBackground: Color

        func body(content: Content) -> some View {
            if #unavailable(iOS 26.0) {
                content
                    .listStyle(.grouped)
                    .listSectionSeparator(.hidden)
            } else {
                content
                    .listSectionSeparator(.hidden)
            }
        }
    }

    private struct ScrollContentBackground: ViewModifier {
        let background: Color

        func body(content: Content) -> some View {
            if #available(iOS 16.0, *) {
                content
                    .scrollContentBackground(.hidden)
                    .background(background)
            } else {
                content
                    .background(background)
            }
        }
    }

    private struct ListSectionSpacing: ViewModifier {
        func body(content: Content) -> some View {
            if #available(iOS 26.0, *) {
                content
                    .frame(maxWidth: .infinity)
                    .padding(.top, UX.spacing)
            } else if #available(iOS 17.0, *) {
                content
                    .listSectionSpacing(UX.sectionPadding)
                    .frame(maxWidth: .infinity)
                    .padding([.bottom, .leading, .trailing], .zero)
            } else {
                content
                    .frame(maxWidth: .infinity)
                    .padding([.bottom, .leading, .trailing], .zero)
            }
        }
    }
}
