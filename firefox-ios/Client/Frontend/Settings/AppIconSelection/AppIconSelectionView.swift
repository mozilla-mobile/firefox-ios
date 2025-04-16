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
    @State private var isShowingErrorAlert = false

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
        VStack {
            List {
                ForEach(AppIcon.allCases, id: \.imageSetAssetName) { appIcon in
                    AppIconView(
                        appIcon: appIcon,
                        isSelected: appIcon == currentAppIcon,
                        windowUUID: windowUUID,
                        setAppIcon: setAppIcon
                    )
                }.listRowBackground(themeColors.layer2.color)
            }
            .listStyle(.plain)
            .alert(isPresented: $isShowingErrorAlert) {
                Alert(
                    title: Text(String.Settings.AppIconSelection.Errors.SelectErrorMessage),
                    message: nil,
                    dismissButton: .default(
                        Text(String.Settings.AppIconSelection.Errors.SelectErrorConfirmation)
                    )
                )
            }
            .onAppear {
                applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            }
            .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
                guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
                applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            }
        }
        .background(themeColors.layer1.color)
    }

    func applyTheme(theme: Theme) {
        self.themeColors = theme.colors
    }

    private func setAppIcon(to appIcon: AppIcon) {
        guard UIApplication.shared.supportsAlternateIcons else { return }

        // Don't reselect the current icon
        guard appIcon != currentAppIcon else { return }

        // Optimistically update the UI since there's a slight delay in setting the alternate app icon
        let previousIcon = self.currentAppIcon
        self.currentAppIcon = appIcon

        // If the user is resetting to the default app icon, we need to set the alternative icon to nil.
        UIApplication.shared.setAlternateIconName(appIcon.appIconAssetName) { error in
            guard error == nil else {
                logger.log("Failed to set an alternative app icon [\(appIcon)]", level: .fatal, category: .appIcon)
                isShowingErrorAlert = true

                // Reset the app icon in the UI since we changed it optimistically to provide UI feedback
                self.currentAppIcon = previousIcon

                return
            }

            telemetry.selectedIcon(appIcon, previousIcon: previousIcon)
        }
    }
}

struct AppIconSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        AppIconSelectionView(windowUUID: UUID())
    }
}
