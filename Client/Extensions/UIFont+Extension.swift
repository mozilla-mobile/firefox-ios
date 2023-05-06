// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit.UIFont

extension UIFont {
    /// Returns the font, with the added bold attribute
    func bolded() -> UIFont? {
        return add(trait: .traitBold)
    }

    /// Returns the font, with the added italics attribute
    func italicized() -> UIFont? {
        return add(trait: .traitItalic)
    }

    private func add(trait: UIFontDescriptor.SymbolicTraits) -> UIFont? {
        guard let descriptor = fontDescriptor
            .withSymbolicTraits(fontDescriptor.symbolicTraits.union(trait))
        else { return nil }

        return UIFont(descriptor: descriptor, size: 0)
    }
}
