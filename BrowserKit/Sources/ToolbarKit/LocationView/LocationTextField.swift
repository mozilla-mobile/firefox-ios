// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class LocationTextField: UITextField, ThemeApplicable {
    private var tintedClearImage: UIImage?
    private var clearButtonTintColor: UIColor?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: .zero)
        clearButtonMode = .whileEditing
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    weak var accessibilityActionsSource: AccessibilityActionsSource?

    override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            return accessibilityActionsSource?.accessibilityCustomActionsForView(self)
        }
        set {
            super.accessibilityCustomActions = newValue
        }
    }

    // MARK: - View setup
    override func layoutSubviews() {
        super.layoutSubviews()

        guard let image = UIImage(named: StandardImageIdentifiers.Large.crossCircleFill) else { return }
        if tintedClearImage == nil {
            if let clearButtonTintColor {
                tintedClearImage = image.withTintColor(clearButtonTintColor)
            }
        }

        // Since we're unable to change the tint color of the clear image, we need to iterate through the
        // subviews, find the clear button, and tint it ourselves.
        // https://stackoverflow.com/questions/55046917/clear-button-on-text-field-not-accessible-with-voice-over-swift
        if let clearButton = value(forKey: "_clearButton") as? UIButton {
            clearButton.setImage(tintedClearImage, for: [])
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        let colors = theme.colors
        clearButtonTintColor = colors.iconPrimary
        textColor = colors.textPrimary
    }
}
