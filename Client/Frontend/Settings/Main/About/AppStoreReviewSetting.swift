// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Opens the App Store review page of this app
class AppStoreReviewSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .Settings.About.RateOnAppStore,
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        RatingPromptManager.goToAppStoreReview()
    }
}
