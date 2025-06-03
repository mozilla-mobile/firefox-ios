// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Storage
import Redux

import Security
import CryptoKit
import X509
import SwiftASN1

class TrackingProtectionModel {
    // MARK: - Constants
    let contentBlockerStatus: BlockerStatus
    var contentBlockerStats: TPPageStats?
    var certificates = [Certificate]()
    let url: URL
    let displayTitle: String
    var connectionSecure: Bool
    let globalETPIsEnabled: Bool
    var selectedTab: Tab?

    let clearCookiesButtonTitle: String = .Menu.EnhancedTrackingProtection.clearDataButtonTitle
    let clearCookiesButtonA11yId: String = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.clearCookiesButton

    let settingsButtonTitle: String = .Menu.EnhancedTrackingProtection.privacySettingsTitle

    let clearCookiesAlertTitle: String = .Menu.EnhancedTrackingProtection.clearDataAlertTitle
    let clearCookiesAlertText: String = .Menu.EnhancedTrackingProtection.clearDataAlertText
    let clearCookiesAlertButton: String = .Menu.EnhancedTrackingProtection.clearDataAlertButton
    let clearCookiesAlertCancelButton: String = .Menu.EnhancedTrackingProtection.clearDataAlertCancelButton

    // MARK: Accessibility Identifiers
    let foxImageA11yId: String = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.foxImage
    let shieldImageA11yId: String = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.shieldImage
    let lockImageA11yId: String = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.lockImage
    let arrowImageA11yId: String = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.arrowImage

    let settingsA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.trackingProtectionSettingsButton
    let domainLabelA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.domainLabel
    let domainHeaderLabelA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.domainHeaderLabel
    let statusTitleLabelA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.statusTitleLabel
    let statusBodyLabelA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.statusBodyLabel
    let trackersBlockedButtonA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.trackersBlockedButton
    let securityStatusButtonA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.securityStatusButton
    let toggleViewContainerA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.toggleViewLabelsContainer
    let toggleViewBodyLabelA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.toggleViewBodyLabel
    let closeButtonA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.closeButton
    let closeButtonA11yLabel = String.Menu.EnhancedTrackingProtection.closeButtonAccessibilityLabel
    let faviconImageA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.faviconImage

    var websiteTitle: String {
        return url.baseDomain ?? ""
    }

    let secureStatusString = String.Menu.EnhancedTrackingProtection.connectionSecureLabel
    let unsecureStatusString = String.Menu.EnhancedTrackingProtection.connectionUnsecureLabel
    var connectionStatusString: String {
        return connectionSecure ? secureStatusString : unsecureStatusString
    }

    var connectionDetailsTitle: String {
        if !isProtectionEnabled {
            return .Menu.EnhancedTrackingProtection.offTitle
        }
        if !connectionSecure {
            return .Menu.EnhancedTrackingProtection.onNotSecureTitle
        }
        return String(format: String.Menu.EnhancedTrackingProtection.onTitle, AppName.shortName.rawValue)
    }

    var connectionDetailsHeader: String {
        if !isProtectionEnabled {
            return String(format: .Menu.EnhancedTrackingProtection.offHeader, AppName.shortName.rawValue)
        }
        if !connectionSecure {
            return .Menu.EnhancedTrackingProtection.onNotSecureHeader
        }
        return .Menu.EnhancedTrackingProtection.onHeader
    }

    var isProtectionEnabled = false
    var connectionDetailsImage: UIImage? {
        if !isProtectionEnabled {
            return UIImage(named: ImageIdentifiers.TrackingProtection.protectionOff)
        }
        if !connectionSecure {
            return UIImage(named: ImageIdentifiers.TrackingProtection.protectionAlert)
        }
        return UIImage(named: ImageIdentifiers.TrackingProtection.protectionOn)
    }

    var isSiteETPEnabled: Bool {
        switch contentBlockerStatus {
        case .noBlockedURLs, .blocking, .disabled: return true
        case .safelisted: return false
        }
    }

    // MARK: - Initializers

    init(url: URL,
         displayTitle: String,
         connectionSecure: Bool,
         globalETPIsEnabled: Bool,
         contentBlockerStatus: BlockerStatus,
         contentBlockerStats: TPPageStats?,
         selectedTab: Tab?) {
        self.url = url
        self.displayTitle = displayTitle
        self.connectionSecure = connectionSecure
        self.globalETPIsEnabled = globalETPIsEnabled
        self.contentBlockerStatus = contentBlockerStatus
        self.contentBlockerStats = contentBlockerStats
        self.selectedTab = selectedTab
    }

    // MARK: - Helpers
    func getConnectionDetailsBackgroundColor(theme: Theme) -> UIColor {
        if !isProtectionEnabled {
            return theme.colors.layerAccentPrivateNonOpaque
        }
        if !connectionSecure {
            return theme.colors.layerRatingFSubdued
        }
        return theme.colors.layerAccentPrivateNonOpaque
    }

    func getDetailsModel() -> TrackingProtectionDetailsModel {
        return TrackingProtectionDetailsModel(topLevelDomain: websiteTitle,
                                              title: displayTitle,
                                              URL: url.absoluteDisplayString,
                                              getLockIcon: getConnectionStatusImage(themeType:),
                                              connectionStatusMessage: connectionStatusString,
                                              connectionSecure: connectionSecure,
                                              certificates: certificates)
    }

    func getBlockedTrackersModel() -> BlockedTrackersTableModel {
        return BlockedTrackersTableModel(
            topLevelDomain: websiteTitle,
            title: displayTitle,
            URL: url.absoluteDisplayString,
            contentBlockerStats: contentBlockerStats,
            connectionSecure: connectionSecure
        )
    }

    func getConnectionStatusImage(themeType: ThemeType) -> UIImage {
        let imageName = connectionSecure ? StandardImageIdentifiers.Large.lock : StandardImageIdentifiers.Large.lockSlash
        return UIImage(imageLiteralResourceName: imageName)
            .withRenderingMode(.alwaysTemplate)
    }

    func toggleSiteSafelistStatus() {
        TelemetryWrapper.recordEvent(category: .action, method: .add, object: .trackingProtectionSafelist)
        ContentBlocker.shared.safelist(enable: contentBlockerStatus != .safelisted, url: url) {
        }
    }

    func isURLSafelisted() -> Bool {
        return ContentBlocker.shared.isSafelisted(url: url)
    }

    @MainActor
    func onTapClearCookiesAndSiteData(controller: UIViewController) {
        let alertMessage = String(format: clearCookiesAlertText, url.baseDomain ?? url.shortDisplayString)
        let alert = UIAlertController(
            title: clearCookiesAlertTitle,
            message: alertMessage,
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(title: clearCookiesAlertCancelButton, style: .cancel, handler: nil)
        alert.addAction(cancelAction)

        let confirmAction = UIAlertAction(title: clearCookiesAlertButton,
                                          style: .destructive) { [weak self] _ in
            self?.clearCookiesAndSiteData()
            self?.selectedTab?.webView?.reload()

            guard let windowUUID = self?.selectedTab?.windowUUID else { return }
            store.dispatch(
                TrackingProtectionMiddlewareAction(
                    windowUUID: windowUUID,
                    actionType: TrackingProtectionMiddlewareActionType.dismissTrackingProtection
                )
            )

            store.dispatch(
                GeneralBrowserAction(
                    toastType: .clearCookies,
                    windowUUID: windowUUID,
                    actionType: GeneralBrowserActionType.showToast
                )
            )
        }
        alert.addAction(confirmAction)
        controller.present(alert, animated: true, completion: nil)
    }

    @MainActor
    func clearCookiesAndSiteData() {
        _ = CookiesClearable().clear()
        _ = SiteDataClearable().clear()
    }
}
