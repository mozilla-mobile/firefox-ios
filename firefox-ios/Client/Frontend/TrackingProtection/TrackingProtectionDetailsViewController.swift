// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import SiteImageView
import ComponentLibrary

struct TrackingProtectionDetailsModel {
    let topLevelDomain: String
    let title: String
    let URL: String

    let getLockIcon: (ThemeType) -> UIImage
    let connectionStatusMessage: String
    let connectionSecure: Bool

    let viewCertificatesButtonTitle: String = .Menu.EnhancedTrackingProtection.viewCertificatesButtonTitle

    let detailsViewA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.DetailsScreen.mainView
    let connectionViewA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.DetailsScreen.connectionView
    let headerViewA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.DetailsScreen.headerView
    let containerViewA11Id = AccessibilityIdentifiers.EnhancedTrackingProtection.DetailsScreen.containerView
    let viewCertButtonA11Id = AccessibilityIdentifiers.EnhancedTrackingProtection.DetailsScreen.certificatesButton
}

class TrackingProtectionDetailsViewController: UIViewController, Themeable {
    // MARK: - UI
    private let scrollView: UIScrollView = .build { scrollView in }
    private let baseView: UIView = .build { view in }
    private let siteTitleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.numberOfLines = 2
        label.accessibilityTraits.insert(.header)
    }

    // MARK: Header View
    private let headerView = UIView()
    private let horizontalLine: UIView = .build { _ in }
    private var closeButton: UIButton = .build { button in
        button.layer.cornerRadius = 0.5 * TPMenuUX.UX.closeButtonSize
        button.clipsToBounds = true
        button.imageView?.contentMode = .scaleAspectFit
        button.setImage(UIImage(named: StandardImageIdentifiers.Medium.cross), for: .normal)
    }
    private var backButton: UIButton = .build { button in
        button.layer.cornerRadius = 0.5 * TPMenuUX.UX.closeButtonSize
        button.clipsToBounds = true
        button.setTitle(.KeyboardShortcuts.Back, for: .normal)
        button.setImage(UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.chevronLeft)
            .withRenderingMode(.alwaysTemplate),
                        for: .normal)
        button.titleLabel?.font = TPMenuUX.Fonts.viewTitleLabels
    }

    // MARK: Connection Status View
    private let connectionView: UIView = .build { view in
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = TPMenuUX.UX.viewCornerRadius
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.masksToBounds = true
    }
    private let connectionImage: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
        image.layer.cornerRadius = 5
    }
    private let connectionStatusLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .left
    }
    private let dividerView: UIView = .build { _ in }
    private var lockImageHeightConstraint: NSLayoutConstraint?

    // MARK: Verified By View
    private let verifiedByView: UIView = .build { view in
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = TPMenuUX.UX.viewCornerRadius
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        view.layer.masksToBounds = true
    }
    private let verifiedByLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .left
    }

    // MARK: See Certificates View
    private lazy var viewCertificatesButton: LinkButton = .build { button in
        button.titleLabel?.textAlignment = .left
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: #selector(self.viewCertificatesTapped), for: .touchUpInside)
    }

    // MARK: - Variables

    private var constraints = [NSLayoutConstraint]()
    var viewModel: TrackingProtectionDetailsModel
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { return windowUUID }

    // MARK: - View Lifecycle

    init(with viewModel: TrackingProtectionDetailsModel,
         windowUUID: WindowUUID,
         and notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateViewDetails()
        listenForThemeChange(view)
        applyTheme()
    }

    private func setupView() {
        constraints.removeAll()

        setupContentView()
        setupHeaderView()
        setupConnectionStatusView()
        setupVerifiedByView()
        setupSeeCertificatesView()
        setupAccessibilityIdentifiers()
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: Content View Setup
    private func setupContentView() {
        view.addSubview(scrollView)
        scrollView.addSubview(baseView)

        let contentViewContraints = [
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            baseView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            baseView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            baseView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            baseView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ]

        constraints.append(contentsOf: contentViewContraints)
    }

    // MARK: Header View Setup
    private func setupHeaderView() {
        view.addSubview(headerView)
        headerView.addSubviews(siteTitleLabel, backButton, closeButton, horizontalLine)
        headerView.translatesAutoresizingMaskIntoConstraints = false

        let headerViewContraints = [
            headerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            headerView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            headerView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            headerView.heightAnchor.constraint(greaterThanOrEqualToConstant: TPMenuUX.UX.baseCellHeight),

            backButton.leadingAnchor.constraint(
                equalTo: headerView.leadingAnchor,
                constant: TPMenuUX.UX.TrackingDetails.imageMargins
            ),
            backButton.topAnchor.constraint(equalTo: headerView.topAnchor,
                                            constant: TPMenuUX.UX.horizontalMargin),
            backButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            siteTitleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),

            siteTitleLabel.leadingAnchor.constraint(
                equalTo: backButton.trailingAnchor
            ),
            siteTitleLabel.trailingAnchor.constraint(
                equalTo: closeButton.leadingAnchor
            ),
            siteTitleLabel.topAnchor.constraint(
                equalTo: headerView.topAnchor,
                constant: TPMenuUX.UX.TrackingDetails.baseDistance
            ),
            siteTitleLabel.bottomAnchor.constraint(
                equalTo: headerView.bottomAnchor,
                constant: -TPMenuUX.UX.TrackingDetails.baseDistance
            ),

            closeButton.trailingAnchor.constraint(
                equalTo: headerView.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            closeButton.topAnchor.constraint(equalTo: headerView.topAnchor,
                                             constant: TPMenuUX.UX.horizontalMargin),
            closeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: TPMenuUX.UX.closeButtonSize),
            closeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: TPMenuUX.UX.closeButtonSize),
            closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor),

            horizontalLine.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            horizontalLine.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            horizontalLine.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            horizontalLine.heightAnchor.constraint(equalToConstant: TPMenuUX.UX.Line.height),
        ]

        constraints.append(contentsOf: headerViewContraints)
    }

    // MARK: Connection Status View Setup
    private func setupConnectionStatusView() {
        baseView.addSubviews(connectionView)
        connectionView.addSubviews(connectionImage, connectionStatusLabel, dividerView)

        lockImageHeightConstraint = connectionImage.widthAnchor.constraint(
            equalToConstant: TPMenuUX.UX.iconSize
        )

        let connectionViewContraints = [
            connectionView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            connectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor,
                                                constant: TPMenuUX.UX.TrackingDetails.baseDistance),
            connectionView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            connectionView.heightAnchor.constraint(greaterThanOrEqualToConstant: TPMenuUX.UX.baseCellHeight),

            connectionImage.centerYAnchor.constraint(equalTo: connectionView.centerYAnchor),
            connectionImage.leadingAnchor.constraint(equalTo: connectionView.leadingAnchor,
                                                     constant: TPMenuUX.UX.horizontalMargin),
            connectionImage.heightAnchor.constraint(equalTo: connectionView.widthAnchor),
            lockImageHeightConstraint!,

            connectionStatusLabel.leadingAnchor.constraint(equalTo: connectionImage.trailingAnchor,
                                                           constant: TPMenuUX.UX.TrackingDetails.imageMargins),
            connectionStatusLabel.trailingAnchor.constraint(equalTo: connectionView.trailingAnchor),
            connectionStatusLabel.centerYAnchor.constraint(equalTo: connectionView.centerYAnchor),

            dividerView.leadingAnchor.constraint(equalTo: connectionStatusLabel.leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: connectionView.trailingAnchor),
            dividerView.bottomAnchor.constraint(equalTo: connectionView.bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: TPMenuUX.UX.Line.height),
        ]

        constraints.append(contentsOf: connectionViewContraints)
    }

    // MARK: Verified By View Setup
    private func setupVerifiedByView() {
        baseView.addSubview(verifiedByView)
        verifiedByView.addSubview(verifiedByLabel)

        let verifiedByViewContraints = [
            verifiedByView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            verifiedByView.topAnchor.constraint(equalTo: connectionView.bottomAnchor),
            verifiedByView.bottomAnchor.constraint(equalTo: baseView.bottomAnchor,
                                                   constant: -TPMenuUX.UX.TrackingDetails.bottomDistance),
            verifiedByView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            verifiedByView.heightAnchor.constraint(greaterThanOrEqualToConstant: TPMenuUX.UX.baseCellHeight),

            verifiedByLabel.leadingAnchor.constraint(equalTo: verifiedByView.leadingAnchor,
                                                     constant: TPMenuUX.UX.horizontalMargin),
            verifiedByLabel.trailingAnchor.constraint(equalTo: verifiedByView.trailingAnchor),
            verifiedByLabel.centerYAnchor.constraint(equalTo: verifiedByView.centerYAnchor)
        ]

        constraints.append(contentsOf: verifiedByViewContraints)
    }

    // MARK: See Certificates View Setup
    private func setupSeeCertificatesView() {
        let certificatesButtonViewModel = LinkButtonViewModel(
            title: viewModel.viewCertificatesButtonTitle,
            underlineStyle: [],
            a11yIdentifier: viewModel.viewCertButtonA11Id,
            font: FXFontStyles.Regular.footnote.scaledFont()
        )
        viewCertificatesButton.configure(viewModel: certificatesButtonViewModel)
        baseView.addSubview(viewCertificatesButton)

        let viewCertificatesConstraints = [
            viewCertificatesButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            viewCertificatesButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            viewCertificatesButton.topAnchor.constraint(
                equalTo: verifiedByView.bottomAnchor,
                constant: TPMenuUX.UX.TrackingDetails.viewCertButtonTopDistance
            ),
        ]

        constraints.append(contentsOf: viewCertificatesConstraints)
    }

    // MARK: Accessibility
    private func setupAccessibilityIdentifiers() {
        headerView.accessibilityIdentifier = viewModel.headerViewA11yId
        view.accessibilityIdentifier = viewModel.detailsViewA11yId
        baseView.accessibilityIdentifier = viewModel.containerViewA11Id
        connectionView.accessibilityIdentifier = viewModel.connectionViewA11yId
    }

    // MARK: View Transitions
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        adjustLayout()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.adjustLayout()
        }, completion: nil)
    }

    private func adjustLayout() {
        let iconSize = TPMenuUX.UX.iconSize
        lockImageHeightConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: iconSize), 2 * iconSize)

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    private func updateViewDetails() {
        siteTitleLabel.text = viewModel.topLevelDomain
        connectionStatusLabel.text = viewModel.connectionStatusMessage
        verifiedByLabel.text = String(format: .Menu.EnhancedTrackingProtection.connectionVerifiedByLabel,
                                      viewModel.topLevelDomain) // to be updated with the certificate verifier
        viewCertificatesButton.setTitle(viewModel.viewCertificatesButtonTitle, for: .normal)
    }

    // MARK: - Actions

    @objc
    func closeButtonTapped() {
        self.dismiss(animated: true)
    }

    @objc
    func viewCertificatesTapped() {
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }
}

// MARK: - Themable
extension TrackingProtectionDetailsViewController {
    func applyTheme() {
        let theme = currentTheme()
        overrideUserInterfaceStyle = theme.type.getInterfaceStyle()
        view.backgroundColor =  theme.colors.layer1
        siteTitleLabel.textColor = theme.colors.textPrimary
        connectionStatusLabel.textColor = theme.colors.textPrimary
        connectionView.backgroundColor = theme.colors.layer2
        connectionImage.image = viewModel.getLockIcon(theme.type)
        dividerView.backgroundColor = theme.colors.borderPrimary
        horizontalLine.backgroundColor = theme.colors.borderPrimary
        connectionImage.tintColor = theme.colors.iconPrimary
        let buttonImage = UIImage(named: StandardImageIdentifiers.Medium.cross)?
            .tinted(withColor: theme.colors.iconSecondary)
        closeButton.setImage(buttonImage, for: .normal)
        closeButton.backgroundColor = theme.colors.layer2
        backButton.titleLabel?.textColor = theme.colors.textAccent
        backButton.tintColor = theme.colors.iconAction

        verifiedByLabel.textColor = theme.colors.textPrimary
        verifiedByView.backgroundColor = theme.colors.layer2
        viewCertificatesButton.applyTheme(theme: theme)

        setNeedsStatusBarAppearanceUpdate()
    }
}
