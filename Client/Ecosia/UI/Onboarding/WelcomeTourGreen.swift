/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Common

final class WelcomeTourGreen: UIView, Themeable {
    private lazy var searchLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = .localized(.sustainableShoes)
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()
    private lazy var counterLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "10"
        label.font = .systemFont(ofSize: 17).bold()
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()
    private lazy var counterSubtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = .localizedPlural(.searches, num: 500)
        label.font = .systemFont(ofSize: 13)
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()
    
    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init

    init(isCounterEnabled: Bool = false) {
        super.init(frame: .zero)
        setup(isCounterEnabled: isCounterEnabled)
        updateAccessibilitySettings()
        applyTheme()
    }

    required init?(coder: NSCoder) {  nil }

    func setup(isCounterEnabled: Bool) {
        let iPadOffset: CGFloat = traitCollection.userInterfaceIdiom == .pad ? 60 : 0
        
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 24 + iPadOffset
        addSubview(stack)
        
        stack.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        stack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -50 - iPadOffset).isActive = true

        let topImage = UIImageView(image: .init(named: "tourSearch"))
        topImage.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(topImage)

        topImage.addSubview(searchLabel)

        searchLabel.leadingAnchor.constraint(equalTo: topImage.leadingAnchor, constant: 55).isActive = true
        searchLabel.topAnchor.constraint(equalTo: topImage.topAnchor, constant: 35).isActive = true
        searchLabel.trailingAnchor.constraint(equalTo: topImage.trailingAnchor, constant: -40).isActive = true
        searchLabel.transform = .init(rotationAngle: Double.pi / -33)

        let bottomImage = UIImageView(image: .init(named: isCounterEnabled ? "tourCounter" : "tourGreen"))
        bottomImage.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(bottomImage)

        if isCounterEnabled {
            bottomImage.addSubview(counterLabel)
            bottomImage.addSubview(counterSubtitleLabel)
            
            NSLayoutConstraint.activate([
                counterLabel.topAnchor.constraint(equalTo: bottomImage.topAnchor, constant: 28),
                counterLabel.leadingAnchor.constraint(equalTo: bottomImage.leadingAnchor, constant: 65),
                counterLabel.trailingAnchor.constraint(equalTo: bottomImage.trailingAnchor, constant: -46),
                counterSubtitleLabel.topAnchor.constraint(equalTo: counterLabel.bottomAnchor, constant: 2),
                counterSubtitleLabel.leadingAnchor.constraint(equalTo: counterLabel.leadingAnchor),
                counterSubtitleLabel.trailingAnchor.constraint(equalTo: counterLabel.trailingAnchor)
            ])
            let angle: CGFloat = .pi / 33
            counterLabel.transform = .init(rotationAngle: angle)
            counterSubtitleLabel.transform = .init(rotationAngle: angle)
        }
        
        // upscale images for iPad
        if traitCollection.userInterfaceIdiom == .pad {
            bottomImage.transform = bottomImage.transform.scaledBy(x: 1.5, y: 1.5)
            topImage.transform = topImage.transform.scaledBy(x: 1.5, y: 1.5)
        }
    }

    func applyTheme() {
        searchLabel.textColor = .legacyTheme.ecosia.primaryText
        counterLabel.textColor = .legacyTheme.ecosia.primaryText
        counterSubtitleLabel.textColor = .legacyTheme.ecosia.secondaryText
    }
    
    func updateAccessibilitySettings() {
        isAccessibilityElement = false
        shouldGroupAccessibilityChildren = true
    }
}
