// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

final class PrivateTabsLockOverlayView: UIView {

    enum Mode: Equatable {
        case prompt
        case authenticating
        case failed
    }

    var onUnlockTapped: (() -> Void)?
    var onRetryTapped: (() -> Void)?

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let unlockButton = UIButton(type: .system)
    private let retryButton = UIButton(type: .system)
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false

        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .white
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.text = "Private Tabs Locked"

        subtitleLabel.font = .preferredFont(forTextStyle: .body)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textColor = .white.withAlphaComponent(0.85)
        subtitleLabel.text = "Unlock with Face ID to view private tabs."

        spinner.hidesWhenStopped = true

        unlockButton.setTitle("Unlock", for: .normal)
        unlockButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        unlockButton.addTarget(self, action: #selector(unlockTapped), for: .touchUpInside)

        retryButton.setTitle("Try Again", for: .normal)
        retryButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subtitleLabel)
        stack.addArrangedSubview(spinner)
        stack.addArrangedSubview(unlockButton)
        stack.addArrangedSubview(retryButton)

        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        apply(mode: .prompt)
    }

    func apply(mode: Mode) {
        switch mode {
        case .prompt:
            spinner.stopAnimating()
            unlockButton.isHidden = false
            retryButton.isHidden = true
            subtitleLabel.text = "Unlock with Face ID to view private tabs"

        case .authenticating:
            spinner.startAnimating()
            unlockButton.isHidden = true
            retryButton.isHidden = true
            subtitleLabel.text = "Authenticating…"

        case .failed:
            spinner.stopAnimating()
            unlockButton.isHidden = true
            retryButton.isHidden = false
            subtitleLabel.text = "Face ID failed. Try again."
        }
    }

    @objc private func unlockTapped() { onUnlockTapped?() }
    @objc private func retryTapped() { onRetryTapped?() }
}
