// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Storage

import Security
import CryptoKit
import X509
import SwiftASN1

class TrackingProtectionModel {
    // MARK: - Constants
    let contentBlockerStatus: BlockerStatus
    let contentBlockerStats: TPPageStats?
    var certificates = [Certificate]()
    let url: URL
    let displayTitle: String
    let connectionSecure: Bool
    let globalETPIsEnabled: Bool
    private var selectedTab: Tab?

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
    let trackersBlockedLabelA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.trackersBlockedLabel
    let securityStatusLabelA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.securityStatusLabel
    let toggleViewTitleLabelA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.toggleViewTitleLabel
    let toggleViewBodyLabelA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.toggleViewBodyLabel
    let closeButtonA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.closeButton
    let faviconImageA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.faviconImage

    var websiteTitle: String {
        return url.baseDomain ?? ""
    }

    let secureStatusString = String.Menu.EnhancedTrackingProtection.connectionSecureLabel
    let unsecureStatusString = String.Menu.EnhancedTrackingProtection.connectionUnsecureLabel
    var connectionStatusString: String {
        return connectionSecure ? secureStatusString : unsecureStatusString
    }

    var  connectionDetailsTitle: String {
        let titleOn = String(format: String.Menu.EnhancedTrackingProtection.onTitle, AppName.shortName.rawValue)
        return connectionSecure ? titleOn : .Menu.EnhancedTrackingProtection.offTitle
    }

    let protectionOnHeaderString = String.Menu.EnhancedTrackingProtection.onHeader
    let protectionOffHeaderString = String.Menu.EnhancedTrackingProtection.offHeader
    var  connectionDetailsHeader: String {
        return connectionSecure ? protectionOnHeaderString : protectionOffHeaderString
    }

    let protectionOnImage = UIImage(named: ImageIdentifiers.TrackingProtection.protectionOn)
    let protectionOffImage = UIImage(named: ImageIdentifiers.TrackingProtection.protectionOff)
    var  connectionDetailsImage: UIImage? {
        return connectionSecure ? protectionOnImage : protectionOffImage
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

    func getConnectionStatusImage(themeType: ThemeType) -> UIImage {
        if connectionSecure {
            return UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.lock)
                .withRenderingMode(.alwaysTemplate)
        } else {
            return UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.lockSlash)
        }
    }

    func toggleSiteSafelistStatus() {
        TelemetryWrapper.recordEvent(category: .action, method: .add, object: .trackingProtectionSafelist)
        ContentBlocker.shared.safelist(enable: contentBlockerStatus != .safelisted, url: url) {
        }
    }

    func onTapClearCookiesAndSiteData(controller: UIViewController) {
        let alertMessage = String(format: clearCookiesAlertText, url.absoluteDisplayString)
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
        }
        alert.addAction(confirmAction)
        controller.present(alert, animated: true, completion: nil)
    }

    func clearCookiesAndSiteData() {
        selectedTab?.webView?.reload()
        WebCacheUtils.reset()
    }
}
