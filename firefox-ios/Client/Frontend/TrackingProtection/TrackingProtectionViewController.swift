// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import UIKit
import Common
import ComponentLibrary
import SiteImageView

struct TPMenuUX {
    struct Fonts {
        static let websiteTitle: UIFont = .systemFont(ofSize: 17, weight: .semibold)
        static let viewTitleLabels: UIFont = .systemFont(ofSize: 17, weight: .regular)
        static let detailsLabel: UIFont = .systemFont(ofSize: 12, weight: .regular)
        static let minorInfoLabel: UIFont = .systemFont(ofSize: 15, weight: .regular)
    }

    struct UX {
        static let baseCellHeight: CGFloat = 44
        static let popoverTopDistance: CGFloat = 20
        static let horizontalMargin: CGFloat = 16
        static let viewCornerRadius: CGFloat = 8
        static let headerLabelDistance: CGFloat = 2.0
        static let headerLinesLimit: Int = 2
        static let foxImageSize: CGFloat = 100
        static let iconSize: CGFloat = 24
        static let protectionViewBottomSpacing: CGFloat = 70
        static let siteDomainLabelsVerticalSpacing: CGFloat = 12
        static let connectionDetailsLabelBottomSpacing: CGFloat = 28
        static let connectionDetailsHeaderMargins: CGFloat = 8
        static let faviconImageSize: CGFloat = 40
        static let closeButtonSize: CGFloat = 30
        static let faviconCornerRadius: CGFloat = 5
        static let scrollContentHorizontalPadding: CGFloat = 16

        static let clearDataButtonCornerRadius: CGFloat = 12
        static let clearDataButtonBorderWidth: CGFloat = 1
        static let settingsLinkButtonBottomSpacing: CGFloat = 32
        struct Line {
            static let height: CGFloat = 1
        }
        struct TrackingDetails {
            static let baseDistance: CGFloat = 20
            static let imageMargins: CGFloat = 10
            static let bottomDistance: CGFloat = 350
        }
        struct BlockedTrackers {
            static let headerDistance: CGFloat = 8
        }
    }
}

class TPSectionView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = TPMenuUX.UX.viewCornerRadius
    }
}

protocol TrackingProtectionMenuDelegate: AnyObject {
    func settingsOpenPage(settings: Route.SettingsSection)
    func didFinish()
}

class TrackingProtectionViewController: UIViewController, Themeable, Notifiable, UIScrollViewDelegate, BottomSheetChild {
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    weak var enhancedTrackingProtectionMenuDelegate: TrackingProtectionMenuDelegate?

    private var faviconHeightConstraint: NSLayoutConstraint?
    private var faviconWidthConstraint: NSLayoutConstraint?
    private var foxImageHeightConstraint: NSLayoutConstraint?
    private var shieldImageHeightConstraint: NSLayoutConstraint?
    private var lockImageHeightConstraint: NSLayoutConstraint?

    private var trackersArrowHeightConstraint: NSLayoutConstraint?
    private var connectionArrowHeightConstraint: NSLayoutConstraint?

    private lazy var scrollView: UIScrollView = .build { scrollView in
        scrollView.translatesAutoresizingMaskIntoConstraints = false
    }
    private let baseView: UIView = .build { view in }
    private lazy var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 0
    }

    // MARK: UI components Header View
    private let headerContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private lazy var headerLabelsContainer: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.alignment = .leading
        stack.axis = .vertical
        stack.spacing = TPMenuUX.UX.headerLabelDistance
    }

    private var favicon: FaviconImageView = .build { favicon in
        favicon.manuallySetImage(
            UIImage(named: StandardImageIdentifiers.Large.globe)?.withRenderingMode(.alwaysTemplate) ?? UIImage())
    }

    private let siteDisplayTitleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.numberOfLines = TPMenuUX.UX.headerLinesLimit
        label.adjustsFontForContentSizeCategory = true
    }

    private let siteDomainLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private var closeButton: UIButton = .build { button in
        button.layer.cornerRadius = 0.5 * TPMenuUX.UX.closeButtonSize
        button.clipsToBounds = true
        button.imageView?.contentMode = .scaleAspectFit
        button.setImage(UIImage(named: StandardImageIdentifiers.Medium.cross), for: .normal)
    }

    // MARK: Connection Details View
    private let connectionDetailsHeaderView: UIView = .build { view in
        view.layer.cornerRadius = TPMenuUX.UX.viewCornerRadius
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.masksToBounds = true
    }
    private let connectionDetailsContentView: UIView = .build { view in
        view.layer.cornerRadius = TPMenuUX.UX.viewCornerRadius
        view.layer.masksToBounds = true
    }

    private let foxStatusImage: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
    }

    private var connectionDetailsLabelsContainer: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.distribution = .fillProportionally
        stack.alignment = .leading
        stack.axis = .vertical
        stack.spacing = 0.0
    }

    private var connectionDetailsTitleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.subheadline.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private let connectionDetailsStatusLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    // MARK: Blocked Trackers View
    private let trackersView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private let shieldImage: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
        image.image = UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.shield)
            .withRenderingMode(.alwaysTemplate)
    }

    private let trackersLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private let trackersDetailArrow: UIImageView = .build { image in
        image.image = UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.chevronLeft)
            .withRenderingMode(.alwaysTemplate)
            .imageFlippedForRightToLeftLayoutDirection()
        image.transform = CGAffineTransform(rotationAngle: .pi)
    }

    private let trackersHorizontalLine: UIView = .build { _ in }
    private let trackersButton: UIButton = .build { button in }

    // MARK: Connection Status View
    private let connectionView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private let connectionStatusImage: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
    }

    private let connectionStatusLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private let connectionDetailArrow: UIImageView = .build { image in
        image.image = UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.chevronLeft)
            .withRenderingMode(.alwaysTemplate)
            .imageFlippedForRightToLeftLayoutDirection()
        image.transform = CGAffineTransform(rotationAngle: .pi)
    }

    private let connectionButton: UIButton = .build { button in }
    private let connectionHorizontalLine: UIView = .build { _ in }

    // MARK: Toggle View
    private let toggleContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private let toggleView: UIView = .build { view in
        view.layer.cornerRadius = TPMenuUX.UX.viewCornerRadius
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        view.layer.masksToBounds = true
    }
    private let toggleLabelsContainer: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.distribution = .fill
        stack.alignment = .leading
        stack.axis = .vertical
        stack.spacing = TPMenuUX.UX.headerLabelDistance
    }

    private let toggleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private let toggleSwitch: UISwitch = .build { toggleSwitch in
        toggleSwitch.isEnabled = true
    }

    private let toggleStatusLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    // MARK: Clear Cookies View
    private lazy var clearCookiesButton: TrackingProtectionButton = .build { button in
        button.titleLabel?.textAlignment = .left
        button.titleLabel?.numberOfLines = 0
        button.layer.cornerRadius = TPMenuUX.UX.clearDataButtonCornerRadius
        button.layer.borderWidth = TPMenuUX.UX.clearDataButtonBorderWidth
        button.addTarget(self, action: #selector(self.didTapClearCookiesAndSiteData), for: .touchUpInside)
    }

    // MARK: Protection setting view
    private lazy var settingsLinkButton: LinkButton = .build { button in
        button.titleLabel?.textAlignment = .left
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: #selector(self.protectionSettingsTapped), for: .touchUpInside)
    }

    private var constraints = [NSLayoutConstraint]()

    // MARK: - Variables

    private var viewModel: TrackingProtectionViewModel
    private var hasSetPointOrigin = false
    private var pointOrigin: CGPoint?
    var asPopover = false

    private var toggleContainerShouldBeHidden: Bool {
        return !viewModel.globalETPIsEnabled
    }

    private var protectionViewTopConstraint: NSLayoutConstraint?

    // MARK: - View lifecycle

    init(viewModel: TrackingProtectionViewModel,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if !asPopover {
            addGestureRecognizer()
        }
        setupView()
        listenForThemeChange(view)
        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
        scrollView.delegate = self
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        adjustView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.invalidateIntrinsicContentSize() // Adjusts size based on content.
        if !hasSetPointOrigin {
            hasSetPointOrigin = true
            pointOrigin = self.view.frame.origin
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateViewDetails()
        applyTheme()
    }

    private func setupView() {
        constraints.removeAll()

        setupHeaderView()
        setupContentView()
        setupConnectionHeaderView()
        setupBlockedTrackersView()
        setupConnectionStatusView()
        setupToggleView()
        setupClearCookiesButton()
        setupProtectionSettingsView()
        setupViewActions()

        NSLayoutConstraint.activate(constraints)
        scrollView.setNeedsLayout()
        contentStackView.setNeedsLayout()
        contentStackView.setNeedsDisplay()
        setupAccessibilityIdentifiers()
    }

    // MARK: Header Setup
    private func setupHeaderView() {
//        headerContainer.backgroundColor = .magenta
        headerLabelsContainer.addArrangedSubview(siteDisplayTitleLabel)
        headerLabelsContainer.addArrangedSubview(siteDomainLabel)

        headerContainer.addSubviews(favicon, headerLabelsContainer, closeButton)
        view.addSubview(headerContainer)

        faviconHeightConstraint = favicon.heightAnchor.constraint(equalToConstant: TPMenuUX.UX.faviconImageSize)
        faviconWidthConstraint = favicon.widthAnchor.constraint(equalToConstant: TPMenuUX.UX.faviconImageSize)
        let topDistance = asPopover ? TPMenuUX.UX.popoverTopDistance : 0

        let headerConstraints = [
            headerContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            headerContainer.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: topDistance
            ),

            favicon.leadingAnchor.constraint(
                equalTo: headerContainer.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            favicon.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            faviconHeightConstraint!,
            faviconWidthConstraint!,

            headerLabelsContainer.topAnchor.constraint(
                equalTo: headerContainer.topAnchor,
                constant: TPMenuUX.UX.siteDomainLabelsVerticalSpacing
            ),
            headerLabelsContainer.bottomAnchor.constraint(
                equalTo: headerContainer.bottomAnchor,
                constant: -TPMenuUX.UX.siteDomainLabelsVerticalSpacing
            ),
            headerLabelsContainer.leadingAnchor.constraint(
                equalTo: favicon.trailingAnchor,
                constant: TPMenuUX.UX.siteDomainLabelsVerticalSpacing
            ),
            headerLabelsContainer.trailingAnchor.constraint(
                equalTo: closeButton.leadingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),

            closeButton.trailingAnchor.constraint(
                equalTo: headerContainer.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            closeButton.topAnchor.constraint(
                equalTo: headerContainer.topAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            closeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: TPMenuUX.UX.closeButtonSize),
            closeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: TPMenuUX.UX.closeButtonSize),
        ]

        constraints.append(contentsOf: headerConstraints)
    }

    // MARK: Content View
    private func setupContentView() {
        view.addSubview(scrollView)
        scrollView.addSubview(baseView)

        scrollView.isUserInteractionEnabled = true

        let contentViewContraints = [
            scrollView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
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

    // MARK: Connection Status Header Setup
    private func setupConnectionHeaderView() {
        connectionDetailsLabelsContainer.addArrangedSubview(connectionDetailsTitleLabel)
        connectionDetailsLabelsContainer.addArrangedSubview(connectionDetailsStatusLabel)
        connectionDetailsContentView.addSubviews(foxStatusImage, connectionDetailsLabelsContainer)
        connectionDetailsHeaderView.addSubview(connectionDetailsContentView)

//        contentStackView.addArrangedSubview(connectionDetailsHeaderView)
//        view.addSubview(connectionDetailsHeaderView)
        baseView.addSubviews(connectionDetailsHeaderView)
        let connectionHeaderConstraints = [
//            // Section
            connectionDetailsHeaderView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            connectionDetailsHeaderView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            connectionDetailsHeaderView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor,
                                                             constant: 0),
            // Content
            connectionDetailsContentView.leadingAnchor.constraint(
                equalTo: connectionDetailsHeaderView.leadingAnchor,
                constant: 0// TPMenuUX.UX.connectionDetailsHeaderMargins
            ),
            connectionDetailsContentView.trailingAnchor.constraint(
                equalTo: connectionDetailsHeaderView.trailingAnchor,
                constant: 0// -TPMenuUX.UX.connectionDetailsHeaderMargins
            ),
            connectionDetailsContentView.topAnchor.constraint(equalTo: connectionDetailsHeaderView.topAnchor,
                                                              constant: TPMenuUX.UX.connectionDetailsHeaderMargins),
            connectionDetailsContentView.bottomAnchor.constraint(equalTo: connectionDetailsHeaderView.bottomAnchor,
                                                                 constant: -TPMenuUX.UX.connectionDetailsHeaderMargins / 2),
            // Image
            foxStatusImage.leadingAnchor.constraint(
                equalTo: connectionDetailsContentView.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            foxStatusImage.topAnchor.constraint(
                equalTo: connectionDetailsContentView.topAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            foxStatusImage.heightAnchor.constraint(equalToConstant: TPMenuUX.UX.foxImageSize),
            foxStatusImage.widthAnchor.constraint(equalToConstant: TPMenuUX.UX.foxImageSize),

            // Labels
            connectionDetailsLabelsContainer.topAnchor.constraint(
                equalTo: connectionDetailsContentView.topAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            connectionDetailsLabelsContainer.bottomAnchor.constraint(
                equalTo: connectionDetailsContentView.bottomAnchor,
                constant: -TPMenuUX.UX.connectionDetailsLabelBottomSpacing
            ),
            connectionDetailsLabelsContainer.leadingAnchor.constraint(equalTo: foxStatusImage.trailingAnchor,
                                                                      constant: TPMenuUX.UX.siteDomainLabelsVerticalSpacing),
            connectionDetailsLabelsContainer.trailingAnchor.constraint(equalTo:
                                                                        connectionDetailsContentView.trailingAnchor,
                                                                       constant: -TPMenuUX.UX.horizontalMargin)
        ]

        constraints.append(contentsOf: connectionHeaderConstraints)
    }

    // MARK: Blocked Trackers Setup
    private func setupBlockedTrackersView() {
        trackersView.addSubviews(shieldImage, trackersLabel, trackersDetailArrow, trackersButton, trackersHorizontalLine)
//        view.addSubview(trackersView)
//        contentStackView.addArrangedSubview(trackersView)
        baseView.addSubview(trackersView)
        // Bring subviews to front if necessary
        scrollView.bringSubviewToFront(trackersButton)
        view.bringSubviewToFront(trackersView)
//        scrollView.bringSubviewToFront(toggleSwitch)

        shieldImageHeightConstraint = shieldImage.heightAnchor.constraint(equalToConstant: TPMenuUX.UX.iconSize)
        trackersArrowHeightConstraint = trackersDetailArrow.heightAnchor.constraint(
            equalToConstant: TPMenuUX.UX.iconSize
        )

        let blockedTrackersConstraints = [
            trackersView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            trackersView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            trackersView.topAnchor.constraint(equalTo: connectionDetailsHeaderView.bottomAnchor, constant: 0),

            shieldImage.leadingAnchor.constraint(
                equalTo: trackersView.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            shieldImage.centerYAnchor.constraint(equalTo: trackersView.centerYAnchor),
            shieldImage.heightAnchor.constraint(equalTo: shieldImage.widthAnchor),
            shieldImageHeightConstraint!,
            trackersLabel.leadingAnchor.constraint(
                equalTo: shieldImage.trailingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            trackersLabel.topAnchor.constraint(equalTo: trackersView.topAnchor, constant: 11),
            trackersLabel.bottomAnchor.constraint(equalTo: trackersView.bottomAnchor, constant: -11),
            trackersLabel.trailingAnchor.constraint(
                equalTo: trackersDetailArrow.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),

            trackersDetailArrow.trailingAnchor.constraint(
                equalTo: connectionView.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            trackersDetailArrow.centerYAnchor.constraint(equalTo: trackersView.centerYAnchor),
            trackersArrowHeightConstraint!,
            trackersDetailArrow.widthAnchor.constraint(equalTo: trackersDetailArrow.heightAnchor),

            trackersButton.leadingAnchor.constraint(equalTo: trackersView.leadingAnchor),
            trackersButton.topAnchor.constraint(equalTo: trackersView.topAnchor),
            trackersButton.trailingAnchor.constraint(equalTo: trackersView.trailingAnchor),
            trackersButton.bottomAnchor.constraint(equalTo: trackersView.bottomAnchor),

            trackersHorizontalLine.leadingAnchor.constraint(equalTo: trackersLabel.leadingAnchor),
            trackersHorizontalLine.trailingAnchor.constraint(equalTo: trackersView.trailingAnchor,
                                                             constant: -TPMenuUX.UX.connectionDetailsHeaderMargins),
            trackersHorizontalLine.heightAnchor.constraint(equalToConstant: TPMenuUX.UX.Line.height),
            trackersView.bottomAnchor.constraint(equalTo: trackersHorizontalLine.bottomAnchor),
        ]

        constraints.append(contentsOf: blockedTrackersConstraints)
    }

    // MARK: Connection Status Setup
    private func setupConnectionStatusView() {
        connectionView.addSubviews(connectionStatusImage, connectionStatusLabel, connectionDetailArrow)
        connectionView.addSubviews(connectionButton, connectionHorizontalLine)
//        view.addSubview(connectionView)
//        contentStackView.addArrangedSubview(connectionView)
        baseView.addSubviews(connectionView)

        lockImageHeightConstraint = connectionStatusImage.widthAnchor.constraint(
            equalToConstant: TPMenuUX.UX.iconSize
        )
        connectionArrowHeightConstraint = connectionDetailArrow.heightAnchor.constraint(
            equalToConstant: TPMenuUX.UX.iconSize
        )
        let connectionConstraints = [
            connectionView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            connectionView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            connectionView.topAnchor.constraint(equalTo: trackersView.bottomAnchor, constant: 0),

            connectionStatusImage.leadingAnchor.constraint(
                equalTo: connectionView.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            connectionStatusImage.centerYAnchor.constraint(equalTo: connectionView.centerYAnchor),
            lockImageHeightConstraint!,
            connectionStatusImage.heightAnchor.constraint(equalTo: connectionView.widthAnchor),

            connectionStatusLabel.leadingAnchor.constraint(
                equalTo: connectionStatusImage.trailingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            connectionStatusLabel.topAnchor.constraint(equalTo: connectionView.topAnchor, constant: 11),
            connectionStatusLabel.bottomAnchor.constraint(equalTo: connectionView.bottomAnchor, constant: -11),
            connectionStatusLabel.trailingAnchor.constraint(
                equalTo: connectionDetailArrow.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),

            connectionDetailArrow.trailingAnchor.constraint(
                equalTo: connectionView.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            connectionDetailArrow.centerYAnchor.constraint(equalTo: connectionView.centerYAnchor),
            connectionArrowHeightConstraint!,
            connectionDetailArrow.widthAnchor.constraint(equalTo: connectionDetailArrow.heightAnchor),

            connectionButton.leadingAnchor.constraint(equalTo: connectionView.leadingAnchor),
            connectionButton.topAnchor.constraint(equalTo: connectionView.topAnchor),
            connectionButton.trailingAnchor.constraint(equalTo: connectionView.trailingAnchor),
            connectionButton.bottomAnchor.constraint(equalTo: connectionView.bottomAnchor),

            connectionHorizontalLine.leadingAnchor.constraint(equalTo: connectionView.leadingAnchor),
            connectionHorizontalLine.trailingAnchor.constraint(equalTo: connectionView.trailingAnchor),
            connectionHorizontalLine.heightAnchor.constraint(equalToConstant: TPMenuUX.UX.Line.height),
            connectionView.bottomAnchor.constraint(equalTo: connectionHorizontalLine.bottomAnchor),
        ]

        constraints.append(contentsOf: connectionConstraints)
    }

    // MARK: Toggle View Setup
    private func setupToggleView() {
        toggleLabelsContainer.addArrangedSubview(toggleLabel)
        toggleLabelsContainer.addArrangedSubview(toggleStatusLabel)
//        toggleLabelsContainer.backgroundColor = .green
        toggleView.addSubviews(toggleLabelsContainer, toggleSwitch)
        toggleContainer.addSubviews(toggleView)
        baseView.addSubviews(toggleContainer)
//        view.addSubview(toggleContainer)
//        contentStackView.addArrangedSubview(toggleContainer)

        let toggleConstraints = [
            toggleContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toggleContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toggleContainer.topAnchor.constraint(
                equalTo: connectionView.bottomAnchor,
                constant: 0
            ),

            toggleView.leadingAnchor.constraint(
                equalTo: toggleContainer.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            toggleView.trailingAnchor.constraint(
                equalTo: toggleContainer.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            toggleView.topAnchor.constraint(equalTo: toggleContainer.topAnchor),

            toggleLabelsContainer.leadingAnchor.constraint(
                equalTo: toggleView.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            toggleLabelsContainer.trailingAnchor.constraint(
                equalTo: toggleSwitch.leadingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            toggleLabelsContainer.topAnchor.constraint(
                equalTo: toggleView.topAnchor,
                constant: 11
            ),
            toggleLabelsContainer.bottomAnchor.constraint(
                equalTo: toggleView.bottomAnchor,
                constant: -11
            ),

            toggleSwitch.centerYAnchor.constraint(equalTo: toggleView.centerYAnchor),
            toggleSwitch.trailingAnchor.constraint(
                equalTo: toggleView.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            )
        ]

        constraints.append(contentsOf: toggleConstraints)
    }

    // MARK: Clear Cookies Button Setup
    private func setupClearCookiesButton() {
        let clearCookiesViewModel = TrackingProtectionButtonViewModel(title: viewModel.clearCookiesButtonTitle,
                                                                      a11yIdentifier: viewModel.clearCookiesButtonA11yId)
        clearCookiesButton.configure(viewModel: clearCookiesViewModel)

//        view.addSubview(clearCookiesButton)
//        contentStackView.addArrangedSubview(clearCookiesButton)
        baseView.addSubview(clearCookiesButton)
        view.bringSubviewToFront(clearCookiesButton)

        let clearCookiesButtonConstraints = [
            clearCookiesButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            clearCookiesButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            clearCookiesButton.topAnchor.constraint(
                equalTo: toggleView.bottomAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            clearCookiesButton.bottomAnchor.constraint(
                equalTo: settingsLinkButton.topAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
        ]
        constraints.append(contentsOf: clearCookiesButtonConstraints)
    }

    // MARK: Settings View Setup
    private func setupProtectionSettingsView() {
        let settingsButtonViewModel = LinkButtonViewModel(title: viewModel.settingsButtonTitle,
                                                          a11yIdentifier: viewModel.settingsA11yId)
        settingsLinkButton.configure(viewModel: settingsButtonViewModel)
//        view.addSubview(settingsLinkButton)
//        contentStackView.addArrangedSubview(settingsLinkButton)
        baseView.addSubviews(settingsLinkButton)

        let protectionConstraints = [
            settingsLinkButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            settingsLinkButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            settingsLinkButton.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -TPMenuUX.UX.settingsLinkButtonBottomSpacing
            ),
        ]

        constraints.append(contentsOf: protectionConstraints)
    }

    private func updateViewDetails() {
        favicon.setFavicon(FaviconImageViewModel(siteURLString: viewModel.url.absoluteString,
                                                 faviconCornerRadius: TPMenuUX.UX.faviconCornerRadius))

        siteDomainLabel.text = viewModel.websiteTitle
        siteDisplayTitleLabel.text = viewModel.displayTitle
        trackersLabel.text = String(format: .Menu.EnhancedTrackingProtection.trackersBlockedLabel,
                                    viewModel.trackersBlocked)
        shieldImage.image = UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.shield)
            .withRenderingMode(.alwaysTemplate)
        connectionStatusLabel.text = viewModel.connectionStatusString
        toggleSwitch.isOn = viewModel.isSiteETPEnabled
        toggleLabel.text = .Menu.EnhancedTrackingProtection.switchTitle
        toggleStatusLabel.text = toggleSwitch.isOn ?
            .Menu.EnhancedTrackingProtection.switchOnText : .Menu.EnhancedTrackingProtection.switchOffText
        connectionDetailsTitleLabel.text = viewModel.connectionDetailsTitle
        connectionDetailsStatusLabel.text = viewModel.connectionDetailsHeader
        foxStatusImage.image = viewModel.connectionDetailsImage
    }

    private func setupViewActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        connectionButton.addTarget(self, action: #selector(connectionDetailsTapped), for: .touchUpInside)
        trackersButton.addTarget(self, action: #selector(blockedTrackersTapped), for: .touchUpInside)
        toggleSwitch.addTarget(self, action: #selector(trackingProtectionToggleTapped), for: .valueChanged)
    }

    // MARK: Notifications
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            adjustLayout()
        default: break
        }
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

    func adjustView() {
        contentStackView.removeAllArrangedViews()
        let blueView = UIView()
        blueView.backgroundColor = .blue
        blueView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(blueView)
    }

    // MARK: Accessibility
    private func setupAccessibilityIdentifiers() {
        foxStatusImage.accessibilityIdentifier = viewModel.foxImageA11yId
        trackersDetailArrow.accessibilityIdentifier = viewModel.arrowImageA11yId
        trackersLabel.accessibilityIdentifier = viewModel.trackersBlockedLabelA11yId
        connectionDetailArrow.accessibilityIdentifier = viewModel.arrowImageA11yId
        shieldImage.accessibilityIdentifier = viewModel.shieldImageA11yId
        connectionStatusLabel.accessibilityIdentifier = viewModel.securityStatusLabelA11yId
        toggleLabel.accessibilityIdentifier = viewModel.toggleViewTitleLabelA11yId
        toggleStatusLabel.accessibilityIdentifier = viewModel.toggleViewBodyLabelA11yId
        clearCookiesButton.accessibilityIdentifier = viewModel.clearCookiesButtonA11yId
        settingsLinkButton.accessibilityIdentifier = viewModel.settingsA11yId
        headerLabelsContainer.accessibilityIdentifier = "HeaderLabelsStackView"
        contentStackView.accessibilityIdentifier = "ContentStackView"
        headerContainer.accessibilityIdentifier = "HeaderContainer"
        connectionDetailsHeaderView.accessibilityIdentifier = "ConnectionDetailsHeaderView"
        connectionDetailsContentView.accessibilityIdentifier = "ConnectionDetailsContentView"
        connectionView.accessibilityIdentifier = "ConnectionView"
        self.view.accessibilityIdentifier = "TrackingProtectionView"
    }

    private func adjustLayout() {
        let faviconSize = TPMenuUX.UX.faviconImageSize // to avoid line length warnings
        let iconSize = TPMenuUX.UX.iconSize
        faviconHeightConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: faviconSize), 2 * faviconSize)
        faviconWidthConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: faviconSize), 2 * faviconSize)

        shieldImageHeightConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: iconSize), 2 * iconSize)
        trackersArrowHeightConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: iconSize), 2 * iconSize)

        lockImageHeightConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: iconSize), 2 * iconSize)
        connectionArrowHeightConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: iconSize), 2 * iconSize)

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    // MARK: - Button actions
    @objc
    func closeButtonTapped() {
        enhancedTrackingProtectionMenuDelegate?.didFinish()
    }

    @objc
    func connectionDetailsTapped() {
        let detailsVC = TrackingProtectionDetailsViewController(with: viewModel.getDetailsViewModel(),
                                                                windowUUID: windowUUID)
        detailsVC.modalPresentationStyle = .pageSheet
        self.present(detailsVC, animated: true)
    }

    @objc
    func blockedTrackersTapped() {
        let blockedTrackersVC = BlockedTrackersViewController(with: viewModel.getBlockedTrackersViewModel(),
                                                              windowUUID: windowUUID)
        blockedTrackersVC.modalPresentationStyle = .pageSheet
        self.present(blockedTrackersVC, animated: true)
    }

    @objc
    func trackingProtectionToggleTapped() {
        // site is safelisted if site ETP is disabled
        viewModel.toggleSiteSafelistStatus()
        toggleStatusLabel.text = toggleSwitch.isOn ? .ETPOn : .ETPOff
    }

    @objc
    private func didTapClearCookiesAndSiteData() {
        viewModel.onTapClearCookiesAndSiteData(controller: self)
    }

    @objc
    func protectionSettingsTapped() {
        enhancedTrackingProtectionMenuDelegate?.settingsOpenPage(settings: .contentBlocker)
    }

    // MARK: - Gesture Recognizer
    private func addGestureRecognizer() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction))
        view.addGestureRecognizer(panGesture)
    }

    @objc
    func panGestureRecognizerAction(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        let originalYPosition = self.view.frame.origin.y
        let originalXPosition = self.view.frame.origin.x

        // Not allowing the user to drag the view upward
        guard translation.y >= 0 else { return }

        // Setting x based on window calculation because we don't want
        // users to move the frame side ways, only straight up or down
        view.frame.origin = CGPoint(x: originalXPosition,
                                    y: self.pointOrigin!.y + translation.y)

        if sender.state == .ended {
            let dragVelocity = sender.velocity(in: view)
            if dragVelocity.y >= 1300 {
                enhancedTrackingProtectionMenuDelegate?.didFinish()
            } else {
                // Set back to original position of the view controller
                UIView.animate(withDuration: 0.3) {
                    self.view.frame.origin = self.pointOrigin ?? CGPoint(x: originalXPosition, y: originalYPosition)
                }
            }
        }
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    func willDismiss() {
    }
}

// MARK: - Themable
extension TrackingProtectionViewController {
    func applyTheme() {
        let theme = currentTheme()
        overrideUserInterfaceStyle = theme.type.getInterfaceStyle()
        view.backgroundColor = theme.colors.layer1
        closeButton.backgroundColor = theme.colors.layer2
        let buttonImage = UIImage(named: StandardImageIdentifiers.Medium.cross)?
            .tinted(withColor: theme.colors.iconSecondary)
        closeButton.setImage(buttonImage, for: .normal)
        connectionDetailsHeaderView.backgroundColor = theme.colors.layer2
        connectionDetailsContentView.backgroundColor = theme.colors.layerAccentPrivateNonOpaque
        trackersView.backgroundColor = theme.colors.layer2
        trackersDetailArrow.tintColor = theme.colors.iconSecondary
        shieldImage.tintColor = theme.colors.iconPrimary
        connectionView.backgroundColor = theme.colors.layer2
        connectionDetailArrow.tintColor = theme.colors.iconSecondary
        connectionStatusImage.image = viewModel.getConnectionStatusImage(themeType: theme.type)
        headerContainer.tintColor = theme.colors.layer2
        siteDomainLabel.textColor = theme.colors.textSecondary
        siteDisplayTitleLabel.textColor = theme.colors.textPrimary
        if viewModel.connectionSecure {
            connectionStatusImage.tintColor = theme.colors.iconPrimary
        }
        toggleView.backgroundColor = theme.colors.layer2
        toggleSwitch.tintColor = theme.colors.actionPrimary
        toggleSwitch.onTintColor = theme.colors.actionPrimary
        toggleStatusLabel.textColor = theme.colors.textSecondary

        trackersHorizontalLine.backgroundColor = theme.colors.borderPrimary
        connectionHorizontalLine.backgroundColor = theme.colors.borderPrimary

        clearCookiesButton.applyTheme(theme: theme)
        clearCookiesButton.layer.borderColor = theme.colors.borderPrimary.cgColor
        settingsLinkButton.applyTheme(theme: theme)
        setNeedsStatusBarAppearanceUpdate()
    }
}
