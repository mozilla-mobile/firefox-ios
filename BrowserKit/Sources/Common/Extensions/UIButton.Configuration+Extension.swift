// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UIButton.Configuration {
    /// Helper function to set a button's font through UIButton.Configuration using `titleTextAttributesTransformer`.
    ///
    /// - Parameter font: The new button title font.
    public mutating func setFont(_ font: UIFont) {
        titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = font
            return outgoing
        }
    }
}
