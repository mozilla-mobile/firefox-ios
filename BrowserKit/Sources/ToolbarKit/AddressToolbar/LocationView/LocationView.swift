// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class LocationView: UIView,
                          LocationTextFieldDelegate,
                          ThemeApplicable,
                          AccessibilityActionsSource,
                          MenuHelperURLBarInterface {
    // MARK: - Properties
    private enum UX {
        static let horizontalSpace: CGFloat = 8
        static let gradientViewWidth: CGFloat = 40
        static let safeOffset: CGFloat = 40
        static let lockIconImageViewSize = CGSize(width: 40, height: 24)
        static let shieldImageViewSize = CGSize(width: 24, height: 24)
        static let iconContainerNoLockLeadingSpace: CGFloat = 16
        static let iconAnimationTime: CGFloat = 0.1
        static let iconAnimationDelay: CGFloat = 0.03
        static let bottomAddressBarYoffset: CGFloat = -16
        static let bottomAddressBarYoffsetForHomeButton: CGFloat = -28
        static let topAddressBarYoffset: CGFloat = 26
        static let smallScale: CGFloat = 0.7
        static let identityResetAnimationDuration: TimeInterval = 0.2
        static let effectViewCornerRadius: CGFloat = 24
        static let effectViewLeadingPadding: CGFloat = -12
        static let effectViewTrailingPadding: CGFloat = 18
    }

    private var urlAbsolutePath: String?
    private var searchTerm: String?
    private var onTapLockIcon: (@MainActor (UIButton) -> Void)?
    private var onLongPress: (@MainActor () -> Void)?
    private weak var delegate: LocationViewDelegate?
    private var theme: Theme?
    private var isUnifiedSearchEnabled = false
    private var lockIconImageName: String?
    private var lockIconNeedsTheming = false
    private var safeListedURLImageName: String?
    private var scrollAlpha: CGFloat = 1
    private var hasAlternativeLocationColor = false
    private var config: LocationViewConfiguration?

    private var isEditing = false
    private var isURLTextFieldEmpty: Bool {
        urlTextField.text?.isEmpty == true
    }
    private var hasHomeIndicator: Bool {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return false }
        return window.safeAreaInsets.bottom > 0
    }

    private var tapGestureRecognizer: UITapGestureRecognizer?
    private var longPressGestureRecognizer: UILongPressGestureRecognizer?

    /// Determines if the URL text field's content is wider than the visible area, accounting for a safe offset.
    /// An additional offset (default is 0) used when reader mode is available,
    /// to ensure the text does not overlap the icon when the view is constrained to its superview.
    private func isURLTextFieldWiderThanVisibleArea(safeOffset offset: CGFloat = 0) -> Bool {
        guard let text = urlTextField.text, let font = urlTextField.font, !scrollAlpha.isZero else {
            return false
        }
        let locationViewVisibleWidth = frame.width - iconContainerStackView.frame.width - UX.horizontalSpace - offset
        let urlTextFieldWidth = text.size(withAttributes: [.font: font]).width

        return urlTextFieldWidth >= locationViewVisibleWidth
    }

    private var dotWidth: CGFloat {
        guard let font = urlTextField.font else { return 0 }
        let fontAttributes = [NSAttributedString.Key.font: font]
        let width = "...".size(withAttributes: fontAttributes).width
        return CGFloat(width)
    }

    private lazy var urlTextFieldColor: UIColor = .label
    // FXIOS-14906: https://mozilla-hub.atlassian.net/browse/FXIOS-14906
    private lazy var urlTextFieldPlaceholderColor: UIColor = .clear
    private lazy var urlTextFieldSubdomainColor: UIColor = .clear
    private lazy var lockIconImageColor: UIColor = .clear
    private lazy var safeListedURLImageColor: UIColor = .clear
    private lazy var gradientLayer = CAGradientLayer()
    private lazy var gradientView: UIView = .build()
    private lazy var containerView: UIView = .build()

    private var containerViewConstraints: [NSLayoutConstraint] = []
    private var urlTextFieldLeadingConstraint: NSLayoutConstraint?
    private var urlTextFieldTrailingConstraint: NSLayoutConstraint?
    private var iconContainerStackViewLeadingConstraint: NSLayoutConstraint?
    private var lockIconWidthAnchor: NSLayoutConstraint?

    // MARK: - Search Engine / Lock Image
    private lazy var iconContainerStackView: UIStackView = .build { view in
        view.alignment = .center
    }

    // TODO FXIOS-10210 Once the Unified Search experiment is complete, we will only need to use `DropDownSearchEngineView`
    // and we can remove `PlainSearchEngineView` from the project.
    private lazy var plainSearchEngineView: PlainSearchEngineView = .build()
    private lazy var dropDownSearchEngineView: DropDownSearchEngineView = .build()
    private lazy var searchEngineContentView: SearchEngineView = plainSearchEngineView
    private lazy var lockIconButton: UIButton = .build { button in
        button.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(self.didTapLockIcon), for: .touchUpInside)
    }

    private lazy var glassEffect: UIVisualEffect? = if #available(iOS 26.0, *) { UIGlassEffect() } else { nil }
    private lazy var effectView: UIVisualEffectView = .build {
        $0.layer.cornerRadius = UX.effectViewCornerRadius
    }

    // MARK: - URL Text Field
    private lazy var urlTextField: LocationTextField = .build { [self] urlTextField in
        urlTextField.backgroundColor = .clear
        urlTextField.font = FXFontStyles.Regular.body.scaledFont()
        urlTextField.adjustsFontForContentSizeCategory = true
        urlTextField.autocompleteDelegate = self
        urlTextField.accessibilityActionsSource = self
        // Update the `textAlignment` property only when the entire layout direction is RTL or LTR,
        // similar to Apple's handling in Safari, ensuring that `textAlignment` remains in sync with the layout constraints.
        let layoutDirection = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute)
        urlTextField.textAlignment = layoutDirection == .rightToLeft ? .right : .left
    }

    private var isURLTextFieldCentered = false {
        didSet {
            // We need to call applyTheme to ensure the colors are updated in sync whenever the layout changes.
            guard let theme, isURLTextFieldCentered != oldValue else { return }
            applyTheme(theme: theme)
        }
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
        setupGradientLayer()
        addLongPressGestureRecognizer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        // Skip if urlTextField is already first responder to avoid triggering duplicate delegate callbacks
        guard !urlTextField.isFirstResponder else { return true }
        return urlTextField.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        // Skip if urlTextField has already resigned to avoid redundant state changes
        guard urlTextField.isFirstResponder else { return true }
        return urlTextField.resignFirstResponder()
    }

    func configureNonInteractive(_ config: LocationViewConfiguration, uxConfig: AddressToolbarUXConfiguration) {
        isURLTextFieldCentered = uxConfig.isLocationTextCentered
        hasAlternativeLocationColor = uxConfig.hasAlternativeLocationColor
        configureLockIconButton(config)
        configureURLPlaceholder(basedOn: config)
        setTextFieldPlaceholder(color: urlTextFieldPlaceholderColor)
        urlTextField.text = config.url?.absoluteString
        updateIconContainer(iconContainerCornerRadius: uxConfig.toolbarCornerRadius,
                            isURLTextFieldCentered: isURLTextFieldCentered,
                            locationTextFieldTrailingPadding: uxConfig.locationTextFieldTrailingPadding)
        layoutContainerView(isEditing: config.isEditing, isURLTextFieldCentered: isURLTextFieldCentered)
        formatAndTruncateURLTextField()
    }

    func configure(_ config: LocationViewConfiguration,
                   delegate: LocationViewDelegate,
                   isUnifiedSearchEnabled: Bool,
                   uxConfig: AddressToolbarUXConfiguration,
                   addressBarPosition: AddressToolbarPosition) {
        self.config = config
        isURLTextFieldCentered = uxConfig.isLocationTextCentered
        hasAlternativeLocationColor = uxConfig.hasAlternativeLocationColor

        // TODO FXIOS-10210 Once the Unified Search experiment is complete, we won't need this extra layout logic and can
        // simply use the `.build` method on `DropDownSearchEngineView` on `LocationView`'s init.
        searchEngineContentView = isUnifiedSearchEnabled
                                  ? dropDownSearchEngineView
                                  : plainSearchEngineView

        searchEngineContentView.configure(
            config,
            isLocationTextCentered: uxConfig.isLocationTextCentered,
            delegate: delegate
        )

        applyToolbarAlphaIfNeeded(
            alpha: uxConfig.scrollAlpha,
            barPosition: addressBarPosition
        )
        configureLockIconButton(config)
        configureURLTextField(config)
        configureA11y(config)
        updateIconContainer(iconContainerCornerRadius: uxConfig.toolbarCornerRadius,
                            isURLTextFieldCentered: isURLTextFieldCentered,
                            locationTextFieldTrailingPadding: uxConfig.locationTextFieldTrailingPadding)
        handleGesture(&tapGestureRecognizer, type: UITapGestureRecognizer.self, action: #selector(becomeFirstResponder))
        handleGesture(
            &longPressGestureRecognizer,
            type: UILongPressGestureRecognizer.self,
            action: #selector(handleLongPress)
        )
        self.delegate = delegate
        self.isUnifiedSearchEnabled = isUnifiedSearchEnabled
        searchTerm = config.searchTerm
        onLongPress = config.onLongPress

        layoutContainerView(isEditing: config.isEditing, isURLTextFieldCentered: isURLTextFieldCentered)

        guard let theme else { return }
        applyTheme(theme: theme)
    }

    private func layoutContainerView(isEditing: Bool, isURLTextFieldCentered: Bool) {
        var newConstraints: [NSLayoutConstraint] = []
        if isEditing || !isURLTextFieldCentered || isURLTextFieldWiderThanVisibleArea() {
            // leading alignment configuration
            newConstraints = [
                containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            ]
        } else if isURLTextFieldWiderThanVisibleArea(safeOffset: UX.safeOffset) {
            newConstraints = [
                containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
                containerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
                containerView.centerXAnchor.constraint(equalTo: centerXAnchor)
            ]
        } else if let superview, !isURLTextFieldWiderThanVisibleArea(safeOffset: UX.safeOffset) {
            newConstraints = [
                containerView.leadingAnchor.constraint(greaterThanOrEqualTo: superview.leadingAnchor),
                containerView.trailingAnchor.constraint(lessThanOrEqualTo: superview.trailingAnchor),
                containerView.centerXAnchor.constraint(equalTo: superview.centerXAnchor)
            ]
        }

        // Only update the constraints if necessary
        guard !newConstraints.isEmpty else { return }

        NSLayoutConstraint.deactivate(containerViewConstraints)
        containerViewConstraints = newConstraints
        NSLayoutConstraint.activate(containerViewConstraints)
    }

    func setAutocompleteSuggestion(_ suggestion: String?) {
        urlTextField.setAutocompleteSuggestion(suggestion)
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()

        layoutContainerView(isEditing: isEditing, isURLTextFieldCentered: isURLTextFieldCentered)
        updateGradient()
        // Updates the URL text field's leading constraint to ensure it reflects the current layout state
        // during layout passes, such as on screen size or orientation changes.
        updateURLTextFieldLeadingConstraintBasedOnState()
    }

    private func setupLayout() {
        if #available(iOS 26.0, *) {
            addSubview(effectView)
            effectView.contentView.addSubview(containerView)
        } else {
            addSubview(containerView)
        }
        containerView.addSubviews(urlTextField, iconContainerStackView, gradientView)
        if #available(iOS 26.0, *) {
            NSLayoutConstraint.activate([
                effectView.topAnchor.constraint(equalTo: urlTextField.topAnchor),
                effectView.leadingAnchor.constraint(equalTo: iconContainerStackView.leadingAnchor,
                                                    constant: UX.effectViewLeadingPadding),
                effectView.trailingAnchor.constraint(equalTo: urlTextField.trailingAnchor,
                                                     constant: UX.effectViewTrailingPadding),
                effectView.bottomAnchor.constraint(equalTo: urlTextField.bottomAnchor)
            ])
        }
        iconContainerStackView.addArrangedSubview(searchEngineContentView)

        urlTextFieldLeadingConstraint = urlTextField.leadingAnchor.constraint(equalTo: iconContainerStackView.trailingAnchor)
        urlTextFieldLeadingConstraint?.isActive = true

        urlTextFieldTrailingConstraint = urlTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        urlTextFieldTrailingConstraint?.isActive = true

        iconContainerStackViewLeadingConstraint = iconContainerStackView.leadingAnchor.constraint(
            equalTo: containerView.leadingAnchor
        )
        iconContainerStackViewLeadingConstraint?.isActive = true

        containerViewConstraints = [
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ]

        NSLayoutConstraint.activate(containerViewConstraints)
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: urlTextField.topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: urlTextField.bottomAnchor),
            gradientView.leadingAnchor.constraint(equalTo: iconContainerStackView.trailingAnchor),
            gradientView.widthAnchor.constraint(equalToConstant: UX.gradientViewWidth),

            urlTextField.topAnchor.constraint(equalTo: containerView.topAnchor),
            urlTextField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            iconContainerStackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconContainerStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setupGradientLayer() {
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientView.layer.addSublayer(gradientLayer)
    }

    private func updateGradient() {
        let showGradientForLongURL = isURLTextFieldWiderThanVisibleArea() && !isEditing
        gradientView.isHidden = !showGradientForLongURL
        // Use the containerView height since gradient's view height could be still not updated here
        // This can avoid to call containerView.layoutIfNeeded() which is an expensive call.
        let gradientLayerSize = CGSize(width: gradientView.bounds.width, height: containerView.frame.height)
        gradientLayer.frame = CGRect(origin: gradientView.bounds.origin, size: gradientLayerSize)
    }

    private func updateURLTextFieldLeadingConstraintBasedOnState() {
        let shouldAdjustForOverflow = isURLTextFieldWiderThanVisibleArea() && !isEditing
        let shouldAdjustForNonEmpty = !isURLTextFieldEmpty && !isEditing

        func handleOverflowAdjustment() {
            // Hide the leading "..." by moving them behind the lock icon.
            updateURLTextFieldLeadingConstraint(constant: -dotWidth)
            if lockIconImageName == nil {
                // This is the case when we are in reader mode and the lock icon is not visible.
                updateWidthForLockIcon(UX.lockIconImageViewSize.width)
                iconContainerStackViewLeadingConstraint?.constant = 0
            }
        }

        if shouldAdjustForOverflow {
            handleOverflowAdjustment()
        } else if shouldAdjustForNonEmpty {
            updateURLTextFieldLeadingConstraint()
        } else {
            updateURLTextFieldLeadingConstraint(constant: UX.horizontalSpace)
        }
    }

    private func updateURLTextFieldLeadingConstraint(constant: CGFloat = 0) {
        urlTextFieldLeadingConstraint?.constant = constant
    }

    private func removeContainerIcons() {
        iconContainerStackView.removeAllArrangedViews()
    }

    private func updateIconContainer(iconContainerCornerRadius: CGFloat,
                                     isURLTextFieldCentered: Bool,
                                     locationTextFieldTrailingPadding: CGFloat) {
        guard !isEditing else {
            updateUIForSearchEngineDisplay(isURLTextFieldCentered: isURLTextFieldCentered)
            urlTextFieldTrailingConstraint?.constant = 0
            animateIconAppearance()
            return
        }

        if isURLTextFieldEmpty {
            updateUIForSearchEngineDisplay(isURLTextFieldCentered: isURLTextFieldCentered)
        } else {
            updateUIForLockIconDisplay()
        }
        animateIconAppearance()
        urlTextFieldTrailingConstraint?.constant = -locationTextFieldTrailingPadding
    }

    private func animateIconAppearance() {
        let shouldShowLockIcon: Bool
        if isEditing {
            lockIconButton.alpha = 0
            shouldShowLockIcon = false
        } else if isURLTextFieldEmpty {
            shouldShowLockIcon = false
        } else if lockIconImageName == nil {
            shouldShowLockIcon = false
        } else {
            shouldShowLockIcon = true
        }

        let isAnimationEnabled = !UIAccessibility.isReduceMotionEnabled
        if isAnimationEnabled {
            UIView.animate(withDuration: UX.iconAnimationTime, delay: UX.iconAnimationDelay) {
                self.searchEngineContentView.alpha = shouldShowLockIcon ? 0 : 1
                self.lockIconButton.alpha = shouldShowLockIcon ? 1 : 0
            }
        } else {
            searchEngineContentView.alpha = shouldShowLockIcon ? 0 : 1
            lockIconButton.alpha = shouldShowLockIcon ? 1 : 0
        }
    }

    private func updateUIForSearchEngineDisplay(isURLTextFieldCentered: Bool) {
        removeContainerIcons()
        if !isURLTextFieldCentered || isEditing {
            iconContainerStackView.addArrangedSubview(searchEngineContentView)
        }
        updateURLTextFieldLeadingConstraint(constant: UX.horizontalSpace)
        iconContainerStackViewLeadingConstraint?.constant = UX.horizontalSpace
        updateGradient()
    }

    private func updateUIForLockIconDisplay() {
        guard !isEditing else { return }
        removeContainerIcons()
        iconContainerStackView.addArrangedSubview(lockIconButton)
        updateURLTextFieldLeadingConstraintBasedOnState()

        let leadingConstraint = lockIconImageName == nil ? UX.iconContainerNoLockLeadingSpace : 0.0

        iconContainerStackViewLeadingConstraint?.constant = leadingConstraint
        updateGradient()
    }

    private func updateWidthForLockIcon(_ width: CGFloat) {
        lockIconWidthAnchor?.isActive = false
        lockIconWidthAnchor = lockIconButton.widthAnchor.constraint(equalToConstant: width)
        lockIconWidthAnchor?.isActive = true
    }

    // MARK: - LocationView Scaling
    private func shrinkLocationView(barPosition: AddressToolbarPosition) {
        let isiPad = UIDevice.current.userInterfaceIdiom == .pad
        let bottomAddressBarYoffset = if #available(iOS 26.0, *) {
            UX.bottomAddressBarYoffset
        } else {
            hasHomeIndicator ? UX.bottomAddressBarYoffset : UX.bottomAddressBarYoffsetForHomeButton
        }
        let yOffset: CGFloat = (barPosition == .bottom && !isiPad) ? bottomAddressBarYoffset : UX.topAddressBarYoffset
        UIView.animate(
            withDuration: UX.identityResetAnimationDuration,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                let scaledTransformation = CGAffineTransform(scaleX: UX.smallScale, y: UX.smallScale)
                    .translatedBy(x: 0, y: yOffset)
                self.transform = scaledTransformation
                self.urlTextField.isUserInteractionEnabled = false
            })
    }

    private func restoreLocationViewSize() {
        UIView.animate(
            withDuration: UX.identityResetAnimationDuration,
            delay: 0,
            options: [.curveEaseInOut],
            animations: { [unowned self] in
                transform = .identity
            },
            completion: { [unowned self] _ in
                urlTextField.isUserInteractionEnabled = true
            }
        )
    }

    private func removeGlassEffectImmediately() {
        guard #available(iOS 26.0, *) else { return }
        /// Workaround for iOS 26.0 bug: Setting `effectView.effect` to `nil` doesn't remove the glass effect.
        /// We work around this by first setting it to `UIBlurEffect()` and then to `nil`, which forces an immediate removal.
        effectView.effect = UIBlurEffect()
        effectView.effect = nil
    }

    private func applyToolbarAlphaIfNeeded(alpha: CGFloat, barPosition: AddressToolbarPosition) {
        guard scrollAlpha != alpha else { return }
        scrollAlpha = alpha
        if scrollAlpha.isZero {
            shrinkLocationView(barPosition: barPosition)
            if #available(iOS 26.0, *), barPosition == .bottom {
                effectView.effect = glassEffect
            } else {
                removeGlassEffectImmediately()
            }
        } else {
            restoreLocationViewSize()
            removeGlassEffectImmediately()
        }
        if let theme { applyTheme(theme: theme) }
    }

    // MARK: - `urlTextField` Configuration
    private func configureURLTextField(_ config: LocationViewConfiguration) {
        let configurationIsEditing = config.isEditing
        configureURLPlaceholder(basedOn: config)
        // This code is fragile and needs to be called in this exact location or it will break.
        // This is because when we rotate the device, a `keyboardWillHide` notification is fired
        // even though we have set the text field to the first responder. When that notification fires
        // this notification is re-called for both skeleton toolbars where `shouldShowKeyboard` is false
        // causing the keyboard to hide.
        // TODO: FXIOS-14618 don't fire the `keyboardWillHide` notification on device rotation
        let shouldShowKeyboard = configurationIsEditing && config.shouldShowKeyboard
        _ = shouldShowKeyboard ? becomeFirstResponder() : resignFirstResponder()

        // Remove the default drop interaction from the URL text field so that our
        // custom drop interaction on the BVC can accept dropped URLs.
        if let dropInteraction = urlTextField.textDropInteraction {
            urlTextField.removeInteraction(dropInteraction)
        }

        let targetAlpha: CGFloat = configurationIsEditing ? 1 : 0
        let isAnimationEnabled = !UIAccessibility.isReduceMotionEnabled
        if isAnimationEnabled {
            UIView.animate(withDuration: UX.iconAnimationTime, delay: UX.iconAnimationDelay) {
                self.urlTextField.clearButton?.alpha = targetAlpha
            }
        } else {
            urlTextField.clearButton?.alpha = targetAlpha
        }

        // Once the user started typing we should not update the text anymore as that interferes with
        // setting the autocomplete suggestions which is done using a delegate method.
        guard !config.didStartTyping else { return }
        let shouldShowSearchTerm = (config.searchTerm != nil) && configurationIsEditing
        let text = shouldShowSearchTerm ? config.searchTerm : config.url?.absoluteString
        urlTextField.text = text

        DispatchQueue.main.async { [unowned self] in
            if shouldShowKeyboard && config.shouldSelectSearchTerm {
                urlTextField.text = text
                urlTextField.selectAll(nil)
            }
        }
    }

    private func configureURLPlaceholder(basedOn config: LocationViewConfiguration) {
        isEditing = config.isEditing
        if !isEditing && config.url != nil {
            // allow proper centering of the urlTextField removing placeholder size.
            urlTextField.placeholder = nil
        } else {
            urlTextField.placeholder = config.urlTextFieldPlaceholder
        }
        urlAbsolutePath = config.url?.absoluteString
    }

    private func formatAndTruncateURLTextField() {
        guard !isEditing else { return }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingHead

        let urlString = urlAbsolutePath ?? ""
        let (subdomain, normalizedHost) = URL.getSubdomainAndHost(from: urlString)

        let attributedString = NSMutableAttributedString(
            string: normalizedHost,
            attributes: [.foregroundColor: urlTextFieldColor])

        if let subdomain {
            let range = NSRange(location: 0, length: subdomain.count)
            attributedString.addAttribute(.foregroundColor, value: urlTextFieldSubdomainColor, range: range)
        }
        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(
                location: 0,
                length: attributedString.length
            )
        )
        urlTextField.attributedText = attributedString
    }

    // MARK: - `lockIconButton` Configuration
    private func configureLockIconButton(_ config: LocationViewConfiguration) {
        lockIconButton.isUserInteractionEnabled = isURLTextFieldCentered ? false : true
        lockIconImageName = config.lockIconImageName
        lockIconNeedsTheming = config.lockIconNeedsTheming
        safeListedURLImageName = config.safeListedURLImageName
        guard lockIconImageName != nil else {
            updateWidthForLockIcon(0)
            return
        }
        if isURLTextFieldCentered {
            updateWidthForLockIcon(UX.shieldImageViewSize.width)
        } else {
            updateWidthForLockIcon(UX.lockIconImageViewSize.width)
        }
        onTapLockIcon = config.onTapLockIcon

        setLockIconImage()
    }

    private func setLockIconImage() {
        guard let lockIconImageName, !lockIconImageName.isEmpty else { return }
        var lockImage: UIImage?

        if let safeListedURLImageName {
            lockImage = UIImage(named: lockIconImageName)

            if lockIconNeedsTheming {
                lockImage = lockImage?.withTintColor(lockIconImageColor)
            }

            if let dotImage = UIImage(named: safeListedURLImageName)?.withTintColor(safeListedURLImageColor) {
                let origin = isURLTextFieldCentered ? CGPoint(x: 10, y: 10) : CGPoint(x: 13.5, y: 13)
                let image = lockImage?.overlayWith(image: dotImage, modifier: 0.4, origin: origin)
                lockIconButton.setImage(image, for: .normal)
            }
        } else {
            lockImage = UIImage(named: lockIconImageName)

            if lockIconNeedsTheming {
                lockImage = lockImage?.withRenderingMode(.alwaysTemplate)
            }

            lockIconButton.setImage(lockImage, for: .normal)
        }
    }

    // MARK: - Gesture Recognizers
    private func addLongPressGestureRecognizer() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(LocationView.handleLongPress))
        urlTextField.addGestureRecognizer(gestureRecognizer)
    }

    private func handleGesture<T: UIGestureRecognizer>(
        _ gesture: inout T?,
        type: T.Type,
        action: Selector
    ) {
        if isURLTextFieldCentered {
            if gesture == nil {
                let newGesture = type.init(target: self, action: action)
                addGestureRecognizer(newGesture)
                gesture = newGesture
            }
        } else if let existingGesture = gesture {
            removeGestureRecognizer(existingGesture)
            gesture = nil
        }
    }

    // MARK: - Selectors
    @objc
    private func didTapLockIcon() {
        onTapLockIcon?(lockIconButton)
    }

    @objc
    private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            onLongPress?()
        }
    }

    // MARK: - MenuHelperURLBarInterface
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == MenuHelperURLBarModel.selectorPasteAndGo {
            return UIPasteboard.general.hasStrings
        }

        return super.canPerformAction(action, withSender: sender)
    }

    func menuHelperPasteAndGo() {
        ensureMainThread {
            guard let pasteboardContents = UIPasteboard.general.string else { return }
            self.urlTextField.text = pasteboardContents
            self.delegate?.locationViewDidSubmitText(pasteboardContents)
        }
    }

    // MARK: - LocationTextFieldDelegate
    func locationTextField(_ textField: LocationTextField, didEnterText text: String) {
        delegate?.locationViewDidEnterText(text)
    }

    func locationTextFieldShouldReturn(_ textField: LocationTextField) -> Bool {
        guard let text = textField.text else { return true }
        if !text.trimmingCharacters(in: .whitespaces).isEmpty {
            delegate?.locationViewDidSubmitText(text)
            _ = textField.resignFirstResponder()
            return true
        } else {
            return false
        }
    }

    func locationTextFieldShouldClear(_ textField: LocationTextField) -> Bool {
        delegate?.locationViewDidClearText()
        return true
    }

    func locationTextFieldDidBeginEditing(_ textField: UITextField) {
        guard !isEditing else { return }
        updateUIForSearchEngineDisplay(isURLTextFieldCentered: isURLTextFieldCentered)
        let searchText = searchTerm != nil ? searchTerm : urlAbsolutePath

        // `attributedText` property is set to nil to remove all formatting and truncation set before.
        textField.attributedText = nil
        textField.text = searchText

        delegate?.locationViewDidBeginEditing(searchText ?? "", shouldShowSuggestions: searchTerm != nil)
    }

    func locationTextFieldDidEndEditing(_ textField: UITextField) {
        if isURLTextFieldEmpty {
            updateGradient()
        } else {
            updateUIForLockIconDisplay()
        }
    }

    func locationTextFieldNeedsSearchReset(_ textField: UITextField) {
        delegate?.locationTextFieldNeedsSearchReset()
    }

    // MARK: - Accessibility
    private func configureA11y(_ config: LocationViewConfiguration) {
        lockIconButton.accessibilityIdentifier = config.lockIconButtonA11yId
        lockIconButton.accessibilityLabel = config.lockIconButtonA11yLabel

        urlTextField.accessibilityIdentifier = config.urlTextFieldA11yId
        accessibilityElements = [iconContainerStackView, urlTextField]
    }

    func accessibilityCustomActionsForView(_ view: UIView) -> [UIAccessibilityCustomAction]? {
        guard view === urlTextField else { return nil }
        return delegate?.locationViewAccessibilityActions()
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        self.theme = theme
        let colors = theme.colors

        let mainBackgroundColor = hasAlternativeLocationColor ? colors.layerSurfaceMediumAlt : colors.layerSurfaceMedium
        if #available(iOS 26.0, *), scrollAlpha.isZero {
            // We want to use system colors when the location view is fully transparent
            // To make sure it blends well with the background when using glass effect.
            urlTextFieldColor =  .label
            urlTextFieldSubdomainColor = .label
            lockIconButton.tintColor = .label
        } else {
            urlTextFieldColor = colors.textPrimary
            urlTextFieldSubdomainColor = colors.textSecondary
            lockIconButton.tintColor = colors.textSecondary
        }
        gradientLayer.colors = Gradient(
            colors: [
                mainBackgroundColor.withAlphaComponent(1),
                mainBackgroundColor.withAlphaComponent(0)
            ]
        ).cgColors
        searchEngineContentView.applyTheme(theme: theme)
        lockIconButton.backgroundColor = scrollAlpha.isZero ? nil : mainBackgroundColor
        urlTextField.applyTheme(theme: theme)
        urlTextField.textColor = urlTextFieldColor
        setTextFieldPlaceholder(color: colors.textPrimary)
        urlTextFieldPlaceholderColor = colors.textPrimary
        safeListedURLImageColor = colors.iconAccentBlue
        lockIconImageColor = colors.textSecondary

        setLockIconImage()
        // Applying the theme to urlTextField can cause the url formatting to get removed
        // so we apply it again
        formatAndTruncateURLTextField()
    }

    private func setTextFieldPlaceholder(color: UIColor) {
        guard let placeholder = urlTextField.placeholder, !placeholder.isEmpty else { return }
        urlTextField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: color]
        )
    }

    // MARK: - UIGestureRecognizerDelegate
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // When long pressing a button make sure the textfield's long press gesture is not triggered
        return !(otherGestureRecognizer.view is UIButton)
    }
}

fileprivate extension UIImage {
    func overlayWith(image: UIImage,
                     modifier: CGFloat = 0.35,
                     origin: CGPoint = CGPoint(x: 15, y: 16)) -> UIImage {
        let newSize = CGSize(width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        image.draw(in: CGRect(origin: origin,
                              size: CGSize(width: size.width * modifier,
                                           height: size.height * modifier)))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return newImage
    }
}
