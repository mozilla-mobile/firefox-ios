// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import SnapKit
import Shared

protocol AlphaDimmable {
    func updateAlphaForSubviews(_ alpha: CGFloat)
}

class BaseAlphaStackView: UIStackView, AlphaDimmable, ThemeApplicable {
    var isClearBackground = false
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

    private var keyboardSpacerHeight: Constraint!
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
        keyboardSpacer.snp.remakeConstraints { remake in
            keyboardSpacerHeight = remake.height.equalTo(height).constraint
        }
    }

    // MARK: - Spacer view

    private var insetSpacer: UIView?

    func addBottomInsetSpacer(spacerHeight: CGFloat) {
        guard insetSpacer == nil else { return }

        insetSpacer = UIView()
        insetSpacer!.snp.makeConstraints { make in
            make.height.equalTo(spacerHeight)
        }
        addArrangedViewToBottom(insetSpacer!)
    }

    func removeBottomInsetSpacer() {
        guard let insetSpacer = self.insetSpacer else { return }

        removeArrangedView(insetSpacer)
        self.insetSpacer = nil
        self.layoutIfNeeded()
    }

    func applyTheme(theme: Theme) {
        let color = isClearBackground ? .clear : theme.colors.layer1
        backgroundColor = color
        keyboardSpacer?.backgroundColor = color
        insetSpacer?.backgroundColor = color
    }
}
