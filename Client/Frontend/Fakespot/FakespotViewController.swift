// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared

class FakespotViewController: UIViewController, Themeable {
    private struct UX {
        static let closeButtonWidthHeight: CGFloat = 30
        static let topLeadingTrailingSpacing: CGFloat = 18
        static let logoSize: CGFloat = 36
        static let titleLabelFontSize: CGFloat = 17
        static let headerSpacing = 8.0
        static let headerBottomMargin = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
    }

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?

    private lazy var scrollView: UIScrollView = .build()

    private lazy var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
    }

    private lazy var headerStackView: UIStackView = .build { stackView in
        stackView.alignment = .center
        stackView.spacing = UX.headerSpacing
        stackView.layoutMargins = UX.headerBottomMargin
        stackView.isLayoutMarginsRelativeArrangement = true
    }

    private lazy var logoImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall)
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.text = Shopping.SheetHeaderTitle
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .headline,
                                                            size: UX.titleLabelFontSize,
                                                            weight: .semibold)
        label.accessibilityIdentifier = AccessibilityIdentifiers.Shopping.sheetHeaderTitle
    }

    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage(named: StandardImageIdentifiers.ExtraLarge.crossCircleFill), for: .normal)
        button.addTarget(self, action: #selector(self.closeTapped), for: .touchUpInside)
        button.accessibilityLabel = .CloseButtonTitle
    }

    // MARK: - Initializers
    init(notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup & lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupView()
        listenForThemeChange(view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if presentingViewController == nil {
            recordTelemetry()
        }
    }

    func applyTheme() {
        let colors = themeManager.currentTheme.colors
        titleLabel.textColor = colors.textPrimary
    }

    private func setupView() {
        view.addSubviews(headerStackView, scrollView, closeButton)
        scrollView.addSubview(contentStackView)
        [logoImageView, titleLabel].forEach(headerStackView.addArrangedSubview)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.widthAnchor.constraint(equalTo: view.widthAnchor),

            headerStackView.topAnchor.constraint(equalTo: view.topAnchor,
                                                 constant: UX.topLeadingTrailingSpacing),
            headerStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                     constant: UX.topLeadingTrailingSpacing),
            headerStackView.trailingAnchor.constraint(equalTo: closeButton.safeAreaLayoutGuide.leadingAnchor),

            logoImageView.widthAnchor.constraint(equalToConstant: UX.logoSize),
            logoImageView.heightAnchor.constraint(equalToConstant: UX.logoSize),

            closeButton.topAnchor.constraint(equalTo: view.topAnchor,
                                             constant: UX.topLeadingTrailingSpacing),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                  constant: -UX.topLeadingTrailingSpacing),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonWidthHeight),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonWidthHeight)
        ])
    }

    private func recordTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .close,
                                     object: .shoppingBottomSheet)
    }

    @objc
    private func closeTapped() {
        dismissVC()
    }
}
