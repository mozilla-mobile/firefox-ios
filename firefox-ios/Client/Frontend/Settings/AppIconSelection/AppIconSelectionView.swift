// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct AppIconSelectionView: View, ThemeApplicable {
    private let windowUUID: WindowUUID
    private let logger: Logger
    private let telemetry: AppIconSelectionTelemetry

    struct UX {
        static let listPadding: CGFloat = 20
        static let cornerRadius: CGFloat = 10
        static let islandBorderWidth: CGFloat = 1
    }

    @State private var currentAppIcon = AppIcon.initFromSystem()

    // MARK: - Theming
    // FIXME FXIOS-11472 Improve our SwiftUI theming
    @Environment(\.themeManager)
    var themeManager
    @State private var themeColors: ThemeColourPalette = LightTheme().colors

    init(
        windowUUID: WindowUUID,
        gleanWrapper: GleanWrapper = DefaultGleanWrapper(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.windowUUID = windowUUID
        self.telemetry = AppIconSelectionTelemetry(gleanWrapper: gleanWrapper)
        self.logger = logger
    }

    var body: some View {
        NavigationView {
            // Note: Once we drop iOS 15 support we can use a List and properly set background colors / insetGrouped style
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    ForEach(AppIcon.allCases, id: \.imageSetAssetName) { appIcon in
                        AppIconView(
                            appIcon: appIcon,
                            isSelected: appIcon == currentAppIcon,
                            windowUUID: windowUUID,
                            setAppIcon: setAppIcon
                        )
                    }
                }
                .background(themeColors.layer2.color)
                .cornerRadius(UX.cornerRadius)
                .overlay(
                    // Add rounded border
                    RoundedRectangle(cornerRadius: UX.cornerRadius)
                        .stroke(themeColors.borderPrimary.color, lineWidth: UX.islandBorderWidth)
                )

                Spacer()
            }
            .padding(.all, UX.listPadding)
            .background(themeColors.layer1.color)
            .onAppear {
                applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            }
            .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
                guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
                applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Don't display as navigation detail on iPad
    }

    func applyTheme(theme: Theme) {
        self.themeColors = theme.colors
    }

    private func setAppIcon(to appIcon: AppIcon) {
        guard UIApplication.shared.supportsAlternateIcons else { return }

        // If the user is resetting to the default app icon, we need to set the alternative icon to nil.
        UIApplication.shared.setAlternateIconName(appIcon.appIconAssetName) { error in
            guard error == nil else {
                logger.log("Failed to set an alternative app icon [\(appIcon)]", level: .fatal, category: .appIcon)
                // TODO FXIOS-11474 Handle the error with an alert to the user
                return
            }

            telemetry.selectedIcon(appIcon: appIcon)

            self.currentAppIcon = appIcon
        }
    }
}

struct AppIconSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        AppIconSelectionView(windowUUID: UUID())
    }
}
