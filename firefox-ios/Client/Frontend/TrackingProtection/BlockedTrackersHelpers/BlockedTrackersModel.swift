// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

struct BlockedTrackersTableModel {
    let topLevelDomain: String
    let title: String
    let URL: String
    let contentBlockerStats: TPPageStats?
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
            imageLiteralResourceName: StandardImageIdentifiers.Large.socialTracker
        ).withRenderingMode(.alwaysTemplate)
        let trackingContentImage = UIImage(
            imageLiteralResourceName: StandardImageIdentifiers.Large.image
        ).withRenderingMode(.alwaysTemplate)

        return [
            BlockedTrackerItem(
                title: crossSiteText,
                image: crossSiteImage
            ),
            BlockedTrackerItem(
                title: fingerprintersText,
                image: fingerprintersImage
            ),
            BlockedTrackerItem(
                title: trackingContentText,
                image: trackingContentImage
            ),
            BlockedTrackerItem(
                title: socialMediaText,
                image: socialMediaImage
            )
        ]
    }

    func getTotalTrackersText() -> String {
        let totalTrackerBlocked = String(contentBlockerStats?.total ?? 0)
        let trackersText = String(format: .Menu.EnhancedTrackingProtection.trackersBlockedLabel,
                                  totalTrackerBlocked)
        return trackersText
    }
}
