/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Common

final class WelcomeTourProfit: UIView, Themeable {
    weak var beforeContainer: UIView!
    weak var beforeLabel: UILabel!
    weak var afterContainer: UIView!
    weak var afterLabel: UILabel!
    weak var treeImage: UIImageView!

    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init
    
    init() {
        super.init(frame: .zero)
        setup()
        updateAccessibilitySettings()
        applyTheme()
    }

    required init?(coder: NSCoder) {  nil }

    func setup() {
        let beforeContainer = UIView()
        beforeContainer.translatesAutoresizingMaskIntoConstraints = false
        beforeContainer.layer.cornerRadius = 10
        addSubview(beforeContainer)
        self.beforeContainer = beforeContainer
        beforeContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
        beforeContainer.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -50).isActive = true

        let beforeLabel = UILabel()
        beforeLabel.translatesAutoresizingMaskIntoConstraints = false
        beforeLabel.text = .localized(.before)
        beforeLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        beforeLabel.adjustsFontForContentSizeCategory = true
        beforeContainer.addSubview(beforeLabel)
        self.beforeLabel = beforeLabel

        beforeLabel.leadingAnchor.constraint(equalTo: beforeContainer.leadingAnchor, constant: 12).isActive = true
        beforeLabel.trailingAnchor.constraint(equalTo: beforeContainer.trailingAnchor, constant: -12).isActive = true
        beforeLabel.topAnchor.constraint(equalTo: beforeContainer.topAnchor, constant: 10).isActive = true
        beforeLabel.bottomAnchor.constraint(equalTo: beforeContainer.bottomAnchor, constant: -10).isActive = true

        let beforeEllipse = UIImageView(image: .init(named: "tourEllipseBefore"))
        beforeEllipse.translatesAutoresizingMaskIntoConstraints = false
        addSubview(beforeEllipse)
        beforeEllipse.leadingAnchor.constraint(equalTo: beforeContainer.trailingAnchor).isActive = true
        beforeEllipse.topAnchor.constraint(equalTo: beforeContainer.centerYAnchor).isActive = true

        let beforeDot = Dot(effect: UIBlurEffect(style: .light))
        addSubview(beforeDot)
        beforeDot.heightAnchor.constraint(equalToConstant: 20).isActive = true
        beforeDot.widthAnchor.constraint(equalToConstant: 20).isActive = true
        beforeDot.topAnchor.constraint(equalTo: beforeEllipse.bottomAnchor).isActive = true
        beforeDot.centerXAnchor.constraint(equalTo: beforeEllipse.trailingAnchor).isActive = true

        let afterContainer = UIView()
        afterContainer.translatesAutoresizingMaskIntoConstraints = false
        afterContainer.layer.cornerRadius = 10
        addSubview(afterContainer)
        self.afterContainer = afterContainer
        afterContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        afterContainer.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 50).isActive = true

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 8
        afterContainer.addSubview(stack)
        stack.leadingAnchor.constraint(equalTo: afterContainer.leadingAnchor, constant: 12).isActive = true
        stack.trailingAnchor.constraint(equalTo: afterContainer.trailingAnchor, constant: -12).isActive = true
        stack.topAnchor.constraint(equalTo: afterContainer.topAnchor, constant: 10).isActive = true
        stack.bottomAnchor.constraint(equalTo: afterContainer.bottomAnchor, constant: -10).isActive = true

        let treeImage = UIImageView(image: .init(named: "tourTree")?.withRenderingMode(.alwaysTemplate))
        stack.addArrangedSubview(treeImage)
        self.treeImage = treeImage

        let afterLabel = UILabel()
        afterLabel.translatesAutoresizingMaskIntoConstraints = false
        afterLabel.text = .localized(.after)
        afterLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        afterLabel.adjustsFontForContentSizeCategory = true
        stack.addArrangedSubview(afterLabel)
        self.afterLabel = afterLabel

        let afterEllipse = UIImageView(image: .init(named: "tourEllipseAfter"))
        afterEllipse.translatesAutoresizingMaskIntoConstraints = false
        addSubview(afterEllipse)
        afterEllipse.trailingAnchor.constraint(equalTo: afterContainer.leadingAnchor).isActive = true
        afterEllipse.bottomAnchor.constraint(equalTo: afterContainer.centerYAnchor).isActive = true

        let afterDot = Dot(effect: UIBlurEffect(style: .light))
        addSubview(afterDot)
        afterDot.heightAnchor.constraint(equalToConstant: 20).isActive = true
        afterDot.widthAnchor.constraint(equalToConstant: 20).isActive = true
        afterDot.bottomAnchor.constraint(equalTo: afterEllipse.topAnchor).isActive = true
        afterDot.centerXAnchor.constraint(equalTo: afterEllipse.leadingAnchor).isActive = true
    }

    func applyTheme() {
        beforeContainer.backgroundColor = .legacyTheme.ecosia.welcomeBackground
        afterContainer.backgroundColor = .legacyTheme.ecosia.welcomeBackground
        beforeLabel.textColor = .legacyTheme.ecosia.primaryText
        afterLabel.textColor = .legacyTheme.ecosia.primaryText
        treeImage.tintColor = .legacyTheme.ecosia.primaryBrand
    }
    
    func updateAccessibilitySettings() {
        isAccessibilityElement = false
        shouldGroupAccessibilityChildren = true
    }
}

private final class Dot: UIVisualEffectView {

    override init(effect: UIVisualEffect?) {
        super.init(effect: effect)
        setup()
    }
    
    required init?(coder: NSCoder) {  nil }

    func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 10
        layer.masksToBounds = true

        let centerDot = UIView()
        centerDot.translatesAutoresizingMaskIntoConstraints = false
        centerDot.layer.cornerRadius = 4
        centerDot.backgroundColor = .Light.Background.primary
        contentView.addSubview(centerDot)

        centerDot.heightAnchor.constraint(equalToConstant: 8).isActive = true
        centerDot.widthAnchor.constraint(equalToConstant: 8).isActive = true
        centerDot.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        centerDot.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
}
