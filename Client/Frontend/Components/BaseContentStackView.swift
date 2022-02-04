// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol AlphaDimmable {
    func updateAlphaForSubviews(_ alpha: CGFloat)
}

class BaseAlphaStackView: UIStackView, AlphaDimmable {

    override init(frame: CGRect) {
        super.init(frame: frame)

        applyTheme()
        setupStyle()
        setupObservers()
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
        distribution = .fillProportionally
    }

    // MARK: - Spacer view

    private var keyboardSpacer: UIView?

    func addSpacer(at index: Int, spacerHeight: CGFloat) {
        guard keyboardSpacer == nil else { return }

        keyboardSpacer = UIView()
        keyboardSpacer?.backgroundColor = .clear
        keyboardSpacer!.snp.makeConstraints { make in
            make.height.equalTo(spacerHeight)
        }
        insertArrangedView(keyboardSpacer!, position: 1)
    }

    func removeSpacer() {
        guard let keyboardSpacer = self.keyboardSpacer else { return }
        removeArrangedView(keyboardSpacer)
        self.keyboardSpacer = nil
    }

    // MARK: - NotificationThemeable

    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotifications), name: .DisplayThemeChanged, object: nil)
    }

    @objc private func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
}

extension BaseAlphaStackView: NotificationThemeable {
    func applyTheme() {
        backgroundColor = UIColor.theme.browser.background
    }
}
