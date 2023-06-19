// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Storage

class EnhancedTrackingProtectionMenuVM {
    // MARK: - Variables
    var profile: Profile
    var onOpenSettingsTapped: (() -> Void)?
    var onToggleSiteSafelistStatus: (() -> Void)?
    var heroImage: UIImage?

    ///
    let contentBlocker: FirefoxTabContentBlocker
    let url: URL
    let displayTitle: String
    let connectionSecure: Bool
    ///

    var websiteTitle: String {
        return url.baseDomain ?? ""
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

    var isSiteETPEnabled: Bool {
        switch contentBlocker.status {
        case .noBlockedURLs, .blocking, .disabled: return true
        case .safelisted: return false
        }
    }

    var globalETPIsEnabled: Bool {
        return FirefoxTabContentBlocker.isTrackingProtectionEnabled(prefs: profile.prefs)
    }

    // MARK: - Initializers

    init(url: URL, displayTitle: String, connectionSecure: Bool, contentBlocker: FirefoxTabContentBlocker, profile: Profile) {
        self.url = url
        self.displayTitle = displayTitle
        self.connectionSecure = connectionSecure
        self.contentBlocker = contentBlocker
        self.profile = profile
    }

    // MARK: - Functions

    func getDetailsViewModel() -> EnhancedTrackingProtectionDetailsVM {
        return EnhancedTrackingProtectionDetailsVM(topLevelDomain: websiteTitle,
                                                   title: displayTitle,
                                                   URL: url.absoluteDisplayString,
                                                   getLockIcon: getConnectionStatusImage(themeType:),
                                                   connectionStatusMessage: connectionStatusString,
                                                   connectionSecure: connectionSecure)
    }

    func toggleSiteSafelistStatus() {
        TelemetryWrapper.recordEvent(category: .action, method: .add, object: .trackingProtectionSafelist)
        ContentBlocker.shared.safelist(enable: contentBlocker.status != .safelisted, url: url) { [weak self] in
            self?.onToggleSiteSafelistStatus?()
        }
    }
}
