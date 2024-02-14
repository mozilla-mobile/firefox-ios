// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

protocol FindInPageBarDelegate: AnyObject {
    func findInPage(_ findInPage: FindInPageBar, textChanged text: String)
    func findInPage(_ findInPage: FindInPageBar, findPreviousWithText text: String)
    func findInPage(_ findInPage: FindInPageBar, findNextWithText text: String)
    func findInPageDidPressClose(_ findInPage: FindInPageBar)
}

class FindInPageBar: UIView, UITextFieldDelegate, ThemeApplicable {
    private struct UX {
        static let fontSize: CGFloat = 16
        static let totalResultsMax = 500
    }

    weak var delegate: FindInPageBarDelegate?

    private lazy var topBorder: UIView = .build()

    private lazy var searchText: UITextField = .build { textField in
        textField.addTarget(self, action: #selector(self.didTextChange), for: .editingChanged)
        textField.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .callout, size: UX.fontSize)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.adjustsFontForContentSizeCategory = true
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.inputAssistantItem.leadingBarButtonGroups = []
        textField.inputAssistantItem.trailingBarButtonGroups = []
        textField.enablesReturnKeyAutomatically = true
        textField.returnKeyType = .search
        textField.delegate = self
    }

    private lazy var matchCountView: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .callout, size: UX.fontSize)
        label.isHidden = true
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var previousButton: UIButton = .build { button in
        button.setImage(UIImage(named: StandardImageIdentifiers.Large.chevronUp), for: .normal)
        button.addTarget(self, action: #selector(self.didFindPrevious), for: .touchUpInside)
    }

    private lazy var nextButton: UIButton = .build { button in
        button.setImage(UIImage(named: StandardImageIdentifiers.Large.chevronDown), for: .normal)
        button.addTarget(self, action: #selector(self.didFindNext), for: .touchUpInside)
    }

    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage(named: StandardImageIdentifiers.Medium.cross), for: .normal)
        button.addTarget(self, action: #selector(self.didPressClose), for: .touchUpInside)
    }

    var currentResult = 0 {
        didSet {
            if totalResults > UX.totalResultsMax {
                matchCountView.text = "\(currentResult)/\(UX.totalResultsMax)+"
            } else {
                matchCountView.text = "\(currentResult)/\(totalResults)"
            }
        }
    }

    var totalResults = 0 {
        didSet {
            if totalResults > UX.totalResultsMax {
                matchCountView.text = "\(currentResult)/\(UX.totalResultsMax)+"
            } else {
                matchCountView.text = "\(currentResult)/\(totalResults)"
            }
            previousButton.isEnabled = totalResults > 1
            nextButton.isEnabled = previousButton.isEnabled
        }
    }

    var text: String? {
        get {
            return searchText.text
        }

        set {
            searchText.text = newValue
            didTextChange(searchText)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .white

        addSubviews(searchText, matchCountView, previousButton, nextButton, closeButton, topBorder)

        NSLayoutConstraint.activate([
            searchText.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            searchText.topAnchor.constraint(equalTo: topAnchor),
            searchText.bottomAnchor.constraint(equalTo: bottomAnchor),

            matchCountView.leadingAnchor.constraint(equalTo: searchText.trailingAnchor),
            matchCountView.centerYAnchor.constraint(equalTo: centerYAnchor),

            previousButton.leadingAnchor.constraint(equalTo: matchCountView.trailingAnchor),
            previousButton.widthAnchor.constraint(equalTo: heightAnchor),
            previousButton.heightAnchor.constraint(equalTo: heightAnchor),
            previousButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            nextButton.leadingAnchor.constraint(equalTo: previousButton.trailingAnchor),
            nextButton.widthAnchor.constraint(equalTo: heightAnchor),
            nextButton.heightAnchor.constraint(equalTo: heightAnchor),
            nextButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            closeButton.leadingAnchor.constraint(equalTo: nextButton.trailingAnchor),
            closeButton.widthAnchor.constraint(equalTo: heightAnchor),
            closeButton.heightAnchor.constraint(equalTo: heightAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            topBorder.heightAnchor.constraint(equalToConstant: 1),
            topBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBorder.topAnchor.constraint(equalTo: topAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        searchText.becomeFirstResponder()
        return super.becomeFirstResponder()
    }

    @objc
    private func didFindPrevious(_ sender: UIButton) {
        delegate?.findInPage(self, findPreviousWithText: searchText.text ?? "")
    }

    @objc
    private func didFindNext(_ sender: UIButton) {
        delegate?.findInPage(self, findNextWithText: searchText.text ?? "")
    }

    @objc
    private func didTextChange(_ sender: UITextField) {
        matchCountView.isHidden = searchText.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true
        delegate?.findInPage(self, textChanged: searchText.text ?? "")
    }

    @objc
    private func didPressClose(_ sender: UIButton) {
        delegate?.findInPageDidPressClose(self)
    }

    // MARK: - Theme Applicable

    func applyTheme(theme: Theme) {
        let colors = theme.colors
        topBorder.backgroundColor = colors.borderPrimary
        searchText.textColor = theme.type == .light ? colors.textPrimary : colors.textInverted
        matchCountView.textColor = colors.actionSecondary
        previousButton.setTitleColor(colors.iconPrimary, for: .normal)
        nextButton.setTitleColor(colors.iconPrimary, for: .normal)
        closeButton.setTitleColor(colors.iconPrimary, for: .normal)
    }

    // MARK: - UITextFieldDelegate

    // Keyboard with a .search returnKeyType doesn't dismiss when return pressed. Handle this manually.
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if string == "\n" {
            textField.resignFirstResponder()
            return false
        }
        return true
    }
}
