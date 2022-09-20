/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class NTPIntroViewController: UIViewController, NotificationThemeable {
    weak var content: UIView!
    weak var image: UIImageView!
    weak var waves: UIImageView!
    weak var headline: UILabel!
    weak var text: UILabel!
    weak var cta: UIButton!

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        content.layer.cornerRadius = 10
        content.clipsToBounds = true
        view.addSubview(content)
        self.content = content

        content.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        content.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        if view.traitCollection.userInterfaceIdiom == .pad {
            content.widthAnchor.constraint(lessThanOrEqualToConstant: 360).isActive = true
        }
        content.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16).isActive = true
        content.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16).isActive = true
        content.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 16).isActive = true
        content.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -16).isActive = true

        let contentHeight = content.heightAnchor.constraint(equalToConstant: 300)
        contentHeight.priority = .defaultHigh
        contentHeight.isActive = true

        let leftMargin = content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        leftMargin.priority = .defaultHigh
        leftMargin.isActive = true
        let rightMargin = content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        rightMargin.priority = .defaultHigh
        rightMargin.isActive = true

        let image = UIImageView(image: .init(named: "ntpIntro"))
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(image)
        self.image = image

        let waves = UIImageView(image: .init(named: "ntpIntroWaves"))
        waves.translatesAutoresizingMaskIntoConstraints = false
        waves.contentMode = .scaleToFill
        content.addSubview(waves)
        self.waves = waves

        image.centerXAnchor.constraint(equalTo: content.centerXAnchor).isActive = true
        image.setContentCompressionResistancePriority(.required, for: .vertical)
        image.topAnchor.constraint(equalTo: content.topAnchor).isActive = true
        image.leadingAnchor.constraint(equalTo: content.leadingAnchor).isActive = true
        image.trailingAnchor.constraint(equalTo: content.trailingAnchor).isActive = true

        waves.bottomAnchor.constraint(equalTo: image.bottomAnchor).isActive = true
        waves.heightAnchor.constraint(equalToConstant: 34).isActive = true
        waves.leadingAnchor.constraint(equalTo: content.leadingAnchor).isActive = true
        waves.trailingAnchor.constraint(equalTo: content.trailingAnchor).isActive = true
        waves.centerXAnchor.constraint(equalTo: content.centerXAnchor).isActive = true
        waves.setContentCompressionResistancePriority(.required, for: .vertical)

        let headline = UILabel()
        headline.text = .localized(.discoverEcosia)
        headline.translatesAutoresizingMaskIntoConstraints = false
        headline.font = .preferredFont(forTextStyle: .headline).bold()
        headline.adjustsFontForContentSizeCategory = true
        headline.numberOfLines = 0
        headline.textAlignment = .center
        content.addSubview(headline)
        self.headline = headline

        headline.topAnchor.constraint(equalTo: waves.bottomAnchor, constant: 8).isActive = true
        headline.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16).isActive = true
        headline.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16).isActive = true
        headline.setContentCompressionResistancePriority(.required, for: .vertical)

        let text = UILabel()
        text.text = .localized(.ecosiaNewLook)
        text.translatesAutoresizingMaskIntoConstraints = false
        text.font = .preferredFont(forTextStyle: .subheadline)
        text.adjustsFontForContentSizeCategory = true
        text.numberOfLines = 0
        text.textAlignment = .center
        text.setContentCompressionResistancePriority(.required, for: .vertical)
        text.setContentCompressionResistancePriority(.required, for: .horizontal)
        content.addSubview(text)
        self.text = text

        text.topAnchor.constraint(equalTo: headline.bottomAnchor, constant: 8).isActive = true
        text.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16).isActive = true
        text.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16).isActive = true

        let cta = EcosiaPrimaryButton()
        cta.contentEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16)
        cta.translatesAutoresizingMaskIntoConstraints = false
        cta.setTitle(.localized(.seeWhatsNew), for: .normal)
        cta.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        cta.titleLabel?.adjustsFontForContentSizeCategory = true
        cta.layer.cornerRadius = 25
        cta.addTarget(self, action: #selector(ctaTapped), for: .primaryActionTriggered)
        content.addSubview(cta)
        self.cta = cta

        cta.topAnchor.constraint(equalTo: text.bottomAnchor, constant: 24).isActive = true
        cta.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
        cta.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24).isActive = true
        cta.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16).isActive = true
        cta.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16).isActive = true

        cta.setContentHuggingPriority(.required, for: .vertical)

        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: .DisplayThemeChanged, object: nil)
        applyTheme()
    }

    @objc func applyTheme() {
        view.backgroundColor = .theme.ecosia.modalOverlayBackground
        headline.textColor = .theme.ecosia.primaryText
        text.textColor = .theme.ecosia.secondaryText
        content.backgroundColor = .theme.ecosia.ntpIntroBackground
        waves.tintColor = .theme.ecosia.ntpIntroBackground
        cta.setTitleColor(.theme.ecosia.primaryTextInverted, for: .normal)
        cta.backgroundColor = .theme.ecosia.primaryButton
    }

    @objc func ctaTapped() {
        dismiss(animated: true)
    }
}
