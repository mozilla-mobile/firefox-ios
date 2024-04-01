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

class LocationView: UIView, UITextFieldDelegate, ThemeApplicable {
    // MARK: - Properties
    private enum UX {
        static let horizontalSpace: CGFloat = 16
        static let gradientViewVerticalPadding: CGFloat = 8
        static let gradientViewWidth: CGFloat = 40
    }

    private var notifyTextChanged: (() -> Void)?
    private var locationViewDelegate: LocationViewDelegate?

    private lazy var gradientLayer = CAGradientLayer()
    private lazy var gradientView: UIView = .build()

    private lazy var urlTextField: UITextField = .build { urlTextField in
        urlTextField.accessibilityIdentifier = "url"
        urlTextField.backgroundColor = .clear
        urlTextField.font = UIFont.preferredFont(forTextStyle: .body)
        urlTextField.adjustsFontForContentSizeCategory = true
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

            urlTextField.text = urlTextField.text?.lowercased()
            locationViewDelegate?.locationViewDidEnterText(urlTextField.text?.lowercased() ?? "")
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

    func configure(_ text: String?, delegate: LocationViewDelegate) {
        urlTextField.text = getHost(from: text)
        locationViewDelegate = delegate
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        updateGradientLayerFrame()
    }

    private func setupLayout() {
        addSubviews(urlTextField, gradientView)

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
                gradientView.widthAnchor.constraint(equalToConstant: UX.gradientViewWidth),
                gradientView.centerYAnchor.constraint(equalTo: urlTextField.centerYAnchor),

                urlTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.horizontalSpace),
                urlTextField.topAnchor.constraint(equalTo: topAnchor),
                urlTextField.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -UX.horizontalSpace),
                urlTextField.bottomAnchor.constraint(equalTo: bottomAnchor),
            ]
        )
    }

    private func setupGradientLayer() {
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientView.layer.addSublayer(gradientLayer)
    }

    private func updateGradientLayerFrame() {
        let locationViewWidth = frame.width - (UX.horizontalSpace * 2)
        let urlTextFieldWidth = urlTextField.frame.width
        let showGradientForLongURL = urlTextFieldWidth >= locationViewWidth && !urlTextField.isFirstResponder
        gradientLayer.frame = if showGradientForLongURL { gradientView.bounds } else { CGRect() }
    }

    // MARK: - `urlTextField` Configuration
    private func applyTruncationStyleToURLTextField() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingHead

        let attributedString = NSMutableAttributedString(string: urlTextField.text ?? "")
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

    private func getHost(from stringURL: String?) -> String {
        guard let stringURL, let url = URL(string: stringURL) else { return "" }
        return url.host ?? ""
    }

    // MARK: - Selectors
    @objc
    func textDidChange(_ textField: UITextField) {
        notifyTextChanged?()
    }

    // MARK: - UITextFieldDelegate
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        gradientLayer.frame = CGRect()
        locationViewDelegate?.locationViewDidBeginEditing(textField.text?.lowercased() ?? "")
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        updateGradientLayerFrame()
        applyTruncationStyleToURLTextField()
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let searchText = textField.text?.lowercased(), !searchText.isEmpty else { return false }

        locationViewDelegate?.locationViewShouldSearchFor(searchText)
        textField.resignFirstResponder()
        return true
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Common.Theme) {
        let colors = theme.colors
        gradientLayer.colors = colors.layerGradientURL.cgColors.reversed()
    }
}
