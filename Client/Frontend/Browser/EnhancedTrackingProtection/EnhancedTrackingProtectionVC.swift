// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

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
            static let distanceFromHeroImage: CGFloat = 17
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
    private let headerContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private var heroImage: UIImageView = .build { heroImage in
        heroImage.contentMode = .scaleAspectFit
        heroImage.clipsToBounds = true
        heroImage.layer.masksToBounds = true
        heroImage.layer.cornerRadius = 5
    }

    private let siteDomainLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.websiteTitle
        label.numberOfLines = 0
    }

    private var closeButton: UIButton = .build { button in
        button.backgroundColor = .Photon.LightGrey50
        button.layer.cornerRadius = 0.5 * ETPMenuUX.UX.closeButtonSize
        button.clipsToBounds = true
        button.setImage(UIImage(named: "close-medium"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
    }

    private let horizontalLine: UIView = .build { line in
        line.backgroundColor = UIColor.theme.etpMenu.horizontalLine
    }

    // Connection Info view
    private let connectionView = ETPSectionView(frame: .zero)

    private let connectionImage: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
        image.layer.cornerRadius = 5
    }

    private let connectionLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.viewTitleLabels
        label.numberOfLines = 0
    }

    private let connectionDetailArrow: UIImageView = .build { image in
        image.image = UIImage(imageLiteralResourceName: "goBack").withRenderingMode(.alwaysTemplate).imageFlippedForRightToLeftLayoutDirection()
        image.transform = CGAffineTransform(rotationAngle: .pi)
    }

    private let connectionButton: UIButton = .build { button in }

    // TrackingProtection toggle View
    private let toggleContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private let toggleView: UIView = ETPSectionView(frame: .zero)

    private let toggleLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.viewTitleLabels
        label.numberOfLines = 0
    }

    private let toggleSwitch: UISwitch = .build { toggleSwitch in
        toggleSwitch.isEnabled = true
        toggleSwitch.onTintColor = .systemBlue
    }

    private let toggleStatusLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.detailsLabel
        label.numberOfLines = 0
    }

    // Protection setting view
    private let protectionView: UIView = ETPSectionView(frame: .zero)

    private var protectionButton: UIButton = .build { button in
        button.setTitle(.TPProtectionSettings, for: .normal)
        button.titleLabel?.font = ETPMenuUX.Fonts.viewTitleLabels
        button.setTitleColor(.systemBlue, for: .normal)
        button.contentHorizontalAlignment = .left
    }

    private var constraints = [NSLayoutConstraint]()

    // MARK: - Variables

    private var viewModel: EnhancedTrackingProtectionMenuVM
    private var hasSetPointOrigin = false
    private var pointOrigin: CGPoint?
    var asPopover: Bool = false

    private var toggleContainerShouldBeHidden: Bool {
        return !viewModel.globalETPIsEnabled
    }

    private var protectionViewTopConstraint: NSLayoutConstraint?

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
        if asPopover {
            var height: CGFloat = 385
            if toggleContainerShouldBeHidden {
                height = 285
            }
            self.preferredContentSize = CGSize(width: 400, height: height)
        } else {
            addGestureRecognizer()
        }
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
        headerContainer.addSubviews(heroImage, siteDomainLabel, closeButton, horizontalLine)
        view.addSubview(headerContainer)

        var headerConstraints = [
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            heroImage.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            heroImage.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: ETPMenuUX.UX.gutterDistance),
            heroImage.widthAnchor.constraint(equalToConstant: ETPMenuUX.UX.heroImageSize),
            heroImage.heightAnchor.constraint(equalToConstant: ETPMenuUX.UX.heroImageSize),

            siteDomainLabel.centerYAnchor.constraint(equalTo: heroImage.centerYAnchor),
            siteDomainLabel.leadingAnchor.constraint(equalTo: heroImage.trailingAnchor, constant: 8),
            siteDomainLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -15),

            closeButton.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -ETPMenuUX.UX.gutterDistance),
            closeButton.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: ETPMenuUX.UX.gutterDistance),
            closeButton.heightAnchor.constraint(equalToConstant: ETPMenuUX.UX.closeButtonSize),
            closeButton.widthAnchor.constraint(equalToConstant: ETPMenuUX.UX.closeButtonSize),

            horizontalLine.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            horizontalLine.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            horizontalLine.topAnchor.constraint(equalTo: heroImage.bottomAnchor, constant: ETPMenuUX.UX.Line.distanceFromHeroImage),
            horizontalLine.heightAnchor.constraint(equalToConstant: ETPMenuUX.UX.Line.height),
            headerContainer.bottomAnchor.constraint(equalTo: horizontalLine.bottomAnchor)
        ]

        if asPopover {
            headerConstraints.append(headerContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 20))
        } else {
            headerConstraints.append(headerContainer.topAnchor.constraint(equalTo: view.topAnchor))
        }

        constraints.append(contentsOf: headerConstraints)
    }

    private func setupConnectionStatusView() {
        connectionView.addSubviews(connectionImage, connectionLabel, connectionDetailArrow, connectionButton)
        view.addSubview(connectionView)

        let connectionConstraints = [
            connectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            connectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ETPMenuUX.UX.gutterDistance),
            connectionView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 28),
            connectionView.heightAnchor.constraint(greaterThanOrEqualToConstant: ETPMenuUX.UX.viewHeight),

            connectionImage.leadingAnchor.constraint(equalTo: connectionView.leadingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            connectionImage.centerYAnchor.constraint(equalTo: connectionView.centerYAnchor),
            connectionImage.heightAnchor.constraint(equalToConstant: 20),
            connectionImage.widthAnchor.constraint(equalToConstant: 20),

            connectionLabel.leadingAnchor.constraint(equalTo: connectionImage.trailingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            connectionLabel.centerYAnchor.constraint(equalTo: connectionView.centerYAnchor),
            connectionLabel.topAnchor.constraint(equalTo: connectionView.topAnchor, constant: 11),
            connectionLabel.bottomAnchor.constraint(equalTo: connectionView.bottomAnchor, constant: -11),
            connectionLabel.trailingAnchor.constraint(equalTo: connectionDetailArrow.leadingAnchor, constant: ETPMenuUX.UX.gutterDistance),

            connectionDetailArrow.trailingAnchor.constraint(equalTo: connectionView.trailingAnchor, constant: -ETPMenuUX.UX.gutterDistance),
            connectionDetailArrow.centerYAnchor.constraint(equalTo: connectionView.centerYAnchor),
            connectionDetailArrow.heightAnchor.constraint(equalToConstant: 20),
            connectionDetailArrow.widthAnchor.constraint(equalToConstant: 20),

            connectionButton.leadingAnchor.constraint(equalTo: connectionView.leadingAnchor),
            connectionButton.topAnchor.constraint(equalTo: connectionView.topAnchor),
            connectionButton.trailingAnchor.constraint(equalTo: connectionView.trailingAnchor),
            connectionButton.bottomAnchor.constraint(equalTo: connectionView.bottomAnchor)
        ]

        constraints.append(contentsOf: connectionConstraints)
    }

    private func setupToggleView() {
        toggleView.addSubviews(toggleLabel, toggleSwitch)
        toggleContainer.addSubviews(toggleView, toggleStatusLabel)
        view.addSubview(toggleContainer)

        var toggleConstraints = [
            toggleContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toggleContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toggleContainer.topAnchor.constraint(equalTo: connectionView.bottomAnchor, constant: 32),
            toggleContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 92),
            toggleContainer.heightAnchor.constraint(lessThanOrEqualToConstant: 106),

            toggleView.leadingAnchor.constraint(equalTo: toggleContainer.leadingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            toggleView.trailingAnchor.constraint(equalTo: toggleContainer.trailingAnchor, constant: -ETPMenuUX.UX.gutterDistance),
            toggleView.topAnchor.constraint(equalTo: toggleContainer.topAnchor),
            toggleView.heightAnchor.constraint(greaterThanOrEqualToConstant: ETPMenuUX.UX.viewHeight),

            toggleLabel.leadingAnchor.constraint(equalTo: toggleView.leadingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            toggleLabel.trailingAnchor.constraint(equalTo: toggleSwitch.leadingAnchor, constant: -ETPMenuUX.UX.gutterDistance),
            toggleLabel.topAnchor.constraint(equalTo: toggleView.topAnchor, constant: 11),
            toggleLabel.bottomAnchor.constraint(equalTo: toggleView.bottomAnchor, constant: -11),

            toggleSwitch.centerYAnchor.constraint(equalTo: toggleView.centerYAnchor),
            toggleSwitch.widthAnchor.constraint(equalToConstant: 51),
            toggleSwitch.heightAnchor.constraint(equalToConstant: 31),
            toggleSwitch.trailingAnchor.constraint(equalTo: toggleView.trailingAnchor, constant: -ETPMenuUX.UX.gutterDistance),

            toggleStatusLabel.leadingAnchor.constraint(equalTo: toggleLabel.leadingAnchor),
            toggleStatusLabel.trailingAnchor.constraint(equalTo: toggleSwitch.trailingAnchor),
            toggleStatusLabel.topAnchor.constraint(equalTo: toggleView.bottomAnchor, constant: 6),
            toggleStatusLabel.bottomAnchor.constraint(lessThanOrEqualTo: toggleContainer.bottomAnchor, constant: -6)
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
            protectionView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: 15),

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
        toggleLabel.text = .TrackingProtectionEnableTitle
        toggleStatusLabel.text = toggleSwitch.isOn ? .ETPOn : .ETPOff
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
        let detailsVC = EnhancedTrackingProtectionDetailsVC(with: viewModel.getDetailsViewModel(withCachedImage: heroImage.image))
        detailsVC.modalPresentationStyle = .pageSheet
        self.present(detailsVC, animated: true)
    }

    @objc func trackingProtectionToggleTapped() {
        // site is safelisted if site ETP is disabled
        viewModel.toggleSiteSafelistStatus()
        switch viewModel.isSiteETPEnabled {
        case true: toggleStatusLabel.text = .ETPOn
        case false: toggleStatusLabel.text = .ETPOff
        }
    }

    @objc func protectionSettingsTapped() {
        self.dismiss(animated: true) {
            self.viewModel.onOpenSettingsTapped?()
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

extension EnhancedTrackingProtectionMenuVC: NotificationThemeable {
    @objc func applyTheme() {
        overrideUserInterfaceStyle =  LegacyThemeManager.instance.userInterfaceStyle
        view.backgroundColor = UIColor.theme.etpMenu.background
        connectionView.backgroundColor = UIColor.theme.etpMenu.sectionColor
        connectionImage.image = viewModel.connectionStatusImage
        connectionDetailArrow.tintColor = UIColor.theme.etpMenu.defaultImageTints
        if viewModel.connectionSecure {
            connectionImage.tintColor = UIColor.theme.etpMenu.defaultImageTints
        }
        toggleView.backgroundColor = UIColor.theme.etpMenu.sectionColor
        toggleSwitch.tintColor = UIColor.theme.etpMenu.switchAndButtonTint
        toggleSwitch.onTintColor = UIColor.theme.etpMenu.switchAndButtonTint
        toggleStatusLabel.textColor = UIColor.theme.etpMenu.subtextColor
        protectionView.backgroundColor = UIColor.theme.etpMenu.sectionColor
        protectionButton.setTitleColor(UIColor.theme.etpMenu.switchAndButtonTint, for: .normal)
        setNeedsStatusBarAppearanceUpdate()
     }
 }
