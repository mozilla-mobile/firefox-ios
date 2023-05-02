// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared

class ToolbarTextField: AutocompleteTextField {
    // MARK: - Variables
    @objc dynamic var clearButtonTintColor: UIColor? {
        didSet {
            // Clear previous tinted image that's cache and ask for a relayout
            tintedClearImage = nil
            setNeedsLayout()
        }
    }

    private var tintedClearImage: UIImage?

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let image = UIImage.templateImageNamed("topTabs-closeTabs") else { return }
        if tintedClearImage == nil {
            if let clearButtonTintColor = clearButtonTintColor {
                tintedClearImage = image.tinted(withColor: clearButtonTintColor)
            } else {
                tintedClearImage = image
            }
        }
        // Since we're unable to change the tint color of the clear image, we need to iterate through the
        // subviews, find the clear button, and tint it ourselves.
        // https://stackoverflow.com/questions/55046917/clear-button-on-text-field-not-accessible-with-voice-over-swift
        if let clearButton = value(forKey: "_clearButton") as? UIButton {
            clearButton.setImage(tintedClearImage, for: [])
        }
    }

    // The default button size is 19x19, make this larger
    override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.clearButtonRect(forBounds: bounds)
        let grow: CGFloat = 16
        let rect2 = CGRect(x: rect.minX - grow/2,
                           y: rect.minY - grow/2,
                           width: rect.width + grow,
                           height: rect.height + grow)
        return rect2
    }
}

// MARK: - Theme protocols
extension ToolbarTextField: ThemeApplicable {
    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer3
        textColor = theme.colors.textSecondary
        clearButtonTintColor = textColor
        tintColor = AutocompleteTextField.textSelectionColor.textFieldMode
        self.refreshAutocompleteLabelTheme()
    }

    // ToolbarTextField is created on-demand, so the textSelectionColor is a static prop for use when created
    static func applyUIMode(isPrivate: Bool) {
        textSelectionColor = UIColor.legacyTheme.urlbar.textSelectionHighlight(isPrivate)
    }
}

// MARK: - Key commands

extension ToolbarTextField {
    override var keyCommands: [UIKeyCommand]? {
        let commands = [
            UIKeyCommand(action: #selector(handleKeyboardArrowKey(sender:)),
                         input: UIKeyCommand.inputRightArrow),
            UIKeyCommand(action: #selector(handleKeyboardArrowKey(sender:)),
                         input: UIKeyCommand.inputLeftArrow),
        ]
        return commands
    }

    @objc
    private func handleKeyboardArrowKey(sender: UIKeyCommand) {
        self.selectedTextRange = nil
    }
}
