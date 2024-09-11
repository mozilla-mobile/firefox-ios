// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import SiteImageView

class EnhancedTrackingProtectionDetailsVC: UIViewController, Themeable {
    // MARK: - UI
    private let scrollView: UIScrollView = .build { scrollView in }
    private let baseView: UIView = .build { view in }
    private let siteTitleLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.websiteTitle
    }

    private var closeButton: UIButton = .build { button in
        button.layer.cornerRadius = 0.5 * ETPMenuUX.UX.closeButtonSize
        button.clipsToBounds = true
        button.setTitle(.AppSettingsDone, for: .normal)
        button.titleLabel?.font = ETPMenuUX.Fonts.viewTitleLabels
    }

    private let siteInfoSection = ETPSectionView(frame: .zero)
    private let siteInfoImage: FaviconImageView = .build { _ in }

    private var siteInfoTitleLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.viewTitleLabels
        label.numberOfLines = 0
    }

    private var siteInfoURLLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.minorInfoLabel
        label.numberOfLines = 0
    }

    private let connectionView = ETPSectionView(frame: .zero)

    private let connectionImage: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
        image.layer.cornerRadius = 5
    }

    private let connectionStatusLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.viewTitleLabels
    }

    // MARK: - Variables

    var viewModel: EnhancedTrackingProtectionDetailsVM
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { return windowUUID }

    // MARK: - View Lifecycle

    init(with viewModel: EnhancedTrackingProtectionDetailsVM,
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
        view.addSubview(scrollView)
        scrollView.addSubview(baseView)
        baseView.addSubviews(siteTitleLabel, closeButton)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        siteInfoSection.addSubviews(siteInfoImage, siteInfoTitleLabel, siteInfoURLLabel)
        baseView.addSubview(siteInfoSection)

        connectionView.addSubviews(connectionImage, connectionStatusLabel)
        baseView.addSubview(connectionView)

        NSLayoutConstraint.activate(
            [
                scrollView.topAnchor.constraint(equalTo: view.topAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                baseView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                baseView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                baseView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
                baseView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                siteTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                siteTitleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),

                closeButton.trailingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                    constant: -ETPMenuUX.UX.gutterDistance
                ),
                closeButton.topAnchor.constraint(equalTo: baseView.topAnchor, constant: ETPMenuUX.UX.gutterDistance),

                siteInfoSection.leadingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                    constant: ETPMenuUX.UX.gutterDistance
                ),
                siteInfoSection.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 33),
                siteInfoSection.trailingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                    constant: -ETPMenuUX.UX.gutterDistance
                ),
                siteInfoSection.bottomAnchor.constraint(equalTo: siteInfoURLLabel.bottomAnchor, constant: 12),

                siteInfoImage.leadingAnchor.constraint(equalTo: siteInfoSection.leadingAnchor, constant: 13),
                siteInfoImage.topAnchor.constraint(equalTo: siteInfoSection.topAnchor, constant: 13),
                siteInfoImage.heightAnchor.constraint(equalToConstant: ETPMenuUX.UX.faviconImageSize),
                siteInfoImage.widthAnchor.constraint(equalToConstant: ETPMenuUX.UX.faviconImageSize),

                siteInfoTitleLabel.leadingAnchor.constraint(equalTo: siteInfoImage.trailingAnchor, constant: 11),
                siteInfoTitleLabel.topAnchor.constraint(equalTo: siteInfoSection.topAnchor, constant: 13),
                siteInfoTitleLabel.trailingAnchor.constraint(equalTo: siteInfoSection.trailingAnchor, constant: -21),

                siteInfoURLLabel.leadingAnchor.constraint(equalTo: siteInfoTitleLabel.leadingAnchor),
                siteInfoURLLabel.topAnchor.constraint(equalTo: siteInfoTitleLabel.bottomAnchor, constant: 2),
                siteInfoURLLabel.trailingAnchor.constraint(equalTo: siteInfoSection.trailingAnchor, constant: -21),

                connectionView.leadingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                    constant: ETPMenuUX.UX.gutterDistance
                ),
                connectionView.topAnchor.constraint(equalTo: siteInfoSection.bottomAnchor, constant: 36),
                connectionView.bottomAnchor.constraint(equalTo: baseView.bottomAnchor),
                connectionView.trailingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                    constant: -ETPMenuUX.UX.gutterDistance
                ),
                connectionView.heightAnchor.constraint(equalToConstant: 60),

                connectionImage.centerYAnchor.constraint(equalTo: connectionView.centerYAnchor),
                connectionImage.leadingAnchor.constraint(equalTo: connectionView.leadingAnchor, constant: 20),
                connectionImage.heightAnchor.constraint(equalToConstant: 20),
                connectionImage.widthAnchor.constraint(equalToConstant: 20),

                connectionStatusLabel.leadingAnchor.constraint(equalTo: connectionImage.trailingAnchor, constant: 28),
                connectionStatusLabel.trailingAnchor.constraint(equalTo: connectionView.trailingAnchor, constant: -21),
                connectionStatusLabel.heightAnchor.constraint(equalToConstant: 22),
                connectionStatusLabel.centerYAnchor.constraint(equalTo: connectionView.centerYAnchor)
            ]
        )
    }

    private func updateViewDetails() {
        siteTitleLabel.text = viewModel.topLevelDomain
        siteInfoTitleLabel.text = viewModel.title
        siteInfoURLLabel.text = viewModel.URL
        connectionStatusLabel.text = viewModel.connectionStatusMessage
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
extension EnhancedTrackingProtectionDetailsVC {
    func applyTheme() {
        let theme = currentTheme()
        overrideUserInterfaceStyle = theme.type.getInterfaceStyle()
        view.backgroundColor =  theme.colors.layer1
        siteTitleLabel.textColor = theme.colors.textPrimary
        siteInfoTitleLabel.textColor = theme.colors.textPrimary
        connectionStatusLabel.textColor = theme.colors.textPrimary
        siteInfoSection.backgroundColor = theme.colors.layer2
        siteInfoURLLabel.textColor = theme.colors.textSecondary
        connectionView.backgroundColor = theme.colors.layer2
        if viewModel.connectionSecure {
            connectionImage.tintColor = theme.colors.iconPrimary
        }
        closeButton.setTitleColor(theme.colors.actionPrimary, for: .normal)
        connectionImage.image = viewModel.getLockIcon(theme.type)

        siteInfoImage.setFavicon(FaviconImageViewModel(siteURLString: viewModel.URL,
                                                       faviconCornerRadius: ETPMenuUX.UX.faviconCornerRadius))

        setNeedsStatusBarAppearanceUpdate()
    }
}
