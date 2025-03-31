// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

protocol AlphaDimmable {
    func updateAlphaForSubviews(_ alpha: CGFloat)
}

class BaseAlphaStackView: UIStackView, AlphaDimmable, ThemeApplicable {
    var isClearBackground = false
    private var toolbarLayoutType: ToolbarLayoutType? {
        return FxNimbus.shared.features.toolbarRefactorFeature.value().layout
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupStyle()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateAlphaForSubviews(_ alpha: CGFloat) {
        for subview in arrangedSubviews {
            guard let alphaView = subview as? AlphaDimmable else { continue }
            alphaView.updateAlphaForSubviews(alpha)
        }
    }

    private func setupStyle() {
        axis = .vertical
        distribution = .fill
        alignment = .fill
    }

    // MARK: - Spacer view

    private var keyboardSpacerHeight: NSLayoutConstraint?
    private var keyboardSpacer: UIView?

    func addKeyboardSpacer(spacerHeight: CGFloat) {
        keyboardSpacer?.removeFromSuperview()
        if keyboardSpacer == nil {
            keyboardSpacer = UIView()
        }
        addArrangedViewToBottom(keyboardSpacer!)
        setKeyboardSpacerHeight(height: spacerHeight)
    }

    func removeKeyboardSpacer() {
        guard let keyboardSpacer = self.keyboardSpacer else { return }
        removeArrangedView(keyboardSpacer)
        keyboardSpacerHeight = nil
        self.keyboardSpacer = nil
    }

    private func setKeyboardSpacerHeight(height: CGFloat) {
        guard let keyboardSpacer = self.keyboardSpacer else { return }
        keyboardSpacer.translatesAutoresizingMaskIntoConstraints = false
        // Remove any existing height constraint on keyboardSpacer
        if let existingHeightConstraint = keyboardSpacer.constraints.first(where: {
            $0.firstAttribute == .height && $0.secondItem == nil
        }) {
            keyboardSpacer.removeConstraint(existingHeightConstraint)
        }

        // Create and add the new height constraint
        let heightConstraint = NSLayoutConstraint(item: keyboardSpacer,
                                                  attribute: .height,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1.0,
                                                  constant: height)
        keyboardSpacer.addConstraint(heightConstraint)
        keyboardSpacerHeight = heightConstraint
    }

    // MARK: - Spacer view

    private var insetSpacer: UIView?

    func addBottomInsetSpacer(spacerHeight: CGFloat) {
        guard insetSpacer == nil else { return }

        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        addArrangedViewToBottom(spacer)
        NSLayoutConstraint.activate([
            spacer.heightAnchor.constraint(equalToConstant: spacerHeight),
            spacer.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            spacer.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            spacer.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        insetSpacer = spacer
        layoutIfNeeded()
    }

    func removeBottomInsetSpacer() {
        guard let insetSpacer = self.insetSpacer else { return }

        removeArrangedView(insetSpacer)
        self.insetSpacer = nil
        layoutIfNeeded()
    }

    func applyTheme(theme: Theme) {
        let color: UIColor = if isClearBackground {
            .clear
        } else {
            toolbarLayoutType == .version1 ? theme.colors.layer3 : theme.colors.layer1
        }
        backgroundColor = color
        keyboardSpacer?.backgroundColor = color
        insetSpacer?.backgroundColor = color
    }
}
