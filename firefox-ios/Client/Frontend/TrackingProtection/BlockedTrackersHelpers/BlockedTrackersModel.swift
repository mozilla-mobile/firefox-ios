// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

struct BlockedTrackersTableModel {
    let topLevelDomain: String
    let title: String
    let URL: String
    var contentBlockerStats: TPPageStats?
    let connectionSecure: Bool

    func getItems() -> [BlockedTrackerItem] {
        let crossSiteCount = String(contentBlockerStats?.getTrackersBlockedForCategory(.advertising) ?? 0)
        let fingerprintersCount = String(contentBlockerStats?.getTrackersBlockedForCategory(.fingerprinting) ?? 0)
        let socialMediaCount = String(contentBlockerStats?.getTrackersBlockedForCategory(.social) ?? 0)
        let trackingContentCount = String(contentBlockerStats?.getTrackersBlockedForCategory(.analytics) ?? 0)

        let crossSiteText = String(format: .Menu.EnhancedTrackingProtection.crossSiteTrackersBlockedLabel,
                                   crossSiteCount)
        let fingerprintersText = String(format: .Menu.EnhancedTrackingProtection.fingerprinterBlockedLabel,
                                        fingerprintersCount)
        let socialMediaText = String(format: .Menu.EnhancedTrackingProtection.socialMediaTrackersBlockedLabel,
                                     socialMediaCount)
        let trackingContentText = String(format: .Menu.EnhancedTrackingProtection.analyticsTrackersBlockedLabel,
                                         trackingContentCount)

        let crossSiteImage = UIImage(
            imageLiteralResourceName: StandardImageIdentifiers.Large.cookies
        ).withRenderingMode(.alwaysTemplate)
        let fingerprintersImage = UIImage(
            imageLiteralResourceName: StandardImageIdentifiers.Large.fingerprinter
        ).withRenderingMode(.alwaysTemplate)
        let socialMediaImage = UIImage(
            imageLiteralResourceName: StandardImageIdentifiers.Large.socialMedia
        ).withRenderingMode(.alwaysTemplate)
        let trackingContentImage = UIImage(
            imageLiteralResourceName: StandardImageIdentifiers.Large.image
        ).withRenderingMode(.alwaysTemplate)

        typealias A11y = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackers

        return [
            BlockedTrackerItem(
                title: crossSiteText,
                image: crossSiteImage,
                titleIdentifier: A11y.crossSiteTitle,
                imageIdentifier: A11y.crossSiteImage
            ),
            BlockedTrackerItem(
                title: fingerprintersText,
                image: fingerprintersImage,
                titleIdentifier: A11y.fingerPrintersTitle,
                imageIdentifier: A11y.fingerPrintersImage
            ),
            BlockedTrackerItem(
                title: trackingContentText,
                image: trackingContentImage,
                titleIdentifier: A11y.trackingContentTitle,
                imageIdentifier: A11y.trackingContentImage
            ),
            BlockedTrackerItem(
                title: socialMediaText,
                image: socialMediaImage,
                titleIdentifier: A11y.socialMediaTitle,
                imageIdentifier: A11y.socialMediaImage
            )
        ]
    }

    func getTotalTrackersText() -> String {
        let totalTrackerBlocked = String(contentBlockerStats?.total ?? 0)
        let trackersText = String(format: .Menu.EnhancedTrackingProtection.trackersBlockedLabel,
                                  totalTrackerBlocked)
        return trackersText.uppercased()
    }
}
