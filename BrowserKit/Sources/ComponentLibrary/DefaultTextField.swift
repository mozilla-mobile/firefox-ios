// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

public class DefaultTextField: UITextField, ThemeApplicable {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var clearButton: UIButton = .build { view in
        let buttonImage = UIImage(named: StandardImageIdentifiers.Large.crossCircleFill)?.withRenderingMode(.alwaysTemplate)
        view.setImage(buttonImage, for: .normal)
    }

    private func setup() {
        clearButtonMode = .never
        adjustsFontForContentSizeCategory = true
        font = FXFontStyles.Regular.body.scaledFont()
        rightView = clearButton
        rightViewMode = .whileEditing
        showsLargeContentViewer = true
        isAccessibilityElement = true
        clearButton.adjustsImageSizeForAccessibilityContentSizeCategory = true
        clearButton.addAction(UIAction(handler: { [weak self] _ in
            self?.text = ""
            self?.sendActions(for: .valueChanged)
        }), for: .touchUpInside)
    }

    // MARK: - ThemeApplicable

    public func applyTheme(theme: any Theme) {
        tintColor = theme.colors.iconPrimary
    }
}
