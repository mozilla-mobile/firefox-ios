/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Common

@available(iOS 14, *)
protocol DefaultBrowserDelegate: AnyObject {
    func defaultBrowserDidShow(_ defaultBrowser: DefaultBrowser)
}

@available(iOS 14, *)
final class DefaultBrowser: UIViewController, Themeable {
    
    weak var content: UIView!
    weak var image: UIImageView!
    weak var waves: UIImageView!
    weak var headline: UILabel!
    weak var text1: UILabel!
    weak var text2: UILabel!
    weak var arrow1: UIImageView!
    weak var arrow2: UIImageView!
    weak var cta: UIButton!
    weak var skip: UIButton!
    weak var delegate: DefaultBrowserDelegate?
    
    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    convenience init(delegate: DefaultBrowserDelegate) {
        self.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        if traitCollection.userInterfaceIdiom == .pad {
            modalPresentationStyle = .formSheet
            preferredContentSize = .init(width: 544, height: 600)
        } else {
            modalPresentationCapturesStatusBarAppearance = true
        }
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) { nil }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
       .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        applyTheme()

        listenForThemeChange(self.view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Analytics.shared.defaultBrowser(.view)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        modalTransitionStyle = .crossDissolve
        self.delegate?.defaultBrowserDidShow(self)
    }

    private func setupViews() {
        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        content.layer.cornerRadius = 10
        content.clipsToBounds = true
        view.addSubview(content)
        self.content = content

        content.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        content.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        content.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        content.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor).isActive = true

        let contentHeight = content.heightAnchor.constraint(equalToConstant: 300)
        contentHeight.priority = .defaultHigh
        contentHeight.isActive = true

        let image = UIImageView(image: .init(named: "defaultBrowser"))
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(image)
        self.image = image

        image.topAnchor.constraint(equalTo: content.topAnchor).isActive = true
        image.leadingAnchor.constraint(equalTo: content.leadingAnchor).isActive = true
        image.trailingAnchor.constraint(equalTo: content.trailingAnchor).isActive = true
        image.setContentCompressionResistancePriority(.required, for: .vertical)
        image.setContentHuggingPriority(.required, for: .vertical)

        let forest = UIImageView(image: .init(named: "forestIcons"))
        forest.translatesAutoresizingMaskIntoConstraints = false
        forest.contentMode = .bottom
        content.addSubview(forest)
        forest.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        forest.bottomAnchor.constraint(equalTo: image.bottomAnchor).isActive = true

        if view.traitCollection.userInterfaceIdiom == .pad {
            forest.widthAnchor.constraint(equalToConstant: 544).isActive = true
            forest.heightAnchor.constraint(equalToConstant: 135).isActive = true
            forest.contentMode = .scaleAspectFit
        }

        let waves = UIImageView(image: .init(named: "waves"))
        waves.translatesAutoresizingMaskIntoConstraints = false
        waves.contentMode = .scaleToFill
        content.addSubview(waves)
        self.waves = waves

        waves.bottomAnchor.constraint(equalTo: image.bottomAnchor).isActive = true
        waves.heightAnchor.constraint(equalToConstant: 34).isActive = true
        waves.leadingAnchor.constraint(equalTo: content.leadingAnchor).isActive = true
        waves.trailingAnchor.constraint(equalTo: content.trailingAnchor).isActive = true

        let headline = UILabel()
        headline.text = .localized(.makeEcosiaYourDefaultBrowser)
        headline.translatesAutoresizingMaskIntoConstraints = false
        headline.font = .preferredFont(forTextStyle: .title3).bold()
        headline.adjustsFontForContentSizeCategory = true
        headline.numberOfLines = 0
        headline.setContentCompressionResistancePriority(.required, for: .vertical)
        content.addSubview(headline)
        self.headline = headline

        headline.topAnchor.constraint(equalTo: waves.bottomAnchor, constant: 16).isActive = true
        headline.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16).isActive = true
        headline.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16).isActive = true
        let headlineHeight = headline.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
        headlineHeight.priority = .defaultLow
        headlineHeight.isActive = true

        let labelStack = UIStackView()
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        labelStack.axis = .vertical
        labelStack.spacing = 4
        view.addSubview(labelStack)

        labelStack.leadingAnchor.constraint(equalTo: headline.leadingAnchor).isActive = true
        labelStack.trailingAnchor.constraint(equalTo: headline.trailingAnchor).isActive = true
        labelStack.topAnchor.constraint(equalTo: headline.bottomAnchor, constant: 16).isActive = true

        let line1 = UIStackView()
        line1.spacing = 10
        line1.axis = .horizontal
        labelStack.addArrangedSubview(line1)

        let arrow1 = UIImageView(image: .init(systemName: "checkmark"))
        arrow1.contentMode = .scaleAspectFit
        arrow1.widthAnchor.constraint(equalToConstant: 16).isActive = true
        line1.addArrangedSubview(arrow1)
        self.arrow1 = arrow1

        let text1 = UILabel()
        text1.text = .localized(.openAllLinksToPlantTrees, incentiveRestrictedSearchAlternativeKey: .openAllLinksAutomatically)
        text1.translatesAutoresizingMaskIntoConstraints = false
        text1.font = .preferredFont(forTextStyle: .subheadline)
        text1.adjustsFontForContentSizeCategory = true
        text1.numberOfLines = 0
        text1.setContentCompressionResistancePriority(.required, for: .vertical)
        text1.setContentCompressionResistancePriority(.required, for: .horizontal)
        line1.addArrangedSubview(text1)
        self.text1 = text1

        let line2 = UIStackView()
        line2.spacing = 10
        line2.axis = .horizontal
        labelStack.addArrangedSubview(line2)

        let arrow2 = UIImageView(image: .init(systemName: "checkmark"))
        arrow2.contentMode = .scaleAspectFit
        arrow2.widthAnchor.constraint(equalToConstant: 16).isActive = true
        line2.addArrangedSubview(arrow2)
        self.arrow2 = arrow2

        let text2 = UILabel()
        text2.text = .localized(.growYourImpact, incentiveRestrictedSearchAlternativeKey: .beClimateActive)
        text2.translatesAutoresizingMaskIntoConstraints = false
        text2.font = .preferredFont(forTextStyle: .subheadline)
        text2.adjustsFontForContentSizeCategory = true
        text2.numberOfLines = 0
        text2.setContentCompressionResistancePriority(.required, for: .vertical)
        text2.setContentCompressionResistancePriority(.required, for: .horizontal)
        line2.addArrangedSubview(text2)
        self.text2 = text2

        let cta = EcosiaPrimaryButton()
        cta.contentEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16)
        cta.translatesAutoresizingMaskIntoConstraints = false
        cta.setTitle(.localized(.openSettings), for: .normal)
        cta.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        cta.titleLabel?.adjustsFontForContentSizeCategory = true
        cta.layer.cornerRadius = 25
        cta.addTarget(self, action: #selector(ctaTapped), for: .primaryActionTriggered)
        content.addSubview(cta)
        self.cta = cta

        cta.topAnchor.constraint(equalTo: labelStack.bottomAnchor, constant: 24).isActive = true
        cta.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
        cta.leadingAnchor.constraint(equalTo: headline.leadingAnchor).isActive = true
        cta.trailingAnchor.constraint(equalTo: headline.trailingAnchor).isActive = true
        cta.setContentHuggingPriority(.required, for: .vertical)

        let skip = UIButton(type: .system)
        skip.translatesAutoresizingMaskIntoConstraints = false
        skip.backgroundColor = .clear
        skip.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        skip.titleLabel?.adjustsFontForContentSizeCategory = true
        skip.setTitle(.localized(.maybeLater), for: .normal)
        skip.addTarget(self, action: #selector(skipTapped), for: .primaryActionTriggered)
        content.addSubview(skip)
        self.skip = skip

        skip.topAnchor.constraint(equalTo: cta.bottomAnchor, constant: 8).isActive = true
        skip.leadingAnchor.constraint(equalTo: cta.leadingAnchor).isActive = true
        skip.trailingAnchor.constraint(equalTo: cta.trailingAnchor).isActive = true
        skip.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
        skip.bottomAnchor.constraint(equalTo: content.safeAreaLayoutGuide.bottomAnchor, constant: -16).isActive = true
    }

    @objc func applyTheme() {
        view.backgroundColor = .clear
        headline.textColor = .legacyTheme.ecosia.primaryText
        text1.textColor = .legacyTheme.ecosia.secondaryText
        text2.textColor = .legacyTheme.ecosia.secondaryText
        arrow1.tintColor = .legacyTheme.ecosia.primaryButton
        arrow2.tintColor = .legacyTheme.ecosia.primaryButton
        content.backgroundColor = .legacyTheme.ecosia.ntpIntroBackground
        waves.tintColor = .legacyTheme.ecosia.ntpIntroBackground
        cta.setTitleColor(.legacyTheme.ecosia.primaryTextInverted, for: .normal)
        skip.setTitleColor(.legacyTheme.ecosia.primaryButton, for: .normal)
        cta.backgroundColor = .legacyTheme.ecosia.primaryButton
    }

    @objc private func skipTapped() {
        Analytics.shared.defaultBrowser(.close)
        dismiss(animated: true)
    }

    @objc private func ctaTapped() {
        Analytics.shared.defaultBrowser(.click)

        dismiss(animated: true) {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
        }
    }
}
