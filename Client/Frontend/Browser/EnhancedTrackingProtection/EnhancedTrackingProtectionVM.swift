// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import Storage

class EnhancedTrackingProtectionMenuVM {

    // MARK: - Variables
    var tab: Tab
    var profile: Profile
    var onOpenSettingsTapped: (() -> Void)?
    var heroImage: UIImage?

    var websiteTitle: String {
        return tab.url?.baseDomain ?? ""
    }

    var favIcon: URL? {
        if let icon = tab.displayFavicon, let url = URL(string: icon.url) { return url }
        return nil
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
        return tab.webView?.hasOnlySecureContent ?? false
    }

    var isSiteETPEnabled: Bool {
        guard let blocker = tab.contentBlocker else { return true }

        switch blocker.status {
        case .noBlockedURLs, .blocking, .disabled: return true
        case .safelisted: return false
        }
    }

    var globalETPIsEnabled: Bool {
        return FirefoxTabContentBlocker.isTrackingProtectionEnabled(prefs: profile.prefs)
    }

    // MARK: - Initializers

    init(tab: Tab, profile: Profile) {
        self.tab = tab
        self.profile = profile
    }

    // MARK: - Functions

    func getDetailsViewModel(withCachedImage cachedImage: UIImage?) -> EnhancedTrackingProtectionDetailsVM {
        return EnhancedTrackingProtectionDetailsVM(topLevelDomain: websiteTitle,
                                                   title: tab.displayTitle,
                                                   image: cachedImage,
                                                   URL: tab.url?.absoluteDisplayString ?? websiteTitle,
                                                   getLockIcon: getConnectionStatusImage(themeType:),
                                                   connectionStatusMessage: connectionStatusString,
                                                   connectionSecure: connectionSecure)
    }

    func toggleSiteSafelistStatus() {
        guard let currentURL = tab.url else { return }

        TelemetryWrapper.recordEvent(category: .action, method: .add, object: .trackingProtectionSafelist)
        ContentBlocker.shared.safelist(enable: tab.contentBlocker?.status != .safelisted, url: currentURL) {
            self.tab.reload()
        }
    }
}
