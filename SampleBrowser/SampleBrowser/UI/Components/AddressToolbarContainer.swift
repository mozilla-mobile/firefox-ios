// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ToolbarKit
import UIKit

protocol AddressToolbarContainerDelegate: AnyObject {
    func didTapMenu()
}

class AddressToolbarContainer: UIView, ThemeApplicable {
    private enum UX {
        static let toolbarHorizontalPadding: CGFloat = 16
    }

    private lazy var compactToolbar: CompactBrowserAddressToolbar =  .build { _ in }
    private lazy var regularToolbar: RegularBrowserAddressToolbar = .build()

    private var isCompact: Bool {
        traitCollection.horizontalSizeClass == .compact
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ model: AddressToolbarContainerModel,
                   toolbarDelegate: AddressToolbarDelegate) {
        compactToolbar.configure(
            state: model.state,
            toolbarDelegate: toolbarDelegate,
            leadingSpace: calculateToolbarSpace(),
            trailingSpace: calculateToolbarSpace(),
            isUnifiedSearchEnabled: false
        )
        regularToolbar.configure(
            state: model.state,
            toolbarDelegate: toolbarDelegate,
            leadingSpace: calculateToolbarSpace(),
            trailingSpace: calculateToolbarSpace(),
            isUnifiedSearchEnabled: false
        )
    }

    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        let isCompact = traitCollection.horizontalSizeClass == .compact
        let toolbar = isCompact ? compactToolbar : regularToolbar
        return toolbar.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        let isCompact = traitCollection.horizontalSizeClass == .compact
        let toolbar = isCompact ? compactToolbar : regularToolbar
        return toolbar.resignFirstResponder()
    }

    // MARK: View Transitions
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        adjustLayout()
    }

    private func setupLayout() {
        adjustLayout()
    }

    private func adjustLayout() {
        compactToolbar.removeFromSuperview()
        regularToolbar.removeFromSuperview()

        let toolbarToAdd = isCompact ? compactToolbar : regularToolbar

        addSubview(toolbarToAdd)

        NSLayoutConstraint.activate([
            toolbarToAdd.topAnchor.constraint(equalTo: topAnchor),
            toolbarToAdd.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbarToAdd.bottomAnchor.constraint(equalTo: bottomAnchor),
            toolbarToAdd.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    private func calculateToolbarSpace() -> CGFloat {
        // Provide 0 padding in iPhone landscape due to safe area insets
        return isCompact || UIDevice.current.userInterfaceIdiom == .pad ? UX.toolbarHorizontalPadding : 0
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        compactToolbar.applyTheme(theme: theme)
        regularToolbar.applyTheme(theme: theme)
    }
}
