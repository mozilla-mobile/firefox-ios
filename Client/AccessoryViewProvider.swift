// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

class AccessoryViewProvider: UIView, Themeable {
    private struct AccessoryViewUX {
        static let toolbarHeight: CGFloat = 50
    }

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    var showCreditCard = false
    let target: TabWebView
    let throttler = Throttler(seconds: 1.0)

    // stubs - these closures will be given as selectors in a future task
    var previousClosure: (() -> Void)?
    var nextClosure: (() -> Void)?
    var doneClosure: (() -> Void)?
    var savedCardsClosure: (() -> Void)?

    private var toolbar: UIToolbar = .build { toolbar in
        toolbar.sizeToFit()
    }

    lazy private var previousButton = UIBarButtonItem(image: UIImage(systemName: "chevron.up"),
                                                      style: .plain,
                                                      target: target,
                                                      action: nil)

    lazy private var nextButton = UIBarButtonItem(image: UIImage(systemName: "chevron.down"),
                                                  style: .plain,
                                                  target: target,
                                                  action: nil)

    lazy private var doneButton = UIBarButtonItem(title: .CreditCard.Settings.Done,
                                                  style: .done,
                                                  target: target,
                                                  action: nil)

    private let flexibleSpacer = UIBarButtonItem(systemItem: .flexibleSpace)

    private let fixedSpacer: UIView = .build { view in
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 2),
            view.heightAnchor.constraint(equalToConstant: 30)
        ])

        view.accessibilityElementsHidden = true
    }

    lazy private var cardImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: ImageIdentifiers.creditCardPlaceholder)?.withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityElementsHidden = true

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    lazy private var useCardTextLabel: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .title3, size: 16, weight: .medium)
        label.text = .CreditCard.Settings.UseSavedCardFromKeyboard
        label.numberOfLines = 0
    }

    private lazy var cardButtonStackView: UIStackView = .build { [weak self] stackView in
        guard let self = self else { return }

        stackView.addArrangedSubview(self.fixedSpacer)
        stackView.addArrangedSubview(self.cardImageView)
        stackView.addArrangedSubview(self.useCardTextLabel)
        stackView.addArrangedSubview(self.fixedSpacer)
        stackView.spacing = 2
        stackView.distribution = .equalCentering
    }

    init(for target: TabWebView,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.target = target
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter

        super.init(frame: CGRect(width: UIScreen.main.bounds.width,
                                 height: AccessoryViewUX.toolbarHeight))

        listenForThemeChange(self)
        setupLayout()
        applyTheme()

        self.notificationCenter.addObserver(self,
                                            selector: #selector(reloadViewWithDelay),
                                            name: .CreditCardAccessoryNeeded,
                                            object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func reloadViewWithDelay() {
        throttler.throttle { [weak self] in
            guard let self = self else { return }

            self.showCreditCard = true

            self.setNeedsLayout()
            self.setupLayout()
            self.layoutIfNeeded()
        }
    }

    private func setupLayout() {
        translatesAutoresizingMaskIntoConstraints = false

        if showCreditCard {
            let cardStackViewForBarButton = UIBarButtonItem(customView: cardButtonStackView)
            toolbar.items = [previousButton, nextButton, cardStackViewForBarButton, flexibleSpacer, doneButton]
        } else {
            toolbar.items = [previousButton, nextButton, flexibleSpacer, doneButton]
        }

        addSubview(toolbar)

        NSLayoutConstraint.activate([
            toolbar.widthAnchor.constraint(equalTo: super.widthAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    func applyTheme() {
        let theme = themeManager.currentTheme

        backgroundColor = theme.colors.layer5
        previousButton.tintColor = theme.colors.iconAccentBlue
        nextButton.tintColor = theme.colors.iconAccentBlue
        doneButton.tintColor = theme.colors.iconAccentBlue
        cardImageView.tintColor = theme.colors.iconPrimary
        cardButtonStackView.backgroundColor = .systemBackground
    }
}
