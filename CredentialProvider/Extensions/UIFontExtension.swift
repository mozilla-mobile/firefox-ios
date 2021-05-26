//
//  UIFontExtension.swift
//  CredentialProvider
//
//  Created by raluca.iordan on 5/18/21.
//  Copyright © 2021 Mozilla. All rights reserved.
//

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
