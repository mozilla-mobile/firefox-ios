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
        static let iconContainerCornerRadius: CGFloat = 8
        static let lockIconImageViewSize = CGSize(width: 40, height: 24)
        static let iconContainerNoLockLeadingSpace: CGFloat = 16
    }

    private var urlAbsolutePath: String?
    private var searchTerm: String?
    private var onTapLockIcon: ((UIButton) -> Void)?
    private var onLongPress: (() -> Void)?
    private weak var delegate: LocationViewDelegate?
    private var isUnifiedSearchEnabled = false
    private var lockIconImageName: String?
    private var lockIconNeedsTheming = false
    private var safeListedURLImageName: String?

    private var isEditing = false
    private var isURLTextFieldEmpty: Bool {
        urlTextField.text?.isEmpty == true
    }

    private var longPressRecognizer: UILongPressGestureRecognizer?

    private var doesURLTextFieldExceedViewWidth: Bool {
        guard let text = urlTextField.text, let font = urlTextField.font else {
            return false
        }
        let locationViewVisibleWidth = frame.width - iconContainerStackView.frame.width - UX.horizontalSpace
        let urlTextFieldWidth = text.size(withAttributes: [.font: font]).width

        return urlTextFieldWidth >= locationViewVisibleWidth
    }

    private var dotWidth: CGFloat {
        guard let font = urlTextField.font else { return 0 }
        let fontAttributes = [NSAttributedString.Key.font: font]
        let width = "...".size(withAttributes: fontAttributes).width
        return CGFloat(width)
    }

    private lazy var urlTextFieldColor: UIColor = .black
    private lazy var urlTextFieldSubdomainColor: UIColor = .clear
    private lazy var lockIconImageColor: UIColor = .clear
    private lazy var safeListedURLImageColor: UIColor = .clear
    private lazy var gradientLayer = CAGradientLayer()
    private lazy var gradientView: UIView = .build()

    private var urlTextFieldLeadingConstraint: NSLayoutConstraint?
    private var urlTextFieldTrailingConstraint: NSLayoutConstraint?
    private var iconContainerStackViewLeadingConstraint: NSLayoutConstraint?
    private var lockIconWidthAnchor: NSLayoutConstraint?

    // MARK: - Search Engine / Lock Image
    private lazy var iconContainerStackView: UIStackView = .build { view in
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fill
    }

    private lazy var iconContainerBackgroundView: UIView = .build { view in
        view.layer.cornerRadius = UX.iconContainerCornerRadius
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

    // MARK: - URL Text Field
    private lazy var urlTextField: LocationTextField = .build { [self] urlTextField in
        urlTextField.backgroundColor = .clear
        urlTextField.font = FXFontStyles.Regular.body.scaledFont()
        urlTextField.adjustsFontForContentSizeCategory = true
        urlTextField.autocompleteDelegate = self
        urlTextField.accessibilityActionsSource = self
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
        return urlTextField.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        return urlTextField.resignFirstResponder()
    }

    func configure(_ state: LocationViewState, delegate: LocationViewDelegate, isUnifiedSearchEnabled: Bool) {
        // TODO FXIOS-10210 Once the Unified Search experiment is complete, we won't need this extra layout logic and can
        // simply use the `.build` method on `DropDownSearchEngineView` on `LocationView`'s init.
        searchEngineContentView = isUnifiedSearchEnabled
                                  ? dropDownSearchEngineView
                                  : plainSearchEngineView
        searchEngineContentView.configure(state, delegate: delegate)

        configureLockIconButton(state)
        configureURLTextField(state)
        configureA11y(state)
        formatAndTruncateURLTextField()
        updateIconContainer()
        self.delegate = delegate
        self.isUnifiedSearchEnabled = isUnifiedSearchEnabled
        searchTerm = state.searchTerm
        onLongPress = state.onLongPress
    }

    func setAutocompleteSuggestion(_ suggestion: String?) {
        urlTextField.setAutocompleteSuggestion(suggestion)
    }

    // MARK: - Layout
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        DispatchQueue.main.async { [self] in
            formatAndTruncateURLTextField()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateGradient()
        updateURLTextFieldLeadingConstraintBasedOnState()
    }

    private func setupLayout() {
        addSubviews(urlTextField, iconContainerStackView, gradientView)
        iconContainerStackView.addSubview(iconContainerBackgroundView)
        iconContainerStackView.addArrangedSubview(searchEngineContentView)

        urlTextFieldLeadingConstraint = urlTextField.leadingAnchor.constraint(equalTo: iconContainerStackView.trailingAnchor)
        urlTextFieldLeadingConstraint?.isActive = true

        urlTextFieldTrailingConstraint = urlTextField.trailingAnchor.constraint(equalTo: trailingAnchor)
        urlTextFieldTrailingConstraint?.isActive = true

        iconContainerStackViewLeadingConstraint = iconContainerStackView.leadingAnchor.constraint(equalTo: leadingAnchor)
        iconContainerStackViewLeadingConstraint?.isActive = true

        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: urlTextField.topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: urlTextField.bottomAnchor),
            gradientView.leadingAnchor.constraint(equalTo: iconContainerStackView.trailingAnchor),
            gradientView.widthAnchor.constraint(equalToConstant: UX.gradientViewWidth),

            urlTextField.topAnchor.constraint(equalTo: topAnchor),
            urlTextField.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconContainerBackgroundView.topAnchor.constraint(equalTo: urlTextField.topAnchor),
            iconContainerBackgroundView.bottomAnchor.constraint(equalTo: urlTextField.bottomAnchor),
            iconContainerBackgroundView.leadingAnchor.constraint(equalTo: iconContainerStackView.leadingAnchor),
            iconContainerBackgroundView.trailingAnchor.constraint(equalTo: iconContainerStackView.trailingAnchor),

            lockIconButton.heightAnchor.constraint(equalToConstant: UX.lockIconImageViewSize.height),
            lockIconButton.widthAnchor.constraint(equalToConstant: UX.lockIconImageViewSize.width),

            iconContainerStackView.topAnchor.constraint(equalTo: topAnchor),
            iconContainerStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupGradientLayer() {
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientView.layer.addSublayer(gradientLayer)
    }

    private func updateGradient() {
        let showGradientForLongURL = doesURLTextFieldExceedViewWidth && !isEditing
        gradientView.isHidden = !showGradientForLongURL
        gradientLayer.frame = gradientView.bounds
    }

    private func updateURLTextFieldLeadingConstraintBasedOnState() {
        let shouldAdjustForOverflow = doesURLTextFieldExceedViewWidth && !isEditing
        let shouldAdjustForNonEmpty = !isURLTextFieldEmpty && !isEditing

        // hide the leading "..." by moving them behind the lock icon
        if shouldAdjustForOverflow {
            updateURLTextFieldLeadingConstraint(constant: -dotWidth)
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

    private func updateIconContainer() {
        guard !isEditing else {
            updateUIForSearchEngineDisplay()
            urlTextFieldTrailingConstraint?.constant = 0
            return
        }

        if isURLTextFieldEmpty {
            updateUIForSearchEngineDisplay()
        } else {
            updateUIForLockIconDisplay()
        }
        urlTextFieldTrailingConstraint?.constant = -UX.horizontalSpace
    }

    private func updateUIForSearchEngineDisplay() {
        removeContainerIcons()
        iconContainerStackView.addArrangedSubview(searchEngineContentView)
        updateURLTextFieldLeadingConstraint(constant: UX.horizontalSpace)
        iconContainerStackViewLeadingConstraint?.constant = UX.horizontalSpace
        updateGradient()
    }

    private func updateUIForLockIconDisplay() {
        guard !isEditing else { return }
        removeContainerIcons()
        iconContainerStackView.addArrangedSubview(lockIconButton)
        updateURLTextFieldLeadingConstraint()

        let leadingConstraint = lockIconImageName == nil ? UX.iconContainerNoLockLeadingSpace : 0.0

        iconContainerStackViewLeadingConstraint?.constant = leadingConstraint
        updateGradient()
    }

    private func updateWidthForLockIcon(_ width: CGFloat) {
        lockIconWidthAnchor?.isActive = false
        lockIconWidthAnchor = lockIconButton.widthAnchor.constraint(equalToConstant: width)
        lockIconWidthAnchor?.isActive = true
    }

    // MARK: - `urlTextField` Configuration
    private func configureURLTextField(_ state: LocationViewState) {
        isEditing = state.isEditing

        urlTextField.placeholder = state.urlTextFieldPlaceholder
        urlAbsolutePath = state.url?.absoluteString

        let shouldShowKeyboard = state.isEditing && state.shouldShowKeyboard
        _ = shouldShowKeyboard ? becomeFirstResponder() : resignFirstResponder()

        // Remove the default drop interaction from the URL text field so that our
        // custom drop interaction on the BVC can accept dropped URLs.
        if let dropInteraction = urlTextField.textDropInteraction {
            urlTextField.removeInteraction(dropInteraction)
        }

        // Once the user started typing we should not update the text anymore as that interferes with
        // setting the autocomplete suggestions which is done using a delegate method.
        guard !state.didStartTyping else { return }

        let text = (state.searchTerm != nil) && state.isEditing ? state.searchTerm : state.url?.absoluteString
        urlTextField.text = text

        // Start overlay mode & select text when in edit mode with a search term
        if shouldShowKeyboard, state.shouldSelectSearchTerm {
            DispatchQueue.main.async {
                self.urlTextField.text = text
                self.urlTextField.selectAll(nil)
            }
        }
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
    private func configureLockIconButton(_ state: LocationViewState) {
        lockIconImageName = state.lockIconImageName
        lockIconNeedsTheming = state.lockIconNeedsTheming
        safeListedURLImageName = state.safeListedURLImageName
        guard lockIconImageName != nil else {
            updateWidthForLockIcon(0)
            return
        }
        updateWidthForLockIcon(UX.lockIconImageViewSize.width)
        onTapLockIcon = state.onTapLockIcon

        setLockIconImage()
    }

    private func setLockIconImage() {
        guard let lockIconImageName else { return }
        var lockImage: UIImage?

        if let safeListedURLImageName {
            lockImage = UIImage(named: lockIconImageName)

            if lockIconNeedsTheming {
                lockImage = lockImage?.withTintColor(lockIconImageColor)
            }

            if let dotImage = UIImage(named: safeListedURLImageName)?.withTintColor(safeListedURLImageColor) {
                let image = lockImage!.overlayWith(image: dotImage, modifier: 0.4, origin: CGPoint(x: 13.5, y: 13))
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
        longPressRecognizer = gestureRecognizer
        urlTextField.addGestureRecognizer(gestureRecognizer)
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
        guard let pasteboardContents = UIPasteboard.general.string else { return }
        delegate?.locationViewDidSubmitText(pasteboardContents)
        urlTextField.text = pasteboardContents
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
        updateUIForSearchEngineDisplay()
        let searchText = searchTerm != nil ? searchTerm : urlAbsolutePath

        // `attributedText` property is set to nil to remove all formatting and truncation set before.
        textField.attributedText = nil
        textField.text = searchText

        delegate?.locationViewDidBeginEditing(searchText ?? "", shouldShowSuggestions: searchTerm != nil)
    }

    func locationTextFieldDidEndEditing(_ textField: UITextField) {
        formatAndTruncateURLTextField()
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
    private func configureA11y(_ state: LocationViewState) {
        lockIconButton.accessibilityIdentifier = state.lockIconButtonA11yId
        lockIconButton.accessibilityLabel = state.lockIconButtonA11yLabel

        urlTextField.accessibilityIdentifier = state.urlTextFieldA11yId
    }

    func accessibilityCustomActionsForView(_ view: UIView) -> [UIAccessibilityCustomAction]? {
        guard view === urlTextField else { return nil }
        return delegate?.locationViewAccessibilityActions()
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        let colors = theme.colors
        urlTextFieldColor = colors.textPrimary
        urlTextFieldSubdomainColor = colors.textSecondary
        gradientLayer.colors = colors.layerGradientURL.cgColors.reversed()
        searchEngineContentView.applyTheme(theme: theme)
        iconContainerBackgroundView.backgroundColor = colors.layerSearch
        lockIconButton.backgroundColor = colors.layerSearch
        urlTextField.applyTheme(theme: theme)
        safeListedURLImageColor = colors.iconAccentBlue
        lockIconButton.tintColor = colors.iconPrimary
        lockIconImageColor = colors.iconPrimary

        setLockIconImage()
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
