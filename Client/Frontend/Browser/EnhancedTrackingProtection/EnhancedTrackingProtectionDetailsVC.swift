//
//  EnhancedTrackingProtectionDetalsVC.swift
//  Client
//
//  Created by Roux Buciu on 2021-08-04.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import Foundation

class EnhancedTrackingProtectionDetailsVC: UIViewController {

    // MARK: - UI

    let siteTitleLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.websiteTitle
    }

    var closeButton: UIButton = .build { button in
        button.layer.cornerRadius = 0.5 * ETPMenuUX.UX.closeButtonSize
        button.clipsToBounds = true
        button.setTitle(.AppSettingsDone, for: .normal)
        button.titleLabel?.font = ETPMenuUX.Fonts.viewTitleLabels
        button.setTitleColor(.systemBlue, for: .normal)
    }

    let siteInfoSection = ETPSectionView(frame: .zero)

    let siteInfoImage: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
        image.layer.cornerRadius = 5
    }

    var siteInfoTitleLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.viewTitleLabels
        label.numberOfLines = 0
    }

    var siteInfoURLLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.minorInfoLabel
        label.numberOfLines = 0
    }

    let connectionView = ETPSectionView(frame: .zero)

    let connectionImage: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
        image.layer.cornerRadius = 5
    }

    let connectionStatusLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.viewTitleLabels
    }

    let connectionVerifierLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.minorInfoLabel
    }

    // MARK: - Variables
    var viewModel: EnhancedTrackingProtectionDetailsVM

    // MARK: - View Lifecycle

    init(viewModel: EnhancedTrackingProtectionDetailsVM) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateViewDetails()
        applyTheme()
    }

    private func setupView() {
        view.addSubview(siteTitleLabel)
        view.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        siteInfoSection.addSubview(siteInfoImage)
        siteInfoSection.addSubview(siteInfoTitleLabel)
        siteInfoSection.addSubview(siteInfoURLLabel)
        view.addSubview(siteInfoSection)

        connectionView.addSubview(connectionImage)
        connectionView.addSubview(connectionStatusLabel)
        connectionView.addSubview(connectionVerifierLabel)
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
            connectionStatusLabel.topAnchor.constraint(equalTo: connectionView.topAnchor, constant: 8),
            connectionStatusLabel.trailingAnchor.constraint(equalTo: connectionView.trailingAnchor, constant: -21),
            connectionStatusLabel.heightAnchor.constraint(equalToConstant: 22),

            connectionVerifierLabel.leadingAnchor.constraint(equalTo: connectionStatusLabel.leadingAnchor),
            connectionVerifierLabel.bottomAnchor.constraint(equalTo: connectionView.bottomAnchor, constant: -8),
            connectionVerifierLabel.trailingAnchor.constraint(equalTo: connectionView.trailingAnchor, constant: -21),
            connectionVerifierLabel.heightAnchor.constraint(equalToConstant: 20),
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
extension EnhancedTrackingProtectionDetailsVC: Themeable {
    @objc func applyTheme() {
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle =  ThemeManager.instance.userInterfaceStyle
        }
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
