// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ToolbarKit
import UIKit

protocol AddressToolbarContainerDelegate: AnyObject {
    func didClickMenu()
}

class AddressToolbarContainer: UIView, ThemeApplicable {
    private lazy var compactToolbar: CompactBrowserAddressToolbar =  .build { _ in }
    private lazy var regularToolbar: BrowserAddressToolbar = .build()

    private var addressToolbarModel: AddressToolbarModel?
    private weak var delegate: AddressToolbarContainerDelegate?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(url: String?,
                   toolbarDelegate: AddressToolbarDelegate,
                   toolbarContainerDelegate: AddressToolbarContainerDelegate) {
        addressToolbarModel = updateModel(url: url)
        guard let addressToolbarModel else { return }

        compactToolbar.configure(state: addressToolbarModel.state, toolbarDelegate: toolbarDelegate)
        regularToolbar.configure(state: addressToolbarModel.state, toolbarDelegate: toolbarDelegate)
        delegate = toolbarContainerDelegate
    }

    override func becomeFirstResponder() -> Bool {
        let isCompact = traitCollection.horizontalSizeClass == .compact
        let toolbar = isCompact ? compactToolbar : regularToolbar
        return toolbar.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
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

        let isCompact = traitCollection.horizontalSizeClass == .compact
        let toolbarToAdd = isCompact ? compactToolbar : regularToolbar

        addSubview(toolbarToAdd)

        NSLayoutConstraint.activate([
            toolbarToAdd.topAnchor.constraint(equalTo: topAnchor),
            toolbarToAdd.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbarToAdd.bottomAnchor.constraint(equalTo: bottomAnchor),
            toolbarToAdd.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    private func updateModel(url: String?) -> AddressToolbarModel {
        let pageActions = [ToolbarElement(
            iconName: StandardImageIdentifiers.Large.qrCode,
            isEnabled: true,
            a11yLabel: "Read QR Code",
            a11yId: "qrCodeButton",
            onSelected: nil)]

        let browserActions = [ToolbarElement(
            iconName: StandardImageIdentifiers.Large.appMenu,
            isEnabled: true,
            a11yLabel: "Open Menu",
            a11yId: "appMenuButton",
            onSelected: {
                self.delegate?.didClickMenu()
            })]

        return AddressToolbarModel(
            url: url,
            navigationActions: [],
            pageActions: pageActions,
            browserActions: browserActions)
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        compactToolbar.applyTheme(theme: theme)
        regularToolbar.applyTheme(theme: theme)
    }
}
