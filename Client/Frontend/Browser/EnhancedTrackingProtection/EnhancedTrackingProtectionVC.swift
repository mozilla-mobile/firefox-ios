/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit

struct ETPMenuUX {
    struct Fonts {
        static let websiteTitle: UIFont = .systemFont(ofSize: 17, weight: .semibold)
        static let viewTitleLabels: UIFont = .systemFont(ofSize: 17, weight: .regular)
        static let detailsLabel: UIFont = .systemFont(ofSize: 12, weight: .regular)
        static let minorInfoLabel: UIFont = .systemFont(ofSize: 15, weight: .regular)
    }

    struct UX {
        static let gutterDistance: CGFloat = 16
        static let viewCornerRadius: CGFloat = 8
        static let viewHeight: CGFloat = 44
        static let websiteLabelToHeroImageSpacing: CGFloat = 8
        static let heroImageSize: CGFloat = 40
        static let closeButtonSize: CGFloat = 30

        struct Line {
            static let distanceFromHeroImage: CGFloat = 15
            static let height: CGFloat = 1
        }
    }
}

class ETPSectionView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = ETPMenuUX.UX.viewCornerRadius
    }
}

class EnhancedTrackingProtectionMenuVC: UIViewController {

    // MARK: UI components

    // Header View
    var heroImage: UIImageView = .build { heroImage in
        heroImage.contentMode = .scaleAspectFit
        heroImage.clipsToBounds = true
        heroImage.layer.masksToBounds = true
        heroImage.layer.cornerRadius = 5
    }

    let siteDomainLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.websiteTitle
    }

    var closeButton: UIButton = .build { button in
        button.backgroundColor = .Photon.LightGrey50
        button.layer.cornerRadius = 0.5 * ETPMenuUX.UX.closeButtonSize
        button.clipsToBounds = true
        button.setImage(UIImage(named: "close-medium"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
    }

    let horizontalLine: UIView = .build { line in
        line.backgroundColor = UIColor.theme.etpMenu.horizontalLine
    }

    // Connection Info view
    let connectionView = ETPSectionView(frame: .zero)

    let connectionImage: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
        image.layer.cornerRadius = 5
    }

    let connectionLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.viewTitleLabels
    }

    let connectionDetailArrow: UIImageView = .build { image in
        image.image = UIImage(imageLiteralResourceName: "goBack").withRenderingMode(.alwaysTemplate)
        image.transform = CGAffineTransform(rotationAngle: .pi)
    }

    let connectionButton: UIButton = .build { button in }

    // TrackingProtection toggle View
    let toggleContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    let toggleView: UIView = ETPSectionView(frame: .zero)

    let toggleLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.viewTitleLabels
    }

    let toggleSwitch: UISwitch = .build { toggleSwitch in
        toggleSwitch.isEnabled = true
        toggleSwitch.onTintColor = .systemBlue
    }

    let toggleStatusLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.detailsLabel
    }

    // Protection setting view
    let protectionView: UIView = ETPSectionView(frame: .zero)

    var protectionButton: UIButton = .build { button in
        button.setTitle(Strings.TPProtectionSettings, for: .normal)
        button.titleLabel?.font = ETPMenuUX.Fonts.viewTitleLabels
        button.setTitleColor(.systemBlue, for: .normal)
        button.contentHorizontalAlignment = .left
    }

    var constraints = [NSLayoutConstraint]()

    // MARK: - Variables

    var viewModel: EnhancedTrackingProtectionMenuVM
    var hasSetPointOrigin = false
    var pointOrigin: CGPoint?

    var toggleContainerShouldBeHidden: Bool {
        return !viewModel.globalETPIsEnabled
    }

    var protectionViewTopConstraint: NSLayoutConstraint?

    // MARK: - View lifecycle

    init(viewModel: EnhancedTrackingProtectionMenuVM) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addGestureRecognizer()
        setupView()
    }

    override func viewDidLayoutSubviews() {
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
        setupConnectionStatusView()
        setupToggleView()
        setupProtectionSettingsView()
        setupViewActions()

        NSLayoutConstraint.activate(constraints)
    }

    private func setupHeaderView() {
        view.addSubview(heroImage)
        view.addSubview(siteDomainLabel)
        view.addSubview(closeButton)
        view.addSubview(horizontalLine)

        let headerConstraints = [
            heroImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            heroImage.topAnchor.constraint(equalTo: view.topAnchor, constant: ETPMenuUX.UX.gutterDistance),
            heroImage.widthAnchor.constraint(equalToConstant: ETPMenuUX.UX.heroImageSize),
            heroImage.heightAnchor.constraint(equalToConstant: ETPMenuUX.UX.heroImageSize),

            siteDomainLabel.centerYAnchor.constraint(equalTo: heroImage.centerYAnchor),
            siteDomainLabel.leadingAnchor.constraint(equalTo: heroImage.trailingAnchor, constant: 8),
            siteDomainLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -15),

            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ETPMenuUX.UX.gutterDistance),
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: ETPMenuUX.UX.gutterDistance),
            closeButton.heightAnchor.constraint(equalToConstant: ETPMenuUX.UX.closeButtonSize),
            closeButton.widthAnchor.constraint(equalToConstant: ETPMenuUX.UX.closeButtonSize),

            horizontalLine.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            horizontalLine.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            horizontalLine.topAnchor.constraint(equalTo: heroImage.bottomAnchor, constant: ETPMenuUX.UX.Line.distanceFromHeroImage),
            horizontalLine.heightAnchor.constraint(equalToConstant: ETPMenuUX.UX.Line.height)
        ]

        constraints.append(contentsOf: headerConstraints)
    }

    private func setupConnectionStatusView() {
        // Connection View
        connectionView.addSubview(connectionImage)
        connectionView.addSubview(connectionLabel)
        connectionView.addSubview(connectionDetailArrow)
        connectionView.addSubview(connectionButton)
        view.addSubview(connectionView)

        let connectionConstraints = [
            connectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            connectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ETPMenuUX.UX.gutterDistance),
            connectionView.topAnchor.constraint(equalTo: horizontalLine.bottomAnchor, constant: 28),
            connectionView.heightAnchor.constraint(equalToConstant: ETPMenuUX.UX.viewHeight),

            connectionImage.leadingAnchor.constraint(equalTo: connectionView.leadingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            connectionImage.centerYAnchor.constraint(equalTo: connectionView.centerYAnchor),
            connectionImage.heightAnchor.constraint(equalToConstant: 20),
            connectionImage.widthAnchor.constraint(equalToConstant: 20),

            connectionLabel.leadingAnchor.constraint(equalTo: connectionImage.trailingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            connectionLabel.centerYAnchor.constraint(equalTo: connectionView.centerYAnchor),
            connectionLabel.trailingAnchor.constraint(equalTo: connectionDetailArrow.leadingAnchor, constant: -10),

            connectionDetailArrow.trailingAnchor.constraint(equalTo: connectionView.trailingAnchor, constant: -ETPMenuUX.UX.gutterDistance),
            connectionDetailArrow.centerYAnchor.constraint(equalTo: connectionView.centerYAnchor),
            connectionDetailArrow.heightAnchor.constraint(equalToConstant: 12),
            connectionDetailArrow.widthAnchor.constraint(equalToConstant: 7),

            connectionButton.leadingAnchor.constraint(equalTo: connectionView.leadingAnchor),
            connectionButton.topAnchor.constraint(equalTo: connectionView.topAnchor),
            connectionButton.trailingAnchor.constraint(equalTo: connectionView.trailingAnchor),
            connectionButton.bottomAnchor.constraint(equalTo: connectionView.bottomAnchor)
        ]

        constraints.append(contentsOf: connectionConstraints)
    }

    private func setupToggleView() {
        toggleView.addSubview(toggleLabel)
        toggleView.addSubview(toggleSwitch)
        toggleContainer.addSubview(toggleView)
        toggleContainer.addSubview(toggleStatusLabel)
        view.addSubview(toggleContainer)

        var toggleConstraints = [
            toggleContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toggleContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toggleContainer.topAnchor.constraint(equalTo: connectionView.bottomAnchor, constant: 32),
            toggleContainer.heightAnchor.constraint(equalToConstant: 92),

            toggleView.leadingAnchor.constraint(equalTo: toggleContainer.leadingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            toggleView.trailingAnchor.constraint(equalTo: toggleContainer.trailingAnchor, constant: -ETPMenuUX.UX.gutterDistance),
            toggleView.topAnchor.constraint(equalTo: toggleContainer.topAnchor),
            toggleView.heightAnchor.constraint(equalToConstant: ETPMenuUX.UX.viewHeight),

            toggleLabel.leadingAnchor.constraint(equalTo: toggleView.leadingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            toggleLabel.centerYAnchor.constraint(equalTo: toggleView.centerYAnchor),

            toggleSwitch.centerYAnchor.constraint(equalTo: toggleView.centerYAnchor),
            toggleSwitch.trailingAnchor.constraint(equalTo: toggleView.trailingAnchor, constant: -ETPMenuUX.UX.gutterDistance),

            toggleStatusLabel.leadingAnchor.constraint(equalTo: toggleLabel.leadingAnchor),
            toggleStatusLabel.topAnchor.constraint(equalTo: toggleView.bottomAnchor, constant: 6)
        ]

        if toggleContainerShouldBeHidden {
            toggleConstraints.append(protectionView.topAnchor.constraint(equalTo: connectionView.bottomAnchor, constant: 32))
            toggleContainer.isHidden = true
        } else {
            toggleConstraints.append(protectionView.topAnchor.constraint(equalTo: toggleContainer.bottomAnchor))
            toggleContainer.isHidden = false
        }

        constraints.append(contentsOf: toggleConstraints)
    }

    private func setupProtectionSettingsView() {
        protectionView.addSubview(protectionButton)
        view.addSubview(protectionView)

        let protectionConstraints = [
            protectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            protectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ETPMenuUX.UX.gutterDistance),
            protectionView.heightAnchor.constraint(equalToConstant: ETPMenuUX.UX.viewHeight),
            protectionView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),

            protectionButton.leadingAnchor.constraint(equalTo: protectionView.leadingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            protectionButton.trailingAnchor.constraint(equalTo: protectionView.trailingAnchor, constant: -ETPMenuUX.UX.gutterDistance),
            protectionButton.topAnchor.constraint(equalTo: protectionView.topAnchor),
            protectionButton.bottomAnchor.constraint(equalTo: protectionView.bottomAnchor)

        ]

        constraints.append(contentsOf: protectionConstraints)
    }

    private func updateViewDetails() {
        if let favIconURL = viewModel.favIcon {
            heroImage.sd_setImage(with: favIconURL, placeholderImage: UIImage(named: "defaultFavicon"), options: [], completed: nil)
        } else {
            heroImage.image = UIImage(named: "defaultFavicon")!
            heroImage.tintColor = UIColor.theme.etpMenu.defaultImageTints
        }

        siteDomainLabel.text = viewModel.websiteTitle

        connectionLabel.text = viewModel.connectionStatusString
        connectionImage.image = viewModel.connectionStatusImage

        toggleSwitch.isOn = viewModel.isSiteETPEnabled
        toggleLabel.text = Strings.TrackingProtectionEnableTitle
        toggleStatusLabel.text = toggleSwitch.isOn ? Strings.ETPOn : Strings.ETPOff
    }

    private func setupViewActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        connectionButton.addTarget(self, action: #selector(connectionDetailsTapped), for: .touchUpInside)
        toggleSwitch.addTarget(self, action: #selector(trackingProtectionToggleTapped), for: .valueChanged)
        protectionButton.addTarget(self, action: #selector(protectionSettingsTapped), for: .touchUpInside)
    }

    // MARK: - Button actions

    @objc func closeButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func connectionDetailsTapped() {
        let detailsVC = EnhancedTrackingProtectionDetailsVC(viewModel: viewModel.getDetailsViewModel(withCachedImage: heroImage.image))
        detailsVC.modalPresentationStyle = .pageSheet
        self.present(detailsVC, animated: true)
    }

    @objc func trackingProtectionToggleTapped() {
        // site is safelisted if site ETP is disabled
        viewModel.toggleSiteSafelistStatus()
        switch viewModel.isSiteETPEnabled {
        case true: toggleStatusLabel.text = Strings.ETPOn
        case false: toggleStatusLabel.text = Strings.ETPOff
        }
    }

    @objc func protectionSettingsTapped() {
        self.dismiss(animated: true) {
            self.viewModel.onClose?()
        }
}

// MARK: - Gesture Recognizer

    private func addGestureRecognizer() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction))
        view.addGestureRecognizer(panGesture)
    }

    @objc func panGestureRecognizerAction(sender: UIPanGestureRecognizer) {
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
                self.dismiss(animated: true, completion: nil)
            } else {
                // Set back to original position of the view controller
                UIView.animate(withDuration: 0.3) {
                    self.view.frame.origin = self.pointOrigin ?? CGPoint(x: originalXPosition, y: originalYPosition)
                }
            }
        }
    }
}

extension EnhancedTrackingProtectionMenuVC: PresentingModalViewControllerDelegate {
    func dismissPresentedModalViewController(_ modalViewController: UIViewController, animated: Bool) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension EnhancedTrackingProtectionMenuVC: Themeable {
    @objc func applyTheme() {
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle =  ThemeManager.instance.userInterfaceStyle
        }
        view.backgroundColor = UIColor.theme.etpMenu.background
        connectionView.backgroundColor = UIColor.theme.etpMenu.sectionColor
        connectionImage.image = viewModel.connectionStatusImage
        connectionDetailArrow.tintColor = UIColor.theme.etpMenu.defaultImageTints
        if viewModel.connectionSecure {
            connectionImage.tintColor = UIColor.theme.etpMenu.defaultImageTints
        }
        toggleView.backgroundColor = UIColor.theme.etpMenu.sectionColor
        toggleStatusLabel.textColor = UIColor.theme.etpMenu.subtextColor
        protectionView.backgroundColor = UIColor.theme.etpMenu.sectionColor
        setNeedsStatusBarAppearanceUpdate()
     }
 }
