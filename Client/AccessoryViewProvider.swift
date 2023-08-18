// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

enum AccessoryType {
    case standard, creditCard
}

class AccessoryViewProvider: UIView, Themeable {
    private struct UX {
        static let toolbarHeight: CGFloat = 50
        static let cornerRadius: CGFloat = 4
        static let cardImageViewSize: CGFloat = 24
        static let fixedSpacerHeight: CGFloat = 30
        static let fixedLeadingSpacerWidth: CGFloat = 2
        static let fixedTrailingSpacerWidth: CGFloat = 3
        static let cardButtonStackViewSpacing: CGFloat = 2
    }

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    private var showCreditCard = false

    // stubs - these closures will be given as selectors in a future task
    var previousClosure: (() -> Void)?
    var nextClosure: (() -> Void)?
    var doneClosure: (() -> Void)?
    var savedCardsClosure: (() -> Void)?

    private var toolbar: UIToolbar = .build { toolbar in
        toolbar.sizeToFit()
    }

    private lazy var previousButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(systemName: "chevron.up"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(tappedPreviousButton))

        return button
    }()

    private lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(systemName: "chevron.down"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(tappedNextButton))

        return button
    }()

    private lazy var doneButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: .CreditCard.Settings.Done,
                                     style: .done,
                                     target: self,
                                     action: #selector(tappedDoneButton))

        return button
    }()

    private let flexibleSpacer = UIBarButtonItem(systemItem: .flexibleSpace)

    private let leadingFixedSpacer: UIView = .build()
    private let trailingFixedSpacer: UIView = .build()

    private lazy var cardImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: StandardImageIdentifiers.Large.creditCard)?.withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityElementsHidden = true

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: UX.cardImageViewSize),
            imageView.heightAnchor.constraint(equalToConstant: UX.cardImageViewSize)
        ])
    }

    private lazy var useCardTextLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .title3, size: 16, weight: .medium)
        label.text = .CreditCard.Settings.UseSavedCardFromKeyboard
        label.numberOfLines = 0
        label.accessibilityTraits = .button
    }

    private lazy var cardButtonStackView: UIStackView = .build { [weak self] stackView in
        guard let self = self else { return }

        let stackViewTapped = UITapGestureRecognizer(target: self, action: #selector(self.tappedCardButton))

        stackView.isUserInteractionEnabled = true
        stackView.addArrangedSubview(self.leadingFixedSpacer)
        stackView.addArrangedSubview(self.cardImageView)
        stackView.addArrangedSubview(self.useCardTextLabel)
        stackView.addArrangedSubview(self.trailingFixedSpacer)
        stackView.spacing = UX.cardButtonStackViewSpacing
        stackView.distribution = .equalCentering
        stackView.layer.cornerRadius = UX.cornerRadius
        stackView.addGestureRecognizer(stackViewTapped)
    }

    // MARK: Lifecycle

    init(themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter

        super.init(frame: CGRect(width: UIScreen.main.bounds.width,
                                 height: UX.toolbarHeight))

        listenForThemeChange(self)
        setupLayout()
        applyTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func removeFromSuperview() {
        super.removeFromSuperview()
        // Reset showing of credit card when dismissing the view
        // This is required otherwise it will always show credit card view
        // even if the input isn't of type credit card
        showCreditCard = false
        setupLayout()
    }

    // MARK: Layout and Theme

    func reloadViewFor(_ accessoryType: AccessoryType) {
        switch accessoryType {
        case .standard:
            showCreditCard = false
        case .creditCard:
            showCreditCard = true
        }

        setNeedsLayout()
        setupLayout()
        layoutIfNeeded()
    }

    private func setupSpacer(_ spacer: UIView, width: CGFloat) {
        NSLayoutConstraint.activate([
            spacer.widthAnchor.constraint(equalToConstant: width),
            spacer.heightAnchor.constraint(equalToConstant: UX.fixedSpacerHeight)
        ])
        spacer.accessibilityElementsHidden = true
    }

    private func setupLayout() {
        translatesAutoresizingMaskIntoConstraints = false
        setupSpacer(leadingFixedSpacer, width: UX.fixedLeadingSpacerWidth)
        setupSpacer(trailingFixedSpacer, width: UX.fixedTrailingSpacerWidth)

        if showCreditCard {
            let cardStackViewForBarButton = UIBarButtonItem(customView: cardButtonStackView)
            cardStackViewForBarButton.accessibilityTraits = .button
            cardStackViewForBarButton.accessibilityLabel = .CreditCard.Settings.UseSavedCardFromKeyboard
            toolbar.items = [previousButton, nextButton, cardStackViewForBarButton, flexibleSpacer, doneButton]
            toolbar.accessibilityElements = [previousButton, nextButton, cardStackViewForBarButton, doneButton]
        } else {
            toolbar.items = [previousButton, nextButton, flexibleSpacer, doneButton]
        }

        addSubview(toolbar)

        NSLayoutConstraint.activate([
            toolbar.widthAnchor.constraint(equalTo: super.widthAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: UX.toolbarHeight)
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

    // MARK: - Actions

    @objc
    private func tappedPreviousButton() {
        previousClosure?()
    }

    @objc
    private func tappedNextButton() {
        nextClosure?()
    }

    @objc
    private func tappedDoneButton() {
        doneClosure?()
    }

    @objc
    private func tappedCardButton() {
        savedCardsClosure?()
    }
}
