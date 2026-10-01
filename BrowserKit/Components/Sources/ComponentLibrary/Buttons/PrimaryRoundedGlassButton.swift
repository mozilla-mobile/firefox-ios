// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public final class PrimaryRoundedGlassButton: PrimaryRoundedButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        if #available(iOS 26.0, *) {
            configuration = .prominentGlass()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: ThemeApplicable

    override public func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)
        foregroundColor = .invertedLabel
        setNeedsUpdateConfiguration()
    }
}
