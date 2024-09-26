// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

public class DefaultTextField: UITextField, ThemeApplicable {
    override init(frame: CGRect) {
        super.init(frame: frame)
        clearButtonMode = .whileEditing
        font = UIFont.preferredFont(forTextStyle: .body)
        let buttonImage = UIImage(named: StandardImageIdentifiers.Large.crossCircleFill)?.withRenderingMode(.alwaysTemplate)
        clearButton?.setImage(buttonImage, for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var clearButton: UIButton? {
        return value(forKey: "clearButton") as? UIButton
    }

    // MARK: - ThemeApplicable

    public func applyTheme(theme: any Theme) {
        tintColor = theme.colors.iconPrimary
    }
}
