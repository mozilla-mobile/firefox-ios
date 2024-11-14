// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import SiteImageView
import ComponentLibrary
import X509

struct TrackingProtectionDetailsModel {
    let topLevelDomain: String
    let title: String
    let URL: String

    let getLockIcon: (ThemeType) -> UIImage
    let connectionStatusMessage: String
    let connectionSecure: Bool

    var certificates = [Certificate]()
    let viewCertificatesButtonTitle: String = .Menu.EnhancedTrackingProtection.viewCertificatesButtonTitle

    func getCertificatesModel() -> CertificatesModel {
        return CertificatesModel(
            topLevelDomain: topLevelDomain,
            title: title,
            URL: URL,
            certificates: certificates
        )
    }
}

class TrackingProtectionDetailsViewController: UIViewController, Themeable {
    private struct UX {
        static let baseCellHeight: CGFloat = 44
        static let baseDistance: CGFloat = 20
        static let viewCertButtonTopDistance: CGFloat = 8.0
    }

    // MARK: - UI
    private let scrollView: UIScrollView = .build { scrollView in }
    private let baseView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.accessibilityIdentifier = AccessibilityIdentifiers.EnhancedTrackingProtection.DetailsScreen.containerView
        stackView.distribution = .fillProportionally
    }

    private let headerView: NavigationHeaderView = .build { header in
        header.accessibilityIdentifier = AccessibilityIdentifiers.EnhancedTrackingProtection.DetailsScreen.headerView
    }
    private let connectionView: TrackingProtectionStatusView = .build { view in
        view.accessibilityIdentifier = AccessibilityIdentifiers.EnhancedTrackingProtection.DetailsScreen.connectionView
    }
    private let verifiedByView: TrackingProtectionVerifiedByView = .build()

    // MARK: See Certificates View
    private lazy var viewCertificatesButton: LinkButton = .build { button in
        button.titleLabel?.textAlignment = .left
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: #selector(self.viewCertificatesTapped), for: .touchUpInside)
    }

    // MARK: - Variables

    private var constraints = [NSLayoutConstraint]()
    var model: TrackingProtectionDetailsModel
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { return windowUUID }

    // MARK: - View Lifecycle

    init(with model: TrackingProtectionDetailsModel,
         windowUUID: WindowUUID,
         and notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.model = model
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

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
        setupHeaderViewActions()
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: Content View Setup
    private func setupContentView() {
        view.addSubview(scrollView)
        scrollView.addSubview(baseView)

        let contentViewContraints = [
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.bottomAnchor.constraint(
                greaterThanOrEqualTo: view.bottomAnchor
            ),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            baseView.topAnchor.constraint(
                equalTo: scrollView.topAnchor,
                constant: UX.baseDistance
            ),
            baseView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            baseView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            baseView.widthAnchor.constraint(
                equalTo: scrollView.widthAnchor,
                constant: -2 * TPMenuUX.UX.horizontalMargin
            ),
        ]

        constraints.append(contentsOf: contentViewContraints)
    }

    // MARK: Header View Setup
    private func setupHeaderView() {
        view.addSubview(headerView)
        let headerConstraints = [
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: TPMenuUX.UX.popoverTopDistance
            )
        ]
        constraints.append(contentsOf: headerConstraints)
    }

    // MARK: Connection Status View Setup
    private func setupConnectionStatusView() {
        baseView.addArrangedSubview(connectionView)
    }

    // MARK: Verified By View Setup
    private func setupVerifiedByView() {
        baseView.addArrangedSubview(verifiedByView)
    }

    // MARK: See Certificates View Setup
    private func setupSeeCertificatesView() {
        let certificatesButtonViewModel = LinkButtonViewModel(
            title: model.viewCertificatesButtonTitle,
            a11yIdentifier: AccessibilityIdentifiers.EnhancedTrackingProtection.DetailsScreen.certificatesButton,
            font: FXFontStyles.Regular.footnote.scaledFont()
        )
        viewCertificatesButton.configure(viewModel: certificatesButtonViewModel)
        baseView.addArrangedSubview(viewCertificatesButton)
        baseView.setCustomSpacing(
            UX.viewCertButtonTopDistance,
            after: verifiedByView
        )
    }

    // MARK: Header Actions
    private func setupHeaderViewActions() {
        headerView.backToMainMenuCallback = { [weak self] in
            self?.navigationController?.popToRootViewController(animated: true)
        }
        headerView.dismissMenuCallback = { [weak self] in
            self?.navigationController?.dismissVC()
        }
    }

    // MARK: Accessibility
    private func setupAccessibilityIdentifiers() {
        view.accessibilityIdentifier = AccessibilityIdentifiers.EnhancedTrackingProtection.DetailsScreen.mainView
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
        connectionView.lockImageHeightConstraint?.constant = min(
            UIFontMetrics.default.scaledValue(for: iconSize), 2 * iconSize
        )

        headerView.adjustLayout()
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    private func updateViewDetails() {
        headerView.setViews(with: model.topLevelDomain, and: .KeyboardShortcuts.Back)
        connectionView.connectionStatusLabel.text = model.connectionStatusMessage
        if let certificate = model.certificates.first,
           let issuer = "\(certificate.issuer)".getDictionary()[CertificateKeys.commonName] {
            let certificateVerifier = String(format: .Menu.EnhancedTrackingProtection.connectionVerifiedByLabel,
                                             issuer)
            verifiedByView.configure(verifiedBy: certificateVerifier)
            viewCertificatesButton.setTitle(model.viewCertificatesButtonTitle, for: .normal)
        } else {
            verifiedByView.isHidden = true
        }
    }

    // MARK: - Actions
    @objc
    func viewCertificatesTapped() {
        let certificatesController = CertificatesViewController(with: model.getCertificatesModel(),
                                                                windowUUID: windowUUID)
        self.navigationController?.pushViewController(certificatesController, animated: true)
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }
}

// MARK: - Themable
extension TrackingProtectionDetailsViewController {
    func applyTheme() {
        let theme = currentTheme()
        view.backgroundColor =  theme.colors.layer3
        connectionView.connectionImage.image = model.getLockIcon(theme.type)
        verifiedByView.applyTheme(theme: theme)
        viewCertificatesButton.applyTheme(theme: theme)
        headerView.applyTheme(theme: theme)
        connectionView.applyTheme(theme: theme)

        setNeedsStatusBarAppearanceUpdate()
    }
}
