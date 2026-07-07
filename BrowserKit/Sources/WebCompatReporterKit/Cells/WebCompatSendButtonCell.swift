// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class WebCompatSendButtonCell: UICollectionViewListCell {
    private var tapHandler: (() -> Void)?

    private lazy var button: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = WebCompatReporterUX.SendButton.cornerRadius
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        backgroundConfiguration = UIBackgroundConfiguration.clear()
        contentView.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            button.topAnchor.constraint(equalTo: contentView.topAnchor),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: WebCompatReporterUX.SendButton.height)
        ])
    }

    func configure(title: String, isEnabled: Bool, theme: Theme, onTap: @escaping () -> Void) {
        tapHandler = onTap
        var configuration = button.configuration ?? UIButton.Configuration.filled()
        configuration.title = title
        // Re-resolves the font on every Dynamic Type change, unlike a one-time
        // attributedTitle snapshot.
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .headline)
            return outgoing
        }
        configuration.baseBackgroundColor = theme.colors.actionPrimary
        configuration.baseForegroundColor = theme.colors.textInverted
        button.configuration = configuration
        button.isEnabled = isEnabled
        backgroundConfiguration = UIBackgroundConfiguration.clear()
    }

    @objc
    private func didTap() {
        tapHandler?()
    }
}
