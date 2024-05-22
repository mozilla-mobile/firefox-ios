// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// `LocationViewDelegate` protocol defines the delegate methods that respond
/// to user interactions with a location view.
protocol LocationViewDelegate: AnyObject {
    /// Called when the user enters text into the location view.
    ///
    /// - Parameter text: The text that was entered.
    func locationViewDidEnterText(_ text: String)
    /// Called when the user begins editing text in the location view.
    ///
    /// - Parameter text: The initial text in the location view when the user began editing.
    func locationViewDidBeginEditing(_ text: String)
    /// Called when the location view should perform a search based on the entered text.
    ///
    /// - Parameter text: The text for which the location view should search.
    func locationViewShouldSearchFor(_ text: String)

    /// Called to determine the display text for a given URL in the location view.
    ///
    /// - Parameter url: The URL for which to determine the display text.
    /// - Returns: The display text as an optional String. If the URL is nil
    ///  or cannot be converted to a display text, returns nil.
    func locationViewDisplayTextForURL(_ url: URL?) -> String?
}

public struct LocationViewState {
    public let clearButtonA11yId: String
    public let clearButtonA11yLabel: String

    public let searchEngineImageViewA11yId: String
    public let searchEngineImageViewA11yLabel: String

    public let urlTextFieldPlaceholder: String
    public let urlTextFieldA11yId: String
    public let urlTextFieldA11yLabel: String

    public let searchEngineImageName: String
    public let lockIconImageName: String
    public let url: String?

    public init(
        clearButtonA11yId: String,
        clearButtonA11yLabel: String,
        searchEngineImageViewA11yId: String,
        searchEngineImageViewA11yLabel: String,
        urlTextFieldPlaceholder: String,
        urlTextFieldA11yId: String,
        urlTextFieldA11yLabel: String,
        searchEngineImageName: String,
        lockIconImageName: String,
        url: String?
    ) {
        self.clearButtonA11yId = clearButtonA11yId
        self.clearButtonA11yLabel = clearButtonA11yLabel
        self.searchEngineImageViewA11yId = searchEngineImageViewA11yId
        self.searchEngineImageViewA11yLabel = searchEngineImageViewA11yLabel
        self.urlTextFieldPlaceholder = urlTextFieldPlaceholder
        self.urlTextFieldA11yId = urlTextFieldA11yId
        self.urlTextFieldA11yLabel = urlTextFieldA11yLabel
        self.searchEngineImageName = searchEngineImageName
        self.lockIconImageName = lockIconImageName
        self.url = url
    }
}

class LocationView: UIView, UITextFieldDelegate, ThemeApplicable {
    // MARK: - Properties
    private enum UX {
        static let horizontalSpace: CGFloat = 8
        static let gradientViewVerticalPadding: CGFloat = 8
        static let gradientViewWidth: CGFloat = 40
        static let searchEngineImageViewCornerRadius: CGFloat = 4
        static let lockIconWidth: CGFloat = 20
        static let searchEngineImageViewSize = CGSize(width: 24, height: 24)
        static let clearButtonSize = CGSize(width: 40, height: 40)
        static let transitionDuration: TimeInterval = 0.3
    }

    private var urlAbsolutePath: String?
    private var notifyTextChanged: (() -> Void)?
    private var locationViewDelegate: LocationViewDelegate?

    private var isURLTextFieldEmpty: Bool {
        urlTextField.text?.isEmpty == true
    }

    private lazy var urlTextFieldSubdomainColor: UIColor = .clear
    private lazy var gradientLayer = CAGradientLayer()
    private lazy var gradientView: UIView = .build()

    private var clearButtonWidthConstraint: NSLayoutConstraint?
    private var gradientViewWidthConstraint: NSLayoutConstraint?
    private var iconContainerStackViewWidthConstraint: NSLayoutConstraint?
    private var urlTextFieldLeadingConstraint: NSLayoutConstraint?
    private var urlTextFieldTrailingConstraint: NSLayoutConstraint?

    private lazy var clearButton: UIButton = .build { button in
        button.setImage(
            UIImage(named: StandardImageIdentifiers.Large.crossCircleFill)?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        button.addTarget(self, action: #selector(self.clearURLText), for: .touchUpInside)
    }

    private lazy var iconContainerStackView: UIStackView = .build()

    private lazy var searchEngineContentView: UIView = .build()

    private lazy var searchEngineImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = UX.searchEngineImageViewCornerRadius
        imageView.isAccessibilityElement = true
    }

    private lazy var lockIconImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var urlTextField: UITextField = .build { [self] urlTextField in
        urlTextField.accessibilityIdentifier = "url"
        urlTextField.backgroundColor = .clear
        urlTextField.font = UIFont.preferredFont(forTextStyle: .body)
        urlTextField.adjustsFontForContentSizeCategory = true
        urlTextField.rightView = clearButton
        urlTextField.rightViewMode = .whileEditing
        urlTextField.delegate = self
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
        setupGradientLayer()
        hideClearButton()

        urlTextField.addTarget(self, action: #selector(LocationView.textDidChange), for: .editingChanged)
        notifyTextChanged = { [self] in
            guard urlTextField.isEditing else { return }

            if isURLTextFieldEmpty {
                hideClearButton()
            } else {
                showClearButton()
            }

            urlTextField.text = urlTextField.text?.lowercased()
            urlAbsolutePath = urlTextField.text
            locationViewDelegate?.locationViewDidEnterText(urlTextField.text ?? "")
        }
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

    func configure(_ state: LocationViewState, delegate: LocationViewDelegate) {
        searchEngineImageView.image = UIImage(named: state.searchEngineImageName)
        lockIconImageView.image = UIImage(named: state.lockIconImageName)?.withRenderingMode(.alwaysTemplate)
        configureURLTextField(state)
        configureA11y(state)
        formatAndTruncateURLTextField()
        locationViewDelegate = delegate
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
        updateGradientLayerFrame()
        updateURLTextFieldLeadingConstraintBasedOnState()
    }

    private func setupLayout() {
        addSubviews(urlTextField, iconContainerStackView, gradientView, clearButton)
        searchEngineContentView.addSubview(searchEngineImageView)
        iconContainerStackView.addArrangedSubview(searchEngineContentView)

        urlTextFieldTrailingConstraint = urlTextField.trailingAnchor.constraint(
            equalTo: trailingAnchor,
            constant: UX.horizontalSpace
        )
        urlTextFieldTrailingConstraint?.isActive = true

        NSLayoutConstraint.activate(
            [
                gradientView.topAnchor.constraint(equalTo: urlTextField.topAnchor),
                gradientView.bottomAnchor.constraint(equalTo: urlTextField.bottomAnchor),
                gradientView.leadingAnchor.constraint(equalTo: iconContainerStackView.trailingAnchor),
                gradientView.centerYAnchor.constraint(equalTo: urlTextField.centerYAnchor),

                urlTextField.topAnchor.constraint(equalTo: topAnchor),
                urlTextField.bottomAnchor.constraint(equalTo: bottomAnchor),

                clearButton.heightAnchor.constraint(equalToConstant: UX.clearButtonSize.height),

                searchEngineImageView.heightAnchor.constraint(equalToConstant: UX.searchEngineImageViewSize.height),
                searchEngineImageView.widthAnchor.constraint(equalToConstant: UX.searchEngineImageViewSize.width),
                searchEngineImageView.centerXAnchor.constraint(equalTo: searchEngineContentView.centerXAnchor),
                searchEngineImageView.centerYAnchor.constraint(equalTo: searchEngineContentView.centerYAnchor),

                iconContainerStackView.topAnchor.constraint(equalTo: topAnchor),
                iconContainerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
                iconContainerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.horizontalSpace),
            ]
        )
    }

    private func setupGradientLayer() {
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientView.layer.addSublayer(gradientLayer)
    }

    private var doesURLTextFieldExceedViewWidth: Bool {
        guard let text = urlTextField.text, let font = urlTextField.font else {
            return false
        }
        let locationViewWidth = frame.width - (UX.horizontalSpace * 2)
        let fontAttributes = [NSAttributedString.Key.font: font]
        let urlTextFieldWidth = text.size(withAttributes: fontAttributes).width
        return urlTextFieldWidth >= locationViewWidth
    }

    private func updateGradientLayerFrame() {
        let showGradientForLongURL = doesURLTextFieldExceedViewWidth && !urlTextField.isFirstResponder
        let width = showGradientForLongURL ? UX.gradientViewWidth : 0
        let frame = showGradientForLongURL ? gradientView.bounds : CGRect()

        DispatchQueue.main.async { [self] in
            updateWidthConstraint(&gradientViewWidthConstraint, for: gradientView, to: width)
            gradientLayer.frame = frame
        }
    }

    private func updateURLTextFieldLeadingConstraintBasedOnState() {
        let isTextFieldFocused = urlTextField.isFirstResponder
        let shouldAdjustForOverflow = doesURLTextFieldExceedViewWidth && !isTextFieldFocused
        let shouldAdjustForNonEmpty = !isURLTextFieldEmpty && !isTextFieldFocused

        if shouldAdjustForOverflow {
            updateURLTextFieldLeadingConstraint(equalTo: iconContainerStackView.leadingAnchor)
        } else if shouldAdjustForNonEmpty {
            updateURLTextFieldLeadingConstraint(equalTo: iconContainerStackView.trailingAnchor)
        }
    }

    private func updateURLTextFieldLeadingConstraint(equalTo anchor: NSLayoutXAxisAnchor, constant: CGFloat = 0) {
        urlTextFieldLeadingConstraint?.isActive = false
        urlTextFieldLeadingConstraint = urlTextField.leadingAnchor.constraint(equalTo: anchor, constant: constant)
        urlTextFieldLeadingConstraint?.isActive = true
    }

    private func updateWidthConstraint(
        _ constraint: inout NSLayoutConstraint?,
        for view: UIView,
        to widthConstant: CGFloat
    ) {
        constraint?.isActive = false
        constraint = view.widthAnchor.constraint(equalToConstant: widthConstant)
        constraint?.isActive = true
    }

    private func addSearchEngineButton() {
        iconContainerStackView.addArrangedSubview(searchEngineContentView)
    }

    private func showClearButton() {
        clearButton.isHidden = false
        updateWidthConstraint(&clearButtonWidthConstraint, for: clearButton, to: UX.clearButtonSize.width)
        updateWidthConstraint(&gradientViewWidthConstraint, for: gradientView, to: 0)
    }

    private func hideClearButton() {
        clearButton.isHidden = true
        updateWidthConstraint(&clearButtonWidthConstraint, for: clearButton, to: 0)
        updateWidthConstraint(&gradientViewWidthConstraint, for: gradientView, to: UX.gradientViewWidth)
    }

    private func addLockIconImageView() {
        iconContainerStackView.addArrangedSubview(lockIconImageView)
    }

    private func removeContainerIcons() {
        iconContainerStackView.removeAllArrangedViews()
    }

    // MARK: - `urlTextField` Configuration
    private func configureURLTextField(_ state: LocationViewState) {
        urlTextField.text = state.url
        urlTextField.placeholder = state.urlTextFieldPlaceholder
        urlAbsolutePath = urlTextField.text
    }

    private func formatAndTruncateURLTextField() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingHead

        let urlString = urlAbsolutePath ?? ""
        let (subdomain, normalizedHost) = URL.getSubdomainAndHost(from: urlString)

        let attributedString = NSMutableAttributedString(string: normalizedHost)

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

    private func animateURLText(
        _ textField: UITextField,
        options: UIView.AnimationOptions,
        textAlignment: NSTextAlignment,
        completion: (() -> Void)? = nil
    ) {
        UIView.transition(
            with: textField,
            duration: UX.transitionDuration,
            options: options) {
            textField.textAlignment = textAlignment
        } completion: { _ in
            completion?()
        }
    }

    // MARK: - Selectors
    @objc
    private func clearURLText() {
        urlTextField.text = ""
        notifyTextChanged?()
    }

    @objc
    func textDidChange(_ textField: UITextField) {
        notifyTextChanged?()
    }

    // MARK: - UITextFieldDelegate
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        removeContainerIcons()

        updateWidthConstraint(
            &iconContainerStackViewWidthConstraint,
            for: iconContainerStackView,
            to: UX.searchEngineImageViewSize.width
        )
        updateURLTextFieldLeadingConstraint(
            equalTo: iconContainerStackView.trailingAnchor,
            constant: UX.horizontalSpace
        )
        urlTextFieldTrailingConstraint?.constant = 0

        if !isURLTextFieldEmpty {
            showClearButton()
            animateURLText(textField, options: .transitionFlipFromBottom, textAlignment: .natural)
        } else {
            hideClearButton()
        }
        addSearchEngineButton()
        updateGradientLayerFrame()

        let url = URL(string: textField.text ?? "")
        let queryText = locationViewDelegate?.locationViewDisplayTextForURL(url)

        DispatchQueue.main.async { [self] in
            // `attributedText` property is set to nil to remove all formatting and truncation set before.
            textField.attributedText = nil
            textField.text = (queryText != nil) ? queryText : urlAbsolutePath
            textField.selectAll(nil)
        }
        locationViewDelegate?.locationViewDidBeginEditing(textField.text ?? "")
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        hideClearButton()
        if !isURLTextFieldEmpty {
            updateWidthConstraint(&iconContainerStackViewWidthConstraint, for: iconContainerStackView, to: UX.lockIconWidth)
            removeContainerIcons()
            addLockIconImageView()
        }
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let searchText = textField.text?.lowercased(), !searchText.isEmpty else { return false }

        locationViewDelegate?.locationViewShouldSearchFor(searchText)
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Accessibility
    private func configureA11y(_ state: LocationViewState) {
        clearButton.accessibilityIdentifier = state.clearButtonA11yId
        clearButton.accessibilityLabel = state.clearButtonA11yLabel

        searchEngineImageView.accessibilityIdentifier = state.searchEngineImageViewA11yId
        searchEngineImageView.accessibilityLabel = state.searchEngineImageViewA11yLabel

        urlTextField.accessibilityIdentifier = state.urlTextFieldA11yId
        urlTextField.accessibilityLabel = state.urlTextFieldA11yLabel
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Common.Theme) {
        let colors = theme.colors
        urlTextField.textColor = colors.textPrimary
        urlTextFieldSubdomainColor = colors.textSecondary
        gradientLayer.colors = colors.layerGradientURL.cgColors.reversed()
        clearButton.tintColor = colors.iconPrimary
        searchEngineImageView.backgroundColor = colors.iconPrimary
        lockIconImageView.tintColor = colors.iconPrimary
        lockIconImageView.backgroundColor = colors.layerSearch
    }
}
