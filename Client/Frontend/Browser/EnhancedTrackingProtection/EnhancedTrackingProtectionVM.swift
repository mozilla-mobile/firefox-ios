/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage

class EnhancedTrackingProtectionMenuVM {

    // MARK: - Variables

    var tab: Tab
    var profile: Profile

    var websiteTitle: String {
        return tab.url?.baseDomain ?? ""
    }

//            let trackingProtectionMenu = self.getTrackingSubMenu(for: tab)
    var favIcon: URL? {
        if let icon = tab.displayFavicon, let url = URL(string: icon.url) { return url }
        return nil
    }

    var connectionStatusString: String {
        return connectionSecure ? .ProtectionStatusSheetConnectionSecure : .ProtectionStatusSheetConnectionInsecure
    }

    var connectionStatusImage: UIImage {
        let insecureImageString = ThemeManager.instance.currentName == .dark ? "lock_blocked_dark" : "lock_blocked"
        let image = connectionSecure ? UIImage(imageLiteralResourceName: "lock_verified").withRenderingMode(.alwaysTemplate) : UIImage(imageLiteralResourceName: insecureImageString)
        return image
    }

    var connectionSecure: Bool {
        return tab.webView?.hasOnlySecureContent ?? false
    }

    var isETPEnabled: Bool {
        return FirefoxTabContentBlocker.isTrackingProtectionEnabled(prefs: profile.prefs)
    }

    // MARK: - Initializers

    init(tab: Tab, profile: Profile) {
        self.tab = tab
        self.profile = profile
    }

    deinit {
        print("ROUX - VM out")
    }

    // MARK: - Functions

    func getDetailsViewModel(withCachedImage cachedImage: UIImage?) -> EnhancedTrackingProtectionDetailsVM {
        return EnhancedTrackingProtectionDetailsVM(topLevelDomain: websiteTitle,
                                                   title: tab.displayTitle,
                                                   image: cachedImage ?? UIImage(imageLiteralResourceName: "defaulFavicon"),
                                                   URL: tab.url?.absoluteDisplayString ?? websiteTitle,
                                                   lockIcon: connectionStatusImage,
                                                   connectionStatusMessage: connectionStatusString,
                                                   connectionVerifier: "Test verifier",
                                                   connectionSecure: connectionSecure)
    }

    func setTracking(to status: Bool) {
        FirefoxTabContentBlocker.setTrackingProtection(enabled: status, prefs: profile.prefs)
        tab.reload()
    }
}
