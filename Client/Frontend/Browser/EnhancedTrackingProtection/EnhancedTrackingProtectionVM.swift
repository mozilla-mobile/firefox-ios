// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Storage

class EnhancedTrackingProtectionMenuVM {
    // MARK: - Variables
    var tab: Tab?
    var profile: Profile
    var onOpenSettingsTapped: (() -> Void)?
    var onToggleSiteSafelistStatus: (() -> Void)?
    var heroImage: UIImage?

    // MARK: - Constants
    let contentBlockerStatus: BlockerStatus
    let url: URL
    let displayTitle: String
    let connectionSecure: Bool
    let globalETPIsEnabled: Bool

    var websiteTitle: String {
        return tab?.url?.baseDomain ?? ""
    }

    var connectionStatusString: String {
        return connectionSecure ? .ProtectionStatusSecure : .ProtectionStatusNotSecure
    }

    func getConnectionStatusImage(themeType: ThemeType) -> UIImage {
        let insecureImageName = themeType.getThemedImageName(name: ImageIdentifiers.lockBlocked)
        if connectionSecure {
            return UIImage(imageLiteralResourceName: ImageIdentifiers.lockVerifed).withRenderingMode(.alwaysTemplate)
        } else {
            return UIImage(imageLiteralResourceName: insecureImageName)
        }
    }

    var connectionSecure: Bool {
        return tab?.webView?.hasOnlySecureContent ?? false
    }

    var isSiteETPEnabled: Bool {
        guard let blocker = tab?.contentBlocker else { return true }

        switch blocker.status {
        case .noBlockedURLs, .blocking, .disabled: return true
        case .safelisted: return false
        }
    }

    // MARK: - Initializers

    init(tab: Tab?, profile: Profile) {
        self.tab = tab
        self.profile = profile
    }

    // MARK: - Functions

    func getConnectionStatusImage(themeType: ThemeType) -> UIImage {
        let insecureImageName = themeType.getThemedImageName(name: ImageIdentifiers.lockBlocked)
        if connectionSecure {
            return UIImage(imageLiteralResourceName: ImageIdentifiers.lockVerifed).withRenderingMode(.alwaysTemplate)
        } else {
            return UIImage(imageLiteralResourceName: insecureImageName)
        }
    }

    func getDetailsViewModel() -> EnhancedTrackingProtectionDetailsVM {
        return EnhancedTrackingProtectionDetailsVM(topLevelDomain: websiteTitle,
                                                   title: tab?.displayTitle ?? "",
                                                   URL: tab?.url?.absoluteDisplayString ?? websiteTitle,
                                                   getLockIcon: getConnectionStatusImage(themeType:),
                                                   connectionStatusMessage: connectionStatusString,
                                                   connectionSecure: connectionSecure)
    }

    func toggleSiteSafelistStatus() {
        guard let currentURL = tab?.url else { return }

        TelemetryWrapper.recordEvent(category: .action, method: .add, object: .trackingProtectionSafelist)
        ContentBlocker.shared.safelist(enable: tab?.contentBlocker?.status != .safelisted, url: currentURL) {
            self.tab?.reload()
        }
    }
}
