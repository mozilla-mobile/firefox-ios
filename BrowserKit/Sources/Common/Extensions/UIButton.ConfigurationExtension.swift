// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UIButton.Configuration {
    /// Helper function to set a button's font through UIButton.Configuration using `titleTextAttributesTransformer`.
    ///
    /// - Parameter font: The new button title font.
    ///
    /// - Note: This extension is only temporary to avoid code duplication until all buttons are setup to use
    ///         button components (`PrimaryRoundedButton`, `SecondaryRoundedButton` or `LinkButton`). Once
    ///         this migration is done, this extension should be removed.
    ///         See [this thread](https://github.com/mozilla-mobile/firefox-ios/pull/17616#discussion_r1415780465)
    ///         for more details.
    public mutating func setFont(_ font: UIFont) {
        titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = font
            return outgoing
        }
    }
}
