// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

struct PageZoomSettingsView: ThemeableView {
    let windowUUID: WindowUUID
    @ObservedObject var viewModel: PageZoomSettingsViewModel
    let themeManager: ThemeManager
    @State var theme: Theme

    /// Settings are always shown in the regular theme, even while the user browses in private mode.
    var shouldUsePrivateOverride: Bool { return true }
    var shouldBeInPrivateTheme: Bool { return false }

    private var themeColors: ThemeColourPalette { return theme.colors }

    private struct UX {
        static let dividerHeight: CGFloat = 0.7
        static let sectionPadding: CGFloat = 16
        static let spacing: CGFloat = 24
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

    init(windowUUID: WindowUUID, themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.windowUUID = windowUUID
        self.viewModel = PageZoomSettingsViewModel(zoomManager: ZoomPageManager(windowUUID: windowUUID))
        self.themeManager = themeManager
        self.theme = themeManager.resolveTheme(for: windowUUID, privateOverride: false)
    }

    var body: some View {
        ScrollView {
            VStack {
                // Default zoom level section
                ZoomLevelPickerView(theme: theme,
                                    zoomManager: viewModel.zoomManager,
                                    onZoomLevelChanged: viewModel.updateDefaultZoomLevel)
                .modifier(PaddingWithColorStyle(theme: theme, spacing: UX.spacing, shouldChangeBackgroundColor: true))

                // Specific site zoom level section
                if !viewModel.domainZoomLevels.isEmpty {
                    ZoomSiteListView(theme: theme,
                                     domainZoomLevels: $viewModel.domainZoomLevels,
                                     onDelete: viewModel.deleteZoomLevel,
                                     resetDomain: viewModel.resetDomainZoomLevel)
                    .modifier(PaddingWithColorStyle(theme: theme, spacing: UX.spacing, shouldChangeBackgroundColor: false))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .background(viewBackground)
        .listenToThemeChanges(in: self, theme: $theme)
    }
}
