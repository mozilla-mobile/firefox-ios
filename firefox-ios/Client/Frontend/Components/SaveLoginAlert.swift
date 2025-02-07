// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary

struct SaveLoginAlertViewModel {
    let saveButtonTitle: String
    let saveButtonA11yId: String
    let notNowButtonTitle: String
    let notNowButtonA11yId: String
    let titleText: String
}

class SaveLoginAlert: UIView, ThemeApplicable {
    var saveAction: (() -> Void)?
    var notNotAction: (() -> Void)?
    // Used to persist the alert a certain amount of time only
    var shouldPersist = false

    private struct UX {
        static let cornerRadius: CGFloat = 8
        static let buttonSpacing: CGFloat = 12
        static let headerSpacing: CGFloat = 12
        static let outerSpacing: CGFloat = 12
        static let innerSpacing: CGFloat = 16

        // Shadow
        static let shadowRadius: CGFloat = 6
        static let shadowOffset = CGSize(width: 0, height: 0)
        static let shadowOpacity: Float = 1
    }

    private lazy var shadowView: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
    }

    private lazy var headerStackView: UIStackView = .build { stackView in
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.spacing = UX.headerSpacing
    }

    private lazy var imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.login)
    }

    private lazy var textLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.body.scaledFont()
        label.backgroundColor = .clear
    }

    private lazy var buttonsStackView: UIStackView = .build { stackView in
        stackView.distribution = .fillEqually
        stackView.spacing = UX.buttonSpacing
    }

    private lazy var notNowButton: SecondaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.notNowButtonPressed), for: .touchUpInside)
    }

    private lazy var saveButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.saveButtonPressed), for: .touchUpInside)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setShadowPath()
    }

    func configure(viewModel: SaveLoginAlertViewModel) {
        textLabel.text = viewModel.titleText
        setupLayout()

        let saveButtonViewModel = PrimaryRoundedButtonViewModel(
            title: viewModel.saveButtonTitle,
            a11yIdentifier: viewModel.saveButtonA11yId
        )
        saveButton.configure(viewModel: saveButtonViewModel)

        let notNowButtonViewModel = SecondaryRoundedButtonViewModel(
            title: viewModel.notNowButtonTitle,
            a11yIdentifier: viewModel.notNowButtonA11yId
        )
        notNowButton.configure(viewModel: notNowButtonViewModel)

        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: viewModel.titleText)
        }
    }

    private func setupLayout() {
        addSubview(shadowView)
        shadowView.addSubviews(headerStackView, buttonsStackView)

        headerStackView.addArrangedSubview(imageView)
        headerStackView.addArrangedSubview(textLabel)
        buttonsStackView.addArrangedSubview(notNowButton)
        buttonsStackView.addArrangedSubview(saveButton)

        NSLayoutConstraint.activate([
            shadowView.topAnchor.constraint(equalTo: topAnchor, constant: UX.outerSpacing),
            shadowView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.outerSpacing),
            shadowView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.outerSpacing),
            shadowView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.outerSpacing),

            headerStackView.topAnchor.constraint(equalTo: shadowView.topAnchor,
                                                 constant: UX.innerSpacing),
            headerStackView.leadingAnchor.constraint(greaterThanOrEqualTo: shadowView.leadingAnchor),
            headerStackView.centerXAnchor.constraint(equalTo: shadowView.centerXAnchor),
            headerStackView.trailingAnchor.constraint(lessThanOrEqualTo: shadowView.trailingAnchor),
            headerStackView.bottomAnchor.constraint(equalTo: buttonsStackView.topAnchor,
                                                    constant: -UX.innerSpacing),

            buttonsStackView.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor,
                                                      constant: UX.innerSpacing),
            buttonsStackView.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor,
                                                       constant: -UX.innerSpacing),
            buttonsStackView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor,
                                                     constant: -UX.innerSpacing)
        ])
    }

    // MARK: Buttons Action

    @objc
    private func notNowButtonPressed() {
        notNotAction?()
    }

    @objc
    private func saveButtonPressed() {
        saveAction?()
    }

    // MARK: ThemeApplicable

    func applyTheme(theme: Theme) {
        backgroundColor = .clear
        shadowView.backgroundColor = theme.colors.layer1
        imageView.tintColor = theme.colors.iconPrimary
        textLabel.textColor = theme.colors.textPrimary
        setupShadow(theme: theme)
        saveButton.applyTheme(theme: theme)
        notNowButton.applyTheme(theme: theme)
    }

    private func setupShadow(theme: Theme) {
        shadowView.layoutIfNeeded()

        shadowView.layer.shadowRadius = UX.shadowRadius
        shadowView.layer.shadowOffset = UX.shadowOffset
        shadowView.layer.shadowColor = theme.colors.shadowStrong.cgColor
        shadowView.layer.shadowOpacity = UX.shadowOpacity
    }

    private func setShadowPath() {
        shadowView.layer.shadowPath = UIBezierPath(
            roundedRect: shadowView.bounds,
            cornerRadius: UX.cornerRadius
        ).cgPath
    }
}
