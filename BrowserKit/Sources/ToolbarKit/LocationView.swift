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
}

public struct LocationViewState {
    public let accessibilityIdentifier: String
    public let accessibilityHint: String
    public let accessibilityLabel: String
    public let url: String?

    public init(
        accessibilityIdentifier: String,
        accessibilityHint: String,
        accessibilityLabel: String,
        url: String?
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.accessibilityHint = accessibilityHint
        self.accessibilityLabel = accessibilityLabel
        self.url = url
    }
}

class LocationView: UIView, UITextFieldDelegate, ThemeApplicable {
    // MARK: - Properties
    private enum UX {
        static let horizontalSpace: CGFloat = 8
        static let gradientViewVerticalPadding: CGFloat = 8
        static let gradientViewWidth: CGFloat = 40
        static let clearButtonSize: CGFloat = 40
        static let transitionDuration: TimeInterval = 0.3
    }

    private var urlAbsolutePath: String?
    private var notifyTextChanged: (() -> Void)?
    private var locationViewDelegate: LocationViewDelegate?

    private lazy var urlTextFieldSubdomainColor: UIColor = .clear
    private lazy var gradientLayer = CAGradientLayer()
    private lazy var gradientView: UIView = .build()

    private var clearButtonWidthConstraint: NSLayoutConstraint?
    private var gradientViewWidthConstraint: NSLayoutConstraint?

    private lazy var clearButton: UIButton = .build { button in
        button.setImage(
            UIImage(named: StandardImageIdentifiers.Large.crossCircleFill)?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        button.addTarget(self, action: #selector(self.clearURLText), for: .touchUpInside)
    }

    private lazy var urlTextField: UITextField = .build { urlTextField in
        urlTextField.accessibilityIdentifier = "url"
        urlTextField.backgroundColor = .clear
        urlTextField.font = UIFont.preferredFont(forTextStyle: .body)
        urlTextField.adjustsFontForContentSizeCategory = true
        let isRightToLeft = Locale.characterDirection(forLanguage: Locale.preferredLanguages.first ?? "") == .rightToLeft
        urlTextField.leftView = isRightToLeft ? self.clearButton : nil
        urlTextField.rightView = isRightToLeft ? nil : self.clearButton
        urlTextField.leftViewMode = isRightToLeft ? .whileEditing : .never
        urlTextField.rightViewMode = isRightToLeft ? .never : .whileEditing
        urlTextField.delegate = self
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
        setupGradientLayer()

        urlTextField.addTarget(self, action: #selector(LocationView.textDidChange), for: .editingChanged)
        notifyTextChanged = { [self] in
            guard urlTextField.isEditing else { return }

            if urlTextField.text?.isEmpty == true {
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
        urlTextField.text = state.url
        configureA11yForClearButton(state)
        urlAbsolutePath = urlTextField.text
        formatAndTruncateURLTextField()
        locationViewDelegate = delegate
    }

    // MARK: - Layout
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        DispatchQueue.main.async { [self] in
            formatAndTruncateURLTextField()
            performURLTextFieldAnimationIfPossible()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateGradientLayerFrame()
        performURLTextFieldAnimationIfPossible()
    }

    private func setupLayout() {
        addSubviews(urlTextField, gradientView, clearButton)

        NSLayoutConstraint.activate(
            [
                gradientView.topAnchor.constraint(
                    equalTo: urlTextField.topAnchor,
                    constant: UX.gradientViewVerticalPadding
                ),
                gradientView.bottomAnchor.constraint(
                    equalTo: urlTextField.bottomAnchor,
                    constant: -UX.gradientViewVerticalPadding
                ),
                gradientView.leadingAnchor.constraint(equalTo: urlTextField.leadingAnchor),
                gradientView.centerYAnchor.constraint(equalTo: urlTextField.centerYAnchor),

                urlTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.horizontalSpace),
                urlTextField.topAnchor.constraint(equalTo: topAnchor),
                urlTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.horizontalSpace),
                urlTextField.bottomAnchor.constraint(equalTo: bottomAnchor),

                clearButton.heightAnchor.constraint(equalToConstant: UX.clearButtonSize)
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
        gradientLayer.frame = if showGradientForLongURL { gradientView.bounds } else { CGRect() }
    }

    private func updateClearButtonWidthConstraint(to widthConstant: CGFloat) {
        clearButtonWidthConstraint?.isActive = false
        clearButtonWidthConstraint = clearButton.widthAnchor.constraint(equalToConstant: widthConstant)
        clearButtonWidthConstraint?.isActive = true
    }

    private func updateGradientViewWidthConstraint(to widthConstant: CGFloat) {
        gradientViewWidthConstraint?.isActive = false
        gradientViewWidthConstraint = gradientView.widthAnchor.constraint(equalToConstant: widthConstant)
        gradientViewWidthConstraint?.isActive = true
    }

    private func showClearButton() {
        clearButton.isHidden = false
        updateClearButtonWidthConstraint(to: UX.clearButtonSize)
        updateGradientViewWidthConstraint(to: 0)
    }

    private func hideClearButton() {
        clearButton.isHidden = true
        updateClearButtonWidthConstraint(to: 0)
        updateGradientViewWidthConstraint(to: UX.gradientViewWidth)
    }

    // MARK: - `urlTextField` Configuration
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

    private func performURLTextFieldAnimationIfPossible() {
        if !doesURLTextFieldExceedViewWidth, !urlTextField.isFirstResponder {
            animateURLText(urlTextField, options: .transitionFlipFromLeft, textAlignment: .center)
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
        if textField.text?.isEmpty == false { showClearButton() } else { hideClearButton() }

        updateGradientLayerFrame()
        DispatchQueue.main.async {
            // `attributedText` property is set to nil to remove all formatting and truncation set before.
            textField.attributedText = nil
            textField.text = self.urlAbsolutePath
            textField.selectAll(nil)
        }

        animateURLText(textField, options: .transitionFlipFromRight, textAlignment: .natural) {
            textField.textAlignment = .natural
        }
        locationViewDelegate?.locationViewDidBeginEditing(textField.text?.lowercased() ?? "")
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        hideClearButton()
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let searchText = textField.text?.lowercased(), !searchText.isEmpty else { return false }

        locationViewDelegate?.locationViewShouldSearchFor(searchText)
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Accessibility
    private func configureA11yForClearButton(_ model: LocationViewState) {
        clearButton.accessibilityIdentifier = model.accessibilityIdentifier
        clearButton.accessibilityHint = model.accessibilityHint
        clearButton.accessibilityLabel = model.accessibilityLabel
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Common.Theme) {
        let colors = theme.colors
        urlTextField.textColor = colors.textPrimary
        urlTextFieldSubdomainColor = colors.textSecondary
        gradientLayer.colors = colors.layerGradientURL.cgColors.reversed()
        clearButton.tintColor = colors.iconPrimary
    }
}
