// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

final class PopupViewController: UIViewController {
    private let contentView: UIView

    private let backgroundView: UIView = .build {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }

    init(contentView: UIView) {
        self.contentView = contentView
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        setupConstraints()
        setupGestures()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }

    // MARK: - Setup
    private func setupSubviews() {
        view.addSubview(backgroundView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        contentView.alpha = 0
        contentView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        view.addSubview(contentView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16.0),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16.0),
            contentView.topAnchor.constraint(equalTo: view.topAnchor, constant: 200),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -200)
        ])
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        backgroundView.addGestureRecognizer(tap)
    }

    // MARK: - Animations
    private func animateIn() {
        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.6,
                       options: [.curveEaseOut]) {
            self.contentView.alpha = 1
            self.contentView.transform = .identity
        }
    }

    private func animateOut(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.18,
                       animations: {
            self.contentView.alpha = 0
            self.contentView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.backgroundView.alpha = 0
        }) { _ in
            completion?()
        }
    }

    // MARK: - Actions
    @objc
    private func handleBackgroundTap() {
        animateOut { [weak self] in
            self?.dismiss(animated: false)
        }
    }
}
