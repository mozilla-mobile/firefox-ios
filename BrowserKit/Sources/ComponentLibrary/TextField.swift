// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

public struct TextFieldViewModel {
    public init(formA11yId: String,
                formA11yLabel: String,
                clearButtonA11yId: String,
                clearButtonA11yLabel: String) {
        self.formA11yId = formA11yId
        self.formA11yLabel = formA11yLabel
        self.clearButtonA11yId = clearButtonA11yId
        self.clearButtonA11yLabel = clearButtonA11yLabel
    }

    public let formA11yId: String
    public let formA11yLabel: String
    public let clearButtonA11yId: String
    public let clearButtonA11yLabel: String
}

public class TextField: UITextField, ThemeApplicable {
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

    public func configure(viewModel: TextFieldViewModel) {
        accessibilityIdentifier = viewModel.formA11yId
        accessibilityLabel = viewModel.formA11yLabel
        clearButton.accessibilityIdentifier = viewModel.clearButtonA11yId
        clearButton.accessibilityLabel = viewModel.clearButtonA11yLabel
    }

    // MARK: - ThemeApplicable

    public func applyTheme(theme: any Theme) {
        tintColor = theme.colors.iconPrimary
    }
}
