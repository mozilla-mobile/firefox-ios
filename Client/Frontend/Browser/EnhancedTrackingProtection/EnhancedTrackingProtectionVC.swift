/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit

struct ETPMenuUX {
    struct Fonts {
        static let websiteTitle: UIFont = .systemFont(ofSize: 16, weight: .bold)
        static let viewTitleLabels: UIFont = .systemFont(ofSize: 17, weight: .regular)
        static let detailsLabel: UIFont = .systemFont(ofSize: 12, weight: .regular)
    }

    struct UX {
        static let gutterDistance: CGFloat = 16
        static let viewCornerRadius: CGFloat = 8
        static let viewHeight: CGFloat = 44
        static let websiteLabelToHeroImageSpacing: CGFloat = 8
        static let heroImageSize: CGFloat = 40
        static let closeButtonSize: CGFloat = 30

        struct Line {
            static let distanceFromTopAnchor: CGFloat = 75
            static let height: CGFloat = 1
        }
    }
}

class EnhancedTrackingProtectionMenuVC: UIViewController {

    // MARK: UI components

    // Header View
    let heroImage: UIImageView = .build { heroImage in
        heroImage.contentMode = .scaleAspectFit
        heroImage.clipsToBounds = true
        heroImage.layer.masksToBounds = true
        heroImage.layer.cornerRadius = 5
        heroImage.image = UIImage(named: "defaultFavicon")
        heroImage.tintColor = UIColor.Photon.Grey50
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
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }

    let horizontalLine: UIView = .build { line in
        line.backgroundColor = UIColor.theme.etpMenu.horizontalLine
    }

    // Connection Info view
    let connectionView: UIView = .build { view in
        view.backgroundColor = .white
        view.layer.cornerRadius = ETPMenuUX.UX.viewCornerRadius
    }

    let connectionImage: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
        image.layer.cornerRadius = 5
        image.image = UIImage(named: "lock_verified")
        image.tintColor = UIColor.Photon.Grey50
    }

    let connectionLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.viewTitleLabels
    }

    let connectionDetailArrow: UIImageView = .build { image in
        image.backgroundColor = .green
    }

    let connectionButton: UIButton = .build { button in
        button.addTarget(self, action: #selector(connectionDetailsTapped), for: .touchUpInside)
    }

    // TrackingProtection toggle View
    let toggleContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    let toggleView: UIView = .build { view in
        view.backgroundColor = .white
        view.layer.cornerRadius = ETPMenuUX.UX.viewCornerRadius
    }

    let toggleLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.viewTitleLabels
    }

    let toggleSwitch: UIView = .build { toggleSwitch in
    }

    let toggleStatusLabel: UILabel = .build { label in
        label.backgroundColor = .green
        label.font = ETPMenuUX.Fonts.detailsLabel
    }

    // Protection setting view
    let protectionView: UIView = .build { view in
        view.backgroundColor = .white
        view.layer.cornerRadius = ETPMenuUX.UX.viewCornerRadius
    }

    let protectionButton: UIButton = .build { button in
        button.setTitle("Test button title", for: .normal)
        button.titleLabel?.font = ETPMenuUX.Fonts.viewTitleLabels
        button.setTitleColor(.systemBlue, for: .normal)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(protectionSettingsTapped), for: .touchUpInside)
    }

    var constraints = [NSLayoutConstraint]()

    // MARK: - Variables

    var viewModel: EnhancedTrackingProtectionMenuVM?
    var hasSetPointOrigin = false
    var pointOrigin: CGPoint?

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        addGestureRecognizer()
        setupView()
        applyTheme()
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
    }

    private func setupView() {
        constraints.removeAll()

        setupHeaderView()
        setupConnectionStatusView()
        setupToggleView()
        setupProtectionSettingsView()

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

            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ETPMenuUX.UX.gutterDistance),
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: ETPMenuUX.UX.gutterDistance),
            closeButton.heightAnchor.constraint(equalToConstant: ETPMenuUX.UX.closeButtonSize),
            closeButton.widthAnchor.constraint(equalToConstant: ETPMenuUX.UX.closeButtonSize),

            horizontalLine.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            horizontalLine.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            horizontalLine.topAnchor.constraint(equalTo: view.topAnchor, constant: ETPMenuUX.UX.Line.distanceFromTopAnchor),
            horizontalLine.heightAnchor.constraint(equalToConstant: ETPMenuUX.UX.Line.height)
        ]

        constraints.append(contentsOf: headerConstraints)
    }

    private func setupConnectionStatusView() {
        // Connection View
        connectionView.addSubview(connectionImage)
        connectionView.addSubview(connectionLabel)
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

            connectionButton.leadingAnchor.constraint(equalTo: connectionView.leadingAnchor),
            connectionButton.topAnchor.constraint(equalTo: connectionView.topAnchor),
            connectionButton.trailingAnchor.constraint(equalTo: connectionView.trailingAnchor),
            connectionButton.bottomAnchor.constraint(equalTo: connectionView.bottomAnchor)
        ]

        constraints.append(contentsOf: connectionConstraints)
    }

    private func setupToggleView() {
        toggleView.addSubview(toggleLabel)
        toggleContainer.addSubview(toggleView)
        toggleContainer.addSubview(toggleStatusLabel)
        view.addSubview(toggleContainer)

        let toggleConstraints = [
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

            toggleStatusLabel.leadingAnchor.constraint(equalTo: toggleLabel.leadingAnchor),
            toggleStatusLabel.topAnchor.constraint(equalTo: toggleView.bottomAnchor, constant: 6)
        ]

        constraints.append(contentsOf: toggleConstraints)
    }

    private func setupProtectionSettingsView() {
        protectionView.addSubview(protectionButton)
        view.addSubview(protectionView)

        let protectionConstraints = [
            protectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            protectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ETPMenuUX.UX.gutterDistance),
            protectionView.topAnchor.constraint(equalTo: toggleContainer.bottomAnchor),
            protectionView.heightAnchor.constraint(equalToConstant: ETPMenuUX.UX.viewHeight),

            protectionButton.leadingAnchor.constraint(equalTo: protectionView.leadingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            protectionButton.trailingAnchor.constraint(equalTo: protectionView.trailingAnchor, constant: -ETPMenuUX.UX.gutterDistance),
            protectionButton.topAnchor.constraint(equalTo: protectionView.topAnchor),
            protectionButton.bottomAnchor.constraint(equalTo: protectionView.bottomAnchor)
        ]

        constraints.append(contentsOf: protectionConstraints)
    }

    private func updateViewDetails() {
        heroImage.image = viewModel?.favIcon
        siteDomainLabel.text = viewModel?.websiteTitle
        let statusString: String = (1 == 1) ? .ProtectionStatusSheetConnectionSecure : .ProtectionStatusSheetConnectionInsecure
        connectionLabel.text = statusString
        toggleLabel.text = Strings.TrackingProtectionEnableTitle
        toggleStatusLabel.text = "another soooooo"
    }

    // MARK: - Button actions

    @objc func closeButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func connectionDetailsTapped() {
        let detailsVC = EnhancedTrackingProtectionDetailsVC()
        detailsVC.modalPresentationStyle = .fullScreen
        detailsVC.modalTransitionStyle = .coverVertical
        self.present(detailsVC, animated: true)
    }

    @objc func trackingProtectionToggleTapped() {

    }

    @objc func protectionSettingsTapped() {
//        let settings = PhotonActionSheetItem(title: Strings.TPProtectionSettings, iconString: "settings") { _, _ in
//            let settingsTableViewController = AppSettingsTableViewController()
//            settingsTableViewController.profile = self.profile
//            settingsTableViewController.tabManager = self.tabManager
//            guard let bvc = self as? BrowserViewController else { return }
//            settingsTableViewController.settingsDelegate = bvc
//            settingsTableViewController.showContentBlockerSetting = true
//
//            let controller = ThemedNavigationController(rootViewController: settingsTableViewController)
//            controller.presentingModalViewControllerDelegate = bvc
//
//            // Wait to present VC in an async dispatch queue to prevent a case where dismissal
//            // of this popover on iPad seems to block the presentation of the modal VC.
//            DispatchQueue.main.async {
//                bvc.present(controller, animated: true, completion: nil)
//            }
//        }
    }

    // MARK: - Gesture Recognizer

    private func addGestureRecognizer() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction))
        view.addGestureRecognizer(panGesture)
    }

    @objc func panGestureRecognizerAction(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)

        // Not allowing the user to drag the view upward
        guard translation.y >= 0 else { return }

        // Setting x as 0 or based on window calculation because we don't want
        // users to move the frame side ways, only straight up or down
        var xPosition: CGFloat = 0
        var frameWidth: CGFloat = 0
        if UIApplication.shared.statusBarOrientation.isLandscape {
            frameWidth = view.frame.width
            xPosition = (view.window?.frame.size.width)!/2 - (frameWidth/2)
        }
        view.frame.origin = CGPoint(x: xPosition, y: self.pointOrigin!.y + translation.y)

        if sender.state == .ended {
            let dragVelocity = sender.velocity(in: view)
            if dragVelocity.y >= 1300 {
                self.dismiss(animated: true, completion: nil)
            } else {
                // Set back to original position of the view controller
                UIView.animate(withDuration: 0.3) {
                    self.view.frame.origin = self.pointOrigin ?? CGPoint(x: 0, y: 400)
                }
            }
        }
    }
}

extension EnhancedTrackingProtectionMenuVC: Themeable {
     @objc func applyTheme() {
         if #available(iOS 13.0, *) {
             overrideUserInterfaceStyle =  ThemeManager.instance.userInterfaceStyle
         }
         view.backgroundColor = UIColor.theme.etpMenu.background
         setNeedsStatusBarAppearanceUpdate()
     }
 }
