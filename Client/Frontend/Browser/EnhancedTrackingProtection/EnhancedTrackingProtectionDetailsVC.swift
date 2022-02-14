// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

class EnhancedTrackingProtectionDetailsVC: UIViewController {

    // MARK: - UI

    private let siteTitleLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.websiteTitle
    }

    private var closeButton: UIButton = .build { button in
        button.layer.cornerRadius = 0.5 * ETPMenuUX.UX.closeButtonSize
        button.clipsToBounds = true
        button.setTitle(.AppSettingsDone, for: .normal)
        button.titleLabel?.font = ETPMenuUX.Fonts.viewTitleLabels
        button.setTitleColor(.systemBlue, for: .normal)
    }

    private let siteInfoSection = ETPSectionView(frame: .zero)

    private let siteInfoImage: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
        image.layer.cornerRadius = 5
    }

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

    private let connectionVerifierLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.minorInfoLabel
        label.isHidden = true
    }

    // MARK: - Variables
    var viewModel: EnhancedTrackingProtectionDetailsVM
    var notificationCenter: NotificationCenter

    // MARK: - View Lifecycle

    init(with viewModel: EnhancedTrackingProtectionDetailsVM,
         and notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.viewModel = viewModel
        self.notificationCenter = notificationCenter
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
        setupNotifications(forObserver: self, observing: [.DisplayThemeChanged])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateViewDetails()
        applyTheme()
    }

    private func setupView() {
        view.addSubviews(siteTitleLabel, closeButton)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        siteInfoSection.addSubviews(siteInfoImage, siteInfoTitleLabel, siteInfoURLLabel)
        view.addSubview(siteInfoSection)

        connectionView.addSubviews(connectionImage, connectionStatusLabel, connectionVerifierLabel)
        view.addSubview(connectionView)

        NSLayoutConstraint.activate([
            siteTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            siteTitleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ETPMenuUX.UX.gutterDistance),
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: ETPMenuUX.UX.gutterDistance),

            siteInfoSection.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            siteInfoSection.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 33),
            siteInfoSection.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ETPMenuUX.UX.gutterDistance),
            siteInfoSection.bottomAnchor.constraint(equalTo: siteInfoURLLabel.bottomAnchor, constant: 12),

            siteInfoImage.leadingAnchor.constraint(equalTo: siteInfoSection.leadingAnchor, constant: 13),
            siteInfoImage.topAnchor.constraint(equalTo: siteInfoSection.topAnchor, constant: 13),
            siteInfoImage.heightAnchor.constraint(equalToConstant: ETPMenuUX.UX.heroImageSize),
            siteInfoImage.widthAnchor.constraint(equalToConstant: ETPMenuUX.UX.heroImageSize),

            siteInfoTitleLabel.leadingAnchor.constraint(equalTo: siteInfoImage.trailingAnchor, constant: 11),
            siteInfoTitleLabel.topAnchor.constraint(equalTo: siteInfoSection.topAnchor, constant: 13),
            siteInfoTitleLabel.trailingAnchor.constraint(equalTo: siteInfoSection.trailingAnchor, constant: -21),

            siteInfoURLLabel.leadingAnchor.constraint(equalTo: siteInfoTitleLabel.leadingAnchor),
            siteInfoURLLabel.topAnchor.constraint(equalTo: siteInfoTitleLabel.bottomAnchor, constant: 2),
            siteInfoURLLabel.trailingAnchor.constraint(equalTo: siteInfoSection.trailingAnchor, constant: -21),

            connectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            connectionView.topAnchor.constraint(equalTo: siteInfoSection.bottomAnchor, constant: 36),
            connectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ETPMenuUX.UX.gutterDistance),
            connectionView.heightAnchor.constraint(equalToConstant: 60),

            connectionImage.centerYAnchor.constraint(equalTo: connectionView.centerYAnchor),
            connectionImage.leadingAnchor.constraint(equalTo: connectionView.leadingAnchor, constant: 20),
            connectionImage.heightAnchor.constraint(equalToConstant: 20),
            connectionImage.widthAnchor.constraint(equalToConstant: 20),

            connectionStatusLabel.leadingAnchor.constraint(equalTo: connectionImage.trailingAnchor, constant: 28),
//            connectionStatusLabel.topAnchor.constraint(equalTo: connectionView.topAnchor, constant: 8),
            connectionStatusLabel.trailingAnchor.constraint(equalTo: connectionView.trailingAnchor, constant: -21),
            connectionStatusLabel.heightAnchor.constraint(equalToConstant: 22),
            connectionStatusLabel.centerYAnchor.constraint(equalTo: connectionView.centerYAnchor)

//            connectionVerifierLabel.leadingAnchor.constraint(equalTo: connectionStatusLabel.leadingAnchor),
//            connectionVerifierLabel.bottomAnchor.constraint(equalTo: connectionView.bottomAnchor, constant: -8),
//            connectionVerifierLabel.trailingAnchor.constraint(equalTo: connectionView.trailingAnchor, constant: -21),
//            connectionVerifierLabel.heightAnchor.constraint(equalToConstant: 20),
        ])
    }

    private func updateViewDetails() {
        siteTitleLabel.text = viewModel.topLevelDomain
        siteInfoImage.image = viewModel.image
        siteInfoTitleLabel.text = viewModel.title
        siteInfoURLLabel.text = viewModel.URL
        connectionStatusLabel.text = viewModel.connectionStatusMessage
        connectionVerifierLabel.text = viewModel.connectionVerifier
        connectionImage.image = viewModel.lockIcon
    }

    // MARK: - Actions

    @objc func closeButtonTapped() {
        self.dismiss(animated: true)
    }
}

// MARK: - Themable
extension EnhancedTrackingProtectionDetailsVC: NotificationThemeable {
    @objc func applyTheme() {
        overrideUserInterfaceStyle =  LegacyThemeManager.instance.userInterfaceStyle
        view.backgroundColor = UIColor.theme.etpMenu.background
        siteInfoSection.backgroundColor = UIColor.theme.etpMenu.sectionColor
        siteInfoURLLabel.textColor = UIColor.theme.etpMenu.subtextColor
        connectionView.backgroundColor = UIColor.theme.etpMenu.sectionColor
        if viewModel.connectionSecure {
            connectionImage.tintColor = UIColor.theme.etpMenu.defaultImageTints
        }
        connectionVerifierLabel.textColor = UIColor.theme.etpMenu.subtextColor
        setNeedsStatusBarAppearanceUpdate()
    }
}

// MARK: - Notifiable
extension EnhancedTrackingProtectionDetailsVC: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
}
