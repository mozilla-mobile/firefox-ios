/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class EnhancedTrackingProtectionMenuVC: UIViewController {

    // MARK: UI components
    // Hero image
    lazy var heroImage: UIImageView = {
        let heroImage = UIImageView()
        heroImage.translatesAutoresizingMaskIntoConstraints = false
        heroImage.contentMode = .scaleAspectFit
        heroImage.clipsToBounds = true
        heroImage.layer.masksToBounds = true
        heroImage.layer.cornerRadius = 5
        heroImage.image = UIImage(named: "defaultFavicon")
        heroImage.tintColor = UIColor.Photon.Grey50
        return heroImage
    }()

    lazy var siteDomainLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = viewModel?.websiteTitle
        label.textColor = .black
        return label
    }()
    // close button
    // horizontal line

    // connectionSecure view
    // image
    // string
    // detail
    // button

    // tracking protection view
    // label
    // uitoggle
    // detail label

    // protection setting view
    // button

    // MARK: - Variables

    var viewModel: EnhancedTrackingProtectionMenuVM?
    var hasSetPointOrigin = false
    var pointOrigin: CGPoint?

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

    private func setupView() {
        view.backgroundColor = .white
        view.addSubview(heroImage)
        view.addSubview(siteDomainLabel)

        setupConstranints()
    }

    private func setupConstranints() {
        NSLayoutConstraint.activate([
            heroImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            heroImage.topAnchor.constraint(equalTo: view.topAnchor, constant: 18),
            heroImage.widthAnchor.constraint(equalToConstant: 40),
            heroImage.heightAnchor.constraint(equalToConstant: 40),

            siteDomainLabel.centerYAnchor.constraint(equalTo: heroImage.centerYAnchor),
            siteDomainLabel.leadingAnchor.constraint(equalTo: heroImage.trailingAnchor, constant: 8)
        ])
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
