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

enum WaybackButtonState: Equatable {
    case idle
    case loading
    case failed
}

/// Encapsulates the "no internet / generic error" action area: a reload button,
/// and optionally a secondary wayback area (button, loading state, or a failure card).
final class NativeErrorRegularContentView: UIView, ThemeApplicable {
    private struct UX {
        static let cardCornerRadius: CGFloat = 12
        static let cardInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        static let cardTopSpacing: CGFloat = 8
    }

    weak var delegate: NativeErrorRegularContentViewDelegate?

    private lazy var reloadButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapReload), for: .touchUpInside)
        button.isEnabled = true
    }

    private lazy var waybackButton: SecondaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapWayback), for: .touchUpInside)
        button.isEnabled = true
    }

    private lazy var waybackErrorIcon: UIImageView = .build { imageView in
        // TODO: swap for a real asset once design provides one.
        imageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .horizontal)
    }

    private lazy var waybackErrorLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.numberOfLines = 0
        label.text = .NativeErrorPage.Wayback.CouldNotReachLabel
    }

    private lazy var waybackErrorMessageRow: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 6
    }

    private lazy var waybackRetryButton: UIButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapWayback), for: .touchUpInside)
        button.contentHorizontalAlignment = .leading
    }

    private lazy var waybackErrorContentStack: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 2
    }

    /// Card container that gives the failure state a distinct background,
    /// matching the visual weight of the buttons above it.
    private lazy var waybackErrorCard: UIView = .build { view in
        view.layer.cornerRadius = UX.cardCornerRadius
        view.isHidden = true
    }

    private lazy var buttonStack: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = 8
    }

    private var waybackState: WaybackButtonState = .idle
    private var showsWayback = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        waybackErrorMessageRow.addArrangedSubview(waybackErrorIcon)
        waybackErrorMessageRow.addArrangedSubview(waybackErrorLabel)
        waybackErrorContentStack.addArrangedSubview(waybackErrorMessageRow)
        waybackErrorContentStack.addArrangedSubview(waybackRetryButton)

        waybackErrorCard.addSubview(waybackErrorContentStack)
        NSLayoutConstraint.activate([
            waybackErrorContentStack.topAnchor.constraint(
                equalTo: waybackErrorCard.topAnchor, constant: UX.cardInsets.top
            ),
            waybackErrorContentStack.leadingAnchor.constraint(
                equalTo: waybackErrorCard.leadingAnchor, constant: UX.cardInsets.leading
            ),
            waybackErrorContentStack.trailingAnchor.constraint(
                equalTo: waybackErrorCard.trailingAnchor, constant: -UX.cardInsets.trailing
            ),
            waybackErrorContentStack.bottomAnchor.constraint(
                equalTo: waybackErrorCard.bottomAnchor, constant: -UX.cardInsets.bottom
            )
        ])

        buttonStack.addArrangedSubview(reloadButton)
        buttonStack.addArrangedSubview(waybackButton)
        buttonStack.addArrangedSubview(waybackErrorCard)
        buttonStack.setCustomSpacing(UX.cardTopSpacing, after: waybackButton)

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

        showsWayback = showWaybackButton
        configureWaybackButton(state: .idle)
    }

    /// Updates the wayback area to reflect idle, loading, or failed state.
    func configureWaybackButton(state: WaybackButtonState) {
        waybackState = state
        guard showsWayback else {
            waybackButton.isHidden = true
            waybackErrorCard.isHidden = true
            return
        }

        switch state {
        case .idle:
            waybackButton.isHidden = false
            waybackErrorCard.isHidden = true
            applyWaybackTitle(.NativeErrorPage.Wayback.SearchLabel, enabled: true, showsSpinner: false)
        case .loading:
            waybackButton.isHidden = false
            waybackErrorCard.isHidden = true
            applyWaybackTitle(.NativeErrorPage.Wayback.CheckingLabel, enabled: false, showsSpinner: true)
        case .failed:
            waybackButton.isHidden = true
            waybackErrorCard.isHidden = false
            configureRetryButtonTitle()
        }
    }

    private func applyWaybackTitle(_ title: String, enabled: Bool, showsSpinner: Bool) {
        let viewModel = SecondaryRoundedButtonViewModel(
            title: title,
            a11yIdentifier: AccessibilityIdentifiers.NativeErrorPage.waybackButton
        )
        waybackButton.configure(viewModel: viewModel)
        waybackButton.isEnabled = enabled
        waybackButton.configuration?.showsActivityIndicator = showsSpinner
        waybackButton.configuration?.imagePadding = 8
        waybackButton.configuration?.imagePlacement = .leading
    }

    private func configureRetryButtonTitle() {
        let attributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font: FXFontStyles.Regular.footnote.scaledFont()
        ]
        // TODO: add .NativeErrorPage.Wayback.RetryButton to Strings.swift
        let title = NSAttributedString(string: .NativeErrorPage.Wayback.RetryButton, attributes: attributes)
        waybackRetryButton.setAttributedTitle(title, for: .normal)
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
        waybackErrorCard.backgroundColor = theme.colors.layerWarning
        waybackErrorLabel.textColor = theme.colors.textPrimary
        waybackErrorIcon.tintColor = theme.colors.actionWarning
        waybackRetryButton.setTitleColor(theme.colors.textPrimary, for: .normal)
    }
}
