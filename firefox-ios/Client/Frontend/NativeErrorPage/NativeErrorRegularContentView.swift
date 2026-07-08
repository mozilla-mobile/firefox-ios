// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary
import Shared

@MainActor
protocol NativeErrorRegularContentViewDelegate: AnyObject {
    func regularContentViewDidTapReload()
    func regularContentViewDidTapSearchWayback()
}

/// Encapsulates the "no internet / generic error" action area: a reload button,
/// and optionally a secondary "search wayback" button.
/// The parent view controller swaps this view in when the error is *not* a bad-cert error.
final class NativeErrorRegularContentView: UIView, ThemeApplicable {
    weak var delegate: NativeErrorRegularContentViewDelegate?

    private lazy var reloadButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapReload), for: .touchUpInside)
        button.isEnabled = true
    }

    private lazy var waybackButton: SecondaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapWayback), for: .touchUpInside)
        button.isEnabled = true
    }

    private lazy var buttonStack: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = 8
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        buttonStack.addArrangedSubview(reloadButton)
        buttonStack.addArrangedSubview(waybackButton)
        addSubview(buttonStack)
        NSLayoutConstraint.activate([
            buttonStack.topAnchor.constraint(equalTo: topAnchor),
            buttonStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(showWaybackButton: Bool = false) {
        let viewModel = PrimaryRoundedButtonViewModel(
            title: .NativeErrorPage.ButtonLabel,
            a11yIdentifier: AccessibilityIdentifiers.NativeErrorPage.reloadButton
        )
        reloadButton.configure(viewModel: viewModel)

        waybackButton.isHidden = !showWaybackButton
        configureWaybackButton(isLoading: false)
    }

    func configureWaybackButton(isLoading: Bool) {
        let title = isLoading
            ? String.NativeErrorPage.Wayback.CheckingLabel
            : String.NativeErrorPage.Wayback.SearchLabel
        let viewModel = SecondaryRoundedButtonViewModel(
            title: title,
            a11yIdentifier: AccessibilityIdentifiers.NativeErrorPage.waybackButton
        )
        waybackButton.configure(viewModel: viewModel)
        waybackButton.isEnabled = !isLoading
    }

    @objc
    private func didTapReload() {
        delegate?.regularContentViewDidTapReload()
    }

    @objc
    private func didTapWayback() {
        delegate?.regularContentViewDidTapSearchWayback()
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        reloadButton.applyTheme(theme: theme)
        waybackButton.applyTheme(theme: theme)
    }
}
