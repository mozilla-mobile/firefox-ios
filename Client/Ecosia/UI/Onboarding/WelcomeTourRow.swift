// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class WelcomeTourRow: UIView, Themeable {
    let image: String
    let title: String
    let text: String

    weak var titleLabel: UILabel!
    weak var textLabel: UILabel!

    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init

    init(image: String, title: String, text: String) {
        self.image = image
        self.title = title
        self.text = text

        super.init(frame: .zero)
        setup()
        applyTheme()
    }

    required init?(coder: NSCoder) {  nil }

    func setup() {
        layer.cornerRadius = 10

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        addSubview(stack)

        stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        stack.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true

        let imageView = UIImageView(image: .init(named: image))
        imageView.heightAnchor.constraint(equalToConstant: 33).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 33).isActive = true
        stack.addArrangedSubview(imageView)
        
        let trailingStack = UIStackView()
        trailingStack.spacing = 5
        trailingStack.axis = .vertical
        trailingStack.alignment = .leading

        stack.addArrangedSubview(trailingStack)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .body).bold()
        titleLabel.adjustsFontForContentSizeCategory = true
        trailingStack.addArrangedSubview(titleLabel)
        self.titleLabel = titleLabel

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .preferredFont(forTextStyle: .footnote)
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        trailingStack.addArrangedSubview(textLabel)
        self.textLabel = textLabel
    }

    func applyTheme() {
        backgroundColor = .legacyTheme.ecosia.welcomeElementBackground
        titleLabel.textColor = .legacyTheme.ecosia.primaryText
        textLabel.textColor = .legacyTheme.ecosia.secondaryText
    }
}
