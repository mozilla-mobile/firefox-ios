// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import SiteImageView

struct BlockedTrackersViewModel {
    let topLevelDomain: String
    let title: String
    let URL: String

    let contentBlockerStats: TPPageStats?
    let getLockIcon: (ThemeType) -> UIImage
    let connectionStatusMessage: String
    let connectionSecure: Bool

    let containerViewA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackers.containerView
    let blockedTrackersViewA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackers.mainView
    let headerViewA11yId = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackers.headerView
    let crossSiteViewA11Id = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackers.crossSiteTrackersView
    let socialMediaViewA11Id = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackers.socialMediaTrackersView
    let fingerprintersViewA11Id = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackers.fingerprintersView
    let crossSiteImageA11Id = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackers.crossSiteTrackersImage
    let socialMediaImageA11Id = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackers.socialMediaTrackersImage
    let fingerprintersImageA11Id = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackers.fingerprintersImage
}

class BlockedTrackersViewController: UIViewController, Themeable {
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
    private let totalTrackersBlockedLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .left
        label.font = FXFontStyles.Regular.caption1.scaledFont()
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
        button.setTitle("Back", for: .normal)
        button.setImage(UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.chevronLeft)
            .withRenderingMode(.alwaysTemplate),
                        for: .normal)
        button.titleLabel?.font = TPMenuUX.Fonts.viewTitleLabels
    }

    // MARK: Cross-site trackers View
    private let crossSiteTrackersView: UIView = .build { view in
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = TPMenuUX.UX.viewCornerRadius
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.masksToBounds = true
    }
    private let crossSiteTrackersImage: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
        image.layer.cornerRadius = 5
        image.image = UIImage(imageLiteralResourceName: ImageIdentifiers.TrackingProtection.crossSiteTrackers)
            .withRenderingMode(.alwaysTemplate)
    }

    private let crossSiteTrackersLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .left
    }
    private let crossSitesTrackersDividerView: UIView = .build { _ in }
    private var crossSiteImageHeightConstraint: NSLayoutConstraint?

    // MARK: Social Media trackers View
    private let socialMediaTrackersView: UIView = .build { view in
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    private let socialMediaTrackersImage: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
        image.layer.cornerRadius = 5
        image.image = UIImage(imageLiteralResourceName: ImageIdentifiers.TrackingProtection.socialMediaTrackers)
            .withRenderingMode(.alwaysTemplate)
    }
    private let socialMediaTrackersLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .left
    }

    private var socialMediaImageHeightConstraint: NSLayoutConstraint?
    private let socialMediaTrackersDividerView: UIView = .build { _ in }

    // MARK: Fingerprinters blocked View
    private let fingerprintersView: UIView = .build { view in
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = TPMenuUX.UX.viewCornerRadius
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        view.layer.masksToBounds = true
    }
    private let fingerprintersImage: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
        image.layer.cornerRadius = 5
        image.image = UIImage(imageLiteralResourceName: ImageIdentifiers.TrackingProtection.fingerprintersTrackers)
            .withRenderingMode(.alwaysTemplate)
    }
    private let fingerprintersLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .left
    }

    private var fingerprintersImageHeightConstraint: NSLayoutConstraint?

    // MARK: - Variables

    private var constraints = [NSLayoutConstraint]()
    var viewModel: BlockedTrackersViewModel
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { return windowUUID }

    // MARK: - View Lifecycle

    init(with viewModel: BlockedTrackersViewModel,
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
        setupCrossSiteTrackersView()
        setupSocialMediaView()
        setupFingerprintersView()
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
        view.addSubview(totalTrackersBlockedLabel)
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

            totalTrackersBlockedLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            totalTrackersBlockedLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            totalTrackersBlockedLabel.topAnchor.constraint(
                equalTo: headerView.bottomAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
        ]

        constraints.append(contentsOf: headerViewContraints)
    }

    // MARK: Cross Site Trackers View Setup
    private func setupCrossSiteTrackersView() {
        baseView.addSubviews(crossSiteTrackersView)
        crossSiteTrackersView.addSubviews(crossSiteTrackersImage, crossSiteTrackersLabel, crossSitesTrackersDividerView)

        crossSiteImageHeightConstraint = crossSiteTrackersImage.widthAnchor.constraint(
            equalToConstant: TPMenuUX.UX.iconSize
        )

        let connectionViewContraints = [
            crossSiteTrackersView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            crossSiteTrackersView.topAnchor.constraint(equalTo: totalTrackersBlockedLabel.bottomAnchor,
                                                       constant: TPMenuUX.UX.BlockedTrackers.headerDistance),
            crossSiteTrackersView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            crossSiteTrackersView.heightAnchor.constraint(greaterThanOrEqualToConstant: TPMenuUX.UX.baseCellHeight),

            crossSiteTrackersImage.centerYAnchor.constraint(equalTo: crossSiteTrackersView.centerYAnchor),
            crossSiteTrackersImage.leadingAnchor.constraint(equalTo: crossSiteTrackersView.leadingAnchor,
                                                            constant: TPMenuUX.UX.horizontalMargin),
            crossSiteTrackersImage.heightAnchor.constraint(equalTo: crossSiteTrackersView.widthAnchor),
            crossSiteImageHeightConstraint!,

            crossSiteTrackersLabel.leadingAnchor.constraint(equalTo: crossSiteTrackersImage.trailingAnchor,
                                                            constant: TPMenuUX.UX.TrackingDetails.imageMargins),
            crossSiteTrackersLabel.trailingAnchor.constraint(equalTo: crossSiteTrackersView.trailingAnchor),
            crossSiteTrackersLabel.centerYAnchor.constraint(equalTo: crossSiteTrackersView.centerYAnchor),

            crossSitesTrackersDividerView.leadingAnchor.constraint(equalTo: crossSiteTrackersLabel.leadingAnchor),
            crossSitesTrackersDividerView.trailingAnchor.constraint(equalTo: crossSiteTrackersView.trailingAnchor),
            crossSitesTrackersDividerView.bottomAnchor.constraint(equalTo: crossSiteTrackersView.bottomAnchor),
            crossSitesTrackersDividerView.heightAnchor.constraint(equalToConstant: TPMenuUX.UX.Line.height),
        ]

        constraints.append(contentsOf: connectionViewContraints)
    }

    // MARK: Social Media Trackers View Setup
    private func setupSocialMediaView() {
        baseView.addSubview(socialMediaTrackersView)
        socialMediaTrackersView.addSubviews(socialMediaTrackersImage,
                                            socialMediaTrackersLabel,
                                            socialMediaTrackersDividerView)

        socialMediaImageHeightConstraint = socialMediaTrackersImage.widthAnchor.constraint(
            equalToConstant: TPMenuUX.UX.iconSize
        )

        let socialMediaViewContraints = [
            socialMediaTrackersView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            socialMediaTrackersView.topAnchor.constraint(equalTo: crossSiteTrackersView.bottomAnchor),
            socialMediaTrackersView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            socialMediaTrackersView.heightAnchor.constraint(greaterThanOrEqualToConstant: TPMenuUX.UX.baseCellHeight),

            socialMediaTrackersImage.centerYAnchor.constraint(equalTo: socialMediaTrackersView.centerYAnchor),
            socialMediaTrackersImage.leadingAnchor.constraint(equalTo: socialMediaTrackersView.leadingAnchor,
                                                              constant: TPMenuUX.UX.horizontalMargin),
            socialMediaTrackersImage.heightAnchor.constraint(equalTo: socialMediaTrackersView.widthAnchor),
            socialMediaImageHeightConstraint!,

            socialMediaTrackersLabel.leadingAnchor.constraint(equalTo: socialMediaTrackersImage.trailingAnchor,
                                                              constant: TPMenuUX.UX.horizontalMargin),
            socialMediaTrackersLabel.trailingAnchor.constraint(equalTo: socialMediaTrackersView.trailingAnchor),
            socialMediaTrackersLabel.centerYAnchor.constraint(equalTo: socialMediaTrackersView.centerYAnchor),

            socialMediaTrackersDividerView.leadingAnchor.constraint(equalTo: socialMediaTrackersLabel.leadingAnchor),
            socialMediaTrackersDividerView.trailingAnchor.constraint(equalTo: socialMediaTrackersView.trailingAnchor),
            socialMediaTrackersDividerView.bottomAnchor.constraint(equalTo: socialMediaTrackersView.bottomAnchor),
            socialMediaTrackersDividerView.heightAnchor.constraint(equalToConstant: TPMenuUX.UX.Line.height),
        ]

        constraints.append(contentsOf: socialMediaViewContraints)
    }

    // MARK: Fingerprinters View Setup
    private func setupFingerprintersView() {
        baseView.addSubviews(fingerprintersView)
        fingerprintersView.addSubviews(fingerprintersImage, fingerprintersLabel)

        fingerprintersImageHeightConstraint = fingerprintersImage.widthAnchor.constraint(
            equalToConstant: TPMenuUX.UX.iconSize
        )

        let fingerprintersViewContraints = [
            fingerprintersView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            fingerprintersView.topAnchor.constraint(equalTo: socialMediaTrackersView.bottomAnchor),
            fingerprintersView.bottomAnchor.constraint(equalTo: baseView.bottomAnchor,
                                                       constant: -TPMenuUX.UX.TrackingDetails.bottomDistance),
            fingerprintersView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            fingerprintersView.heightAnchor.constraint(greaterThanOrEqualToConstant: TPMenuUX.UX.baseCellHeight),

            fingerprintersImage.centerYAnchor.constraint(equalTo: fingerprintersView.centerYAnchor),
            fingerprintersImage.leadingAnchor.constraint(equalTo: fingerprintersView.leadingAnchor,
                                                         constant: TPMenuUX.UX.horizontalMargin),
            fingerprintersImage.heightAnchor.constraint(equalTo: fingerprintersView.widthAnchor),
            fingerprintersImageHeightConstraint!,

            fingerprintersLabel.leadingAnchor.constraint(equalTo: fingerprintersImage.trailingAnchor,
                                                         constant: TPMenuUX.UX.TrackingDetails.imageMargins),
            fingerprintersLabel.trailingAnchor.constraint(equalTo: fingerprintersView.trailingAnchor),
            fingerprintersLabel.centerYAnchor.constraint(equalTo: fingerprintersView.centerYAnchor),
        ]

        constraints.append(contentsOf: fingerprintersViewContraints)
    }

    // MARK: Accessibility
    private func setupAccessibilityIdentifiers() {
        headerView.accessibilityIdentifier = viewModel.headerViewA11yId
        view.accessibilityIdentifier = viewModel.blockedTrackersViewA11yId
        baseView.accessibilityIdentifier = viewModel.containerViewA11yId
        crossSiteTrackersView.accessibilityIdentifier = viewModel.crossSiteViewA11Id
        fingerprintersView.accessibilityIdentifier = viewModel.fingerprintersViewA11Id
        socialMediaTrackersView.accessibilityIdentifier = viewModel.socialMediaViewA11Id
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
        crossSiteImageHeightConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: iconSize), 2 * iconSize)
        socialMediaImageHeightConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: iconSize), 2 * iconSize)
        fingerprintersImageHeightConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: iconSize), 2 * iconSize)

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    private func updateViewDetails() {
        siteTitleLabel.text = viewModel.topLevelDomain
        let totalTrackerBlocked = String(viewModel.contentBlockerStats?.total ?? 0)
        let trackersText = String(format: .Menu.EnhancedTrackingProtection.trackersBlockedLabel, totalTrackerBlocked)
        totalTrackersBlockedLabel.text = trackersText

        let crossSiteString = String(viewModel.contentBlockerStats?.getTrackersBlockedForCategory(.advertising) ?? 0)
        let fingerprintersString = String(viewModel.contentBlockerStats?.getTrackersBlockedForCategory(.fingerprinting) ?? 0)
        let socialMediaString = String(viewModel.contentBlockerStats?.getTrackersBlockedForCategory(.social) ?? 0)

        let crossSiteText = String(format: .Menu.EnhancedTrackingProtection.crossSiteTrackersBlockedLabel,
                                   crossSiteString)
        let fingerprintersText = String(format: .Menu.EnhancedTrackingProtection.fingerprinterBlockedLabel,
                                        fingerprintersString)
        let socialMediaText = String(format: .Menu.EnhancedTrackingProtection.socialMediaTrackersBlockedLabel,
                                     socialMediaString)

        crossSiteTrackersLabel.text = crossSiteText
        fingerprintersLabel.text = fingerprintersText
        socialMediaTrackersLabel.text = socialMediaText
        // String(format: .Menu.EnhancedTrackingProtection.connectionVerifiedByLabel, viewModel.topLevelDomain)
        // to be updated with the certificate verifier
    }

    // MARK: - Actions

    @objc
    func closeButtonTapped() {
        self.dismiss(animated: true)
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }
}

// MARK: - Themable
extension BlockedTrackersViewController {
    func applyTheme() {
        let theme = currentTheme()
        overrideUserInterfaceStyle = theme.type.getInterfaceStyle()
        view.backgroundColor =  theme.colors.layer1
        totalTrackersBlockedLabel.textColor = theme.colors.textSecondary
        siteTitleLabel.textColor = theme.colors.textPrimary
        crossSiteTrackersLabel.textColor = theme.colors.textPrimary
        crossSiteTrackersView.backgroundColor = theme.colors.layer2
//        crossSiteTrackersImage.image = UIImage(named: ImageIdentifiers.TrackingProtection.crossSiteTrackers)
        crossSitesTrackersDividerView.backgroundColor = theme.colors.borderPrimary
        horizontalLine.backgroundColor = theme.colors.borderPrimary
        if viewModel.connectionSecure {
            crossSiteTrackersImage.tintColor = theme.colors.iconPrimary
        }
        let buttonImage = UIImage(named: StandardImageIdentifiers.Medium.cross)?
            .tinted(withColor: theme.colors.iconSecondary)
        closeButton.setImage(buttonImage, for: .normal)
        closeButton.backgroundColor = theme.colors.layer2
        backButton.titleLabel?.textColor = theme.colors.textAccent
        backButton.tintColor = theme.colors.iconAction

        socialMediaTrackersLabel.textColor = theme.colors.textPrimary
        socialMediaTrackersView.backgroundColor = theme.colors.layer2
//        socialMediaTrackersImage.image = UIImage(named: ImageIdentifiers.TrackingProtection.socialMediaTrackers)
        socialMediaTrackersDividerView.backgroundColor = theme.colors.borderPrimary

        fingerprintersLabel.textColor = theme.colors.textPrimary
        fingerprintersView.backgroundColor = theme.colors.layer2
//        fingerprintersImage.image = UIImage(named: /*ImageIdentifiers.TrackingProtection.fingerprintersTrackers*/)
        fingerprintersImage.tintColor = theme.colors.iconPrimary
        socialMediaTrackersImage.tintColor = theme.colors.iconPrimary
        crossSiteTrackersImage.tintColor = theme.colors.iconPrimary

        setNeedsStatusBarAppearanceUpdate()
    }
}
