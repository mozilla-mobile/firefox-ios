// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

protocol InAppModalDelegate: AnyObject {
    func inAppModalDidTapCTA(_ modal: InAppModalViewController, action: InAppMessage.CTAAction?)
    func inAppModalDidDismiss(_ modal: InAppModalViewController)
}

final class InAppModalViewController: UIViewController, Themeable {
    private struct UX {
        static let cardMaxWidth: CGFloat = 340
        static let cornerRadius: CGFloat = 16
        static let padding: CGFloat = 24
        static let imageHeight: CGFloat = 160
        static let spacing: CGFloat = 16
        static let closeButtonSize: CGFloat = 24
    }

    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    weak var delegate: InAppModalDelegate?
    let message: InAppMessage

    private lazy var overlayView: UIView = .build { view in
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    }

    private lazy var cardView: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
        view.clipsToBounds = true
    }

    private lazy var closeButton: CloseButton = .build { [weak self] button in
        button.addTarget(self, action: #selector(self?.dismissTapped), for: .touchUpInside)
    }

    private lazy var imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.title3.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = .center
    }

    private lazy var bodyLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = .center
    }

    private lazy var ctaButton: PrimaryRoundedButton = .build { [weak self] button in
        button.addTarget(self, action: #selector(self?.ctaTapped), for: .touchUpInside)
    }

    private lazy var secondaryButton: LinkButton = .build { [weak self] button in
        button.addTarget(self, action: #selector(self?.dismissTapped), for: .touchUpInside)
    }

    private lazy var contentStack: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = UX.spacing
    }

    init(
        message: InAppMessage,
        windowUUID: WindowUUID,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.message = message
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        configure()
        listenForThemeChange(view)
        applyTheme()
    }

    private func setupLayout() {
        view.addSubview(overlayView)
        view.addSubview(cardView)

        if message.content.imageURL != nil {
            contentStack.addArrangedSubview(imageView)
        }
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(bodyLabel)
        contentStack.addArrangedSubview(ctaButton)

        if message.content.dismissLabel != nil {
            contentStack.addArrangedSubview(secondaryButton)
        }

        cardView.addSubview(contentStack)
        cardView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.widthAnchor.constraint(lessThanOrEqualToConstant: UX.cardMaxWidth),
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: UX.padding),
            cardView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -UX.padding),

            closeButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),

            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: UX.padding),
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: UX.padding),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -UX.padding),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -UX.padding),
        ])

        if message.content.imageURL != nil {
            imageView.heightAnchor.constraint(equalToConstant: UX.imageHeight).isActive = true
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
        overlayView.addGestureRecognizer(tapGesture)
    }

    private func configure() {
        titleLabel.text = message.content.title
        bodyLabel.text = message.content.body
        bodyLabel.isHidden = message.content.body == nil

        if let ctaLabel = message.content.ctaLabel {
            let viewModel = PrimaryRoundedButtonViewModel(
                title: ctaLabel,
                a11yIdentifier: "InAppModal.ctaButton"
            )
            ctaButton.configure(viewModel: viewModel)
        } else {
            ctaButton.isHidden = true
        }

        if let dismissLabel = message.content.dismissLabel {
            let viewModel = LinkButtonViewModel(
                title: dismissLabel,
                a11yIdentifier: "InAppModal.dismissButton"
            )
            secondaryButton.configure(viewModel: viewModel)
        }

        let closeViewModel = CloseButtonViewModel(
            a11yLabel: .AppMenu.AppMenuCloseAccessibilityLabel,
            a11yIdentifier: "InAppModal.closeButton"
        )
        closeButton.configure(viewModel: closeViewModel)

        if let imageURLString = message.content.imageURL, let url = URL(string: imageURLString) {
            loadImage(from: url)
        }
    }

    private func loadImage(from url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.sharedMPTCP.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        imageView.image = image
                    }
                }
            } catch {
                imageView.isHidden = true
            }
        }
    }

    @objc private func ctaTapped() {
        delegate?.inAppModalDidTapCTA(self, action: message.content.ctaAction)
    }

    @objc private func dismissTapped() {
        delegate?.inAppModalDidDismiss(self)
    }

    @objc private func overlayTapped() {
        delegate?.inAppModalDidDismiss(self)
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        cardView.backgroundColor = theme.colors.layer1
        titleLabel.textColor = theme.colors.textPrimary
        bodyLabel.textColor = theme.colors.textSecondary
        ctaButton.applyTheme(theme: theme)
        closeButton.applyTheme(theme: theme)
    }
}
