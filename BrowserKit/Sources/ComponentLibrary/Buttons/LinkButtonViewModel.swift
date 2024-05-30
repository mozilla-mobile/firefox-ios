// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Foundation
import Common

/// The view model used to configure a `LinkButton`
public struct LinkButtonViewModel {
    public struct UX {
        public static let verticalInset: CGFloat = 12
        public static let horizontalInset: CGFloat = 16
    }

    public let title: String
    public let a11yIdentifier: String
    public let font: UIFont
    public let contentInsets: NSDirectionalEdgeInsets
    public let contentHorizontalAlignment: UIControl.ContentHorizontalAlignment

    public init(title: String,
                a11yIdentifier: String,
                font: UIFont = FXFontStyles.Regular.callout.scaledFont(),
                contentInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: UX.verticalInset,
                                                                                 leading: UX.horizontalInset,
                                                                                 bottom: UX.verticalInset,
                                                                                 trailing: UX.horizontalInset),
                contentHorizontalAlignment: UIControl.ContentHorizontalAlignment = .leading) {
        self.title = title
        self.a11yIdentifier = a11yIdentifier
        self.font = font
        self.contentInsets = contentInsets
        self.contentHorizontalAlignment = contentHorizontalAlignment
    }
}
