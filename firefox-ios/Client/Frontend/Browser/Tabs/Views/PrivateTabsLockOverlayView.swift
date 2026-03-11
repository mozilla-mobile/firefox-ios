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

    var onRetryTapped: (() -> Void)?

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(access: BrowserViewControllerState.PrivateAccessState, auth: BrowserViewControllerState.PrivateAuthState) {
        switch access {
        case .unlocked:
            isHidden = true
            apply(mode: .prompt)

        case .locked:
            isHidden = false
            switch auth {
            case .idle:
                apply(mode: .prompt)
            case .authenticating:
                apply(mode: .authenticating)
            case .failed:
                apply(mode: .failed)
            }
        }
    }

    func renderHidden() {
        isHidden = true
        apply(mode: .prompt)
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false

        let background = FirefoxGradientBackgroundView()

        addSubview(background)
        background.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: topAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor),
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor)
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

        retryButton.setTitle("Try Again", for: .normal)
        retryButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        stack.axis = .vertical
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subtitleLabel)
        stack.addArrangedSubview(spinner)
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

    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false

        var config = UIButton.Configuration.filled()
        config.title = "Try Again"
        config.baseBackgroundColor = UIColor.systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 28, bottom: 14, trailing: 28)

        button.configuration = config
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.18
        button.layer.shadowRadius = 10
        button.layer.shadowOffset = CGSize(width: 0, height: 4)

        return button
    }()

    func apply(mode: Mode) {
        switch mode {
        case .prompt:
            spinner.stopAnimating()
            retryButton.isHidden = true
            subtitleLabel.text = "Unlock with Face ID to view private tabs"

        case .authenticating:
            spinner.startAnimating()
            retryButton.isHidden = true
            subtitleLabel.text = "Authenticating…"

        case .failed:
            spinner.stopAnimating()
            retryButton.isHidden = false
            subtitleLabel.text = "Face ID failed. Try again."
        }
    }

    @objc private func retryTapped() { onRetryTapped?() }
}
