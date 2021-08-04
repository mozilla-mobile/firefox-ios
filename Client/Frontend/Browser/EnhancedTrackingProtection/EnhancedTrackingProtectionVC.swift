/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct ETPMenuUX {
    struct Fonts {
        static let websiteTitle: UIFont = .systemFont(ofSize: 16, weight: .bold)
        static let viewTitleLabels: UIFont = .systemFont(ofSize: 17, weight: .regular)
        static let detailsLabel: UIFont = .systemFont(ofSize: 12, weight: .regular)
    }

    struct UX {
        static let gutterDistance: CGFloat = 16
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
    let connectionView: UIView = .build { line in
        line.backgroundColor = .green
    }
    let connectionImage: UIImageView = .build { image in
        image.backgroundColor = .green
    }

    let connectionLabel: UILabel = .build { label in
        label.backgroundColor = .green
    }

    let connectionDetailArrow: UIImageView = .build { image in
        image.backgroundColor = .green
    }

    let connectionButton: UIButton = .build { button in
        button.backgroundColor = .green
    }

    // TrackingProtection toggle View
    let toggleView: UIView = .build { line in
        line.backgroundColor = .green
    }

    let toggleLabel: UIView = .build { line in
        line.backgroundColor = .green
    }

    let toggleSwitch: UIView = .build { line in
        line.backgroundColor = .green
    }

    let toggleStatusLabel: UIView = .build { line in
        line.backgroundColor = .green
    }

    // Protection setting view
    let protectionView: UIView = .build { line in
        line.backgroundColor = .green
    }

    let protectionButton: UIView = .build { line in
        line.backgroundColor = .green
    }

    // MARK: - Variables

    var viewModel: EnhancedTrackingProtectionMenuVM?
    var hasSetPointOrigin = false
    var pointOrigin: CGPoint?

    override func viewDidLoad() {
        super.viewDidLoad()
        addGestureRecognizer()
        setupView()
        applyTheme()
        updateViewDetails()
    }

    override func viewDidLayoutSubviews() {
        if !hasSetPointOrigin {
            hasSetPointOrigin = true
            pointOrigin = self.view.frame.origin
        }
    }

    private func setupView() {
        view.addSubview(heroImage)
        view.addSubview(siteDomainLabel)
        view.addSubview(closeButton)
        view.addSubview(horizontalLine)

        setupConstranints()
    }

    private func setupConstranints() {
        NSLayoutConstraint.activate([
            heroImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            heroImage.topAnchor.constraint(equalTo: view.topAnchor, constant: ETPMenuUX.UX.gutterDistance),
            heroImage.widthAnchor.constraint(equalToConstant: ETPMenuUX.UX.heroImageSize),
            heroImage.heightAnchor.constraint(equalToConstant: ETPMenuUX.UX.heroImageSize),

            siteDomainLabel.centerYAnchor.constraint(equalTo: heroImage.centerYAnchor),
            siteDomainLabel.leadingAnchor.constraint(equalTo: heroImage.trailingAnchor, constant: 8),

            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: ETPMenuUX.UX.gutterDistance),
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: ETPMenuUX.UX.gutterDistance),
            closeButton.heightAnchor.constraint(equalToConstant: ETPMenuUX.UX.closeButtonSize),
            closeButton.widthAnchor.constraint(equalToConstant: ETPMenuUX.UX.closeButtonSize),

            horizontalLine.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            horizontalLine.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            horizontalLine.topAnchor.constraint(equalTo: view.topAnchor, constant: ETPMenuUX.UX.Line.distanceFromTopAnchor),
            horizontalLine.heightAnchor.constraint(equalToConstant: ETPMenuUX.UX.Line.height)
        ])
    }

    private func updateViewDetails() {
        siteDomainLabel.text = viewModel?.websiteTitle
    }

    // MARK: - Button actions

    @objc func closeButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func connectionDetailsTapped() {

    }

    @objc func trackingProtectionToggleTapped() {

    }

    @objc func protectionSettingsTapped() {

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

        // Setting x as 0 because we don't want users to move the frame side ways,
        // only straight up or down
        view.frame.origin = CGPoint(x: 0, y: self.pointOrigin!.y + translation.y)

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
