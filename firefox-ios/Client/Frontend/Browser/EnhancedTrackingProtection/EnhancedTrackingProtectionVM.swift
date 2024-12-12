// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

class EnhancedTrackingProtectionMenuVM {
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

    var websiteTitle: String {
        return url.baseDomain ?? ""
    }

    var connectionStatusString: String {
        return connectionSecure ? .ProtectionStatusSecure : .ProtectionStatusNotSecure
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
        ContentBlocker.shared.safelist(enable: contentBlockerStatus != .safelisted, url: url) { [weak self] in
            self?.onToggleSiteSafelistStatus?()
        }
    }
}
