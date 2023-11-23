// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UIFont {
    /** Returns a font to be used for a button in a navigation bar.
     *
     * Note: the font does *not* scale for different dynamic type settings.
     */
    static var navigationButtonFont: UIFont {
        return self.preferredFont(forTextStyle: .body,
                                  compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))
    }

    /** Returns a font to be used for a title in a navigation bar.
     *
     * Note: the font does *not* scale for different dynamic type settings.
     */
    static var navigationTitleFont: UIFont {
        return self.preferredFont(forTextStyle: .headline,
                                  compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))
    }
}
