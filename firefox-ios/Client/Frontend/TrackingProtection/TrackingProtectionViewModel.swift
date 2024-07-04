// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Storage

class TrackingProtectionViewModel {
    // MARK: - Variables
    var onOpenSettingsTapped: (() -> Void)?
    var onToggleSiteSafelistStatus: (() -> Void)?
    var heroImage: UIImage?

    // MARK: - Constants
    let contentBlockerStatus: BlockerStatus
    let url: URL
    let displayTitle: String
    let connectionSecure: Bool
    let globalETPIsEnabled: Bool
    var trackersBlocked: String {
        return "5" // for testing
    }

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

    var connectionStatusString: String {
        return connectionSecure ?
            .Menu.EnhancedTrackingProtection.connectionSecureLabel :
            .Menu.EnhancedTrackingProtection.connectionUnsecureLabel
    }

    var  connectionDetailsTitle: String {
        let titleOn = String(format: String.Menu.EnhancedTrackingProtection.onTitle, AppName.shortName.rawValue)
        return connectionSecure ? titleOn : .Menu.EnhancedTrackingProtection.offTitle
    }

    var  connectionDetailsHeader: String {
        return connectionSecure ?
            .Menu.EnhancedTrackingProtection.onHeader : .Menu.EnhancedTrackingProtection.offHeader
    }

    var  connectionDetailsImage: UIImage? {
        return connectionSecure ?
        UIImage(named: ImageIdentifiers.TrackingProtection.protectionOn) :
        UIImage(named: ImageIdentifiers.TrackingProtection.protectionOff)
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
         contentBlockerStatus: BlockerStatus) {
        self.url = url
        self.displayTitle = displayTitle
        self.connectionSecure = connectionSecure
        self.globalETPIsEnabled = globalETPIsEnabled
        self.contentBlockerStatus = contentBlockerStatus
    }

    // MARK: - Functions

    func getConnectionStatusImage(themeType: ThemeType) -> UIImage {
        if connectionSecure {
            return UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.lock)
                .withRenderingMode(.alwaysTemplate)
        } else {
            return UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.lockSlash)
        }
    }

    func getDetailsViewModel() -> TrackingProtectionDetailsViewModel {
        return TrackingProtectionDetailsViewModel(topLevelDomain: websiteTitle,
                                                  title: displayTitle,
                                                  URL: url.absoluteDisplayString,
                                                  getLockIcon: getConnectionStatusImage(themeType:),
                                                  connectionStatusMessage: connectionStatusString,
                                                  connectionSecure: connectionSecure)
    }

    func getBlockedTrackersViewModel() -> BlockedTrackersViewModel {
        return BlockedTrackersViewModel(topLevelDomain: websiteTitle,
                                        title: displayTitle,
                                        URL: url.absoluteDisplayString,
                                        getLockIcon: getConnectionStatusImage(themeType:),
                                        connectionStatusMessage: connectionStatusString,
                                        connectionSecure: connectionSecure)
    }

    func toggleSiteSafelistStatus() {
        TelemetryWrapper.recordEvent(category: .action, method: .add, object: .trackingProtectionSafelist)
        ContentBlocker.shared.safelist(enable: contentBlockerStatus != .safelisted, url: url) { [weak self] in
            self?.onToggleSiteSafelistStatus?()
        }
    }

    func onTapClearCookiesAndSiteData(controller: UIViewController) {
        let alertMessage = String(format: clearCookiesAlertText, url.absoluteDisplayString)
        let alert = UIAlertController(
            title: clearCookiesAlertTitle,
            message: alertMessage,
            preferredStyle: .alert
        )

        // Add the Cancel action
        let cancelAction = UIAlertAction(title: clearCookiesAlertCancelButton, style: .cancel, handler: nil)
        alert.addAction(cancelAction)

        // Add the Confirm action
        let confirmAction = UIAlertAction(title: clearCookiesAlertButton, style: .destructive) { _ in
            self.clearCookiesAndSiteData()
        }
        alert.addAction(confirmAction)

        // Present the alert
        controller.present(alert, animated: true, completion: nil)
    }

    func clearCookiesAndSiteData() {
    }
}
