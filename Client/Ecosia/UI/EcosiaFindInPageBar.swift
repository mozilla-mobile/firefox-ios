// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Shared
import Common

protocol EcosiaFindInPageBarDelegate: AnyObject {
    func findInPage(_ findInPage: EcosiaFindInPageBar, didTextChange text: String)
    func findInPage(_ findInPage: EcosiaFindInPageBar, didFindPreviousWithText text: String)
    func findInPage(_ findInPage: EcosiaFindInPageBar, didFindNextWithText text: String)
    func findInPageDidPressClose(_ findInPage: EcosiaFindInPageBar)
}

/// Ecosia's custom UI for FindInPageBar.
///
/// You can find the Firefox original view in Client/Frontend/Browser/FindInPageBar (removed from Target since no longer used)
final class EcosiaFindInPageBar: UIView, Themeable {
    private struct UX {
        static let barHeight: CGFloat = 60
        static let searchViewTopBottomSpacing: CGFloat = 8
        static let searchViewLeadingOffset = 16
        static let searchTextFieldLeadingOffset = 16
        static let previousButtonLeadingOffset = 14
        static let nextButtonLeadingOffset = 29
        static let closeButtonLeadingTrailingSpacing = 14
        static let topBorderHeight = 1
    }
    
    private lazy var searchView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = (UX.barHeight - 2*UX.searchViewTopBottomSpacing)/2
        return view
    }()
    private lazy var searchTextField: UITextField = {
        let textField = UITextField()
        textField.addTarget(self, action: #selector(didTextChange), for: .editingChanged)
        textField.font = .preferredFont(forTextStyle: .body)
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.inputAssistantItem.leadingBarButtonGroups = []
        textField.inputAssistantItem.trailingBarButtonGroups = []
        textField.enablesReturnKeyAutomatically = true
        textField.returnKeyType = .search
        textField.accessibilityIdentifier = AccessibilityIdentifiers.Ecosia.FindInPage.searchField
        textField.delegate = self
        return textField
    }()
    private lazy var matchCountLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textAlignment = .right
        label.isHidden = true
        label.accessibilityIdentifier = AccessibilityIdentifiers.Ecosia.FindInPage.matchCount
        return label
    }()
    private lazy var previousButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.templateImageNamed("find_previous"), for: .normal)
        button.isEnabled = false
        button.accessibilityLabel = .FindInPagePreviousAccessibilityLabel
        button.addTarget(self, action: #selector(didFindPrevious), for: .touchUpInside)
        button.accessibilityIdentifier = AccessibilityIdentifiers.Ecosia.FindInPage.findPrevious
        return button
    }()
    private lazy var nextButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.templateImageNamed("find_next"), for: .normal)
        button.isEnabled = false
        button.accessibilityLabel = .FindInPageNextAccessibilityLabel
        button.addTarget(self, action: #selector(didFindNext), for: .touchUpInside)
        button.accessibilityIdentifier = AccessibilityIdentifiers.Ecosia.FindInPage.findNext
        return button
    }()
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setTitle(.localized(.done), for: .normal)
        button.accessibilityLabel = .FindInPageDoneAccessibilityLabel
        button.addTarget(self, action: #selector(didPressClose), for: .touchUpInside)
        button.accessibilityIdentifier = AccessibilityIdentifiers.Ecosia.FindInPage.findClose
        return button
    }()
    private lazy var topBorder = UIView()
    
    weak var delegate: EcosiaFindInPageBarDelegate?

    private static let savedTextKey = "findInPageSavedTextKey"
    static var retrieveSavedText: String? {
        return UserDefaults.standard.object(forKey: EcosiaFindInPageBar.savedTextKey) as? String
    }
    var currentResult = 0 {
        didSet {
            if totalResults > 500 {
                matchCountLabel.text = "\(currentResult)/500+"
            } else {
                matchCountLabel.text = "\(currentResult)/\(totalResults)"
            }
        }
    }
    var totalResults = 0 {
        didSet {
            if totalResults > 500 {
                matchCountLabel.text = "\(currentResult)/500+"
            } else {
                matchCountLabel.text = "\(currentResult)/\(totalResults)"
            }
            previousButton.isEnabled = totalResults > 1
            nextButton.isEnabled = previousButton.isEnabled
        }
    }
    var text: String? {
        get {
            return searchTextField.text
        }

        set {
            searchTextField.text = newValue
            didTextChange(searchTextField)
        }
    }
    
    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(searchView)
        searchView.addSubview(searchTextField)
        searchView.addSubview(matchCountLabel)
        addSubview(previousButton)
        addSubview(nextButton)
        addSubview(closeButton)
        addSubview(topBorder)

        applyTheme()
        setupConstraints()
        
        listenForThemeChange(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @discardableResult override func becomeFirstResponder() -> Bool {
        searchTextField.becomeFirstResponder()
        return super.becomeFirstResponder()
    }
    
    @objc func applyTheme() {
        backgroundColor = .legacyTheme.ecosia.secondaryBackground
        searchView.backgroundColor = .legacyTheme.ecosia.tertiaryBackground
        searchTextField.textColor = .legacyTheme.ecosia.primaryText
        searchTextField.attributedPlaceholder = .init(string: .localized(.findInPage),
                                                      attributes: [.foregroundColor: UIColor.legacyTheme.ecosia.secondaryText])
        matchCountLabel.textColor = .legacyTheme.ecosia.secondaryText
        previousButton.tintColor = .legacyTheme.ecosia.primaryIcon
        nextButton.tintColor = .legacyTheme.ecosia.primaryIcon
        closeButton.setTitleColor(.legacyTheme.ecosia.primaryButton, for: .normal)
        topBorder.backgroundColor = .legacyTheme.ecosia.border
    }
    
    private func setupConstraints() {
        self.snp.makeConstraints { make in
            make.height.equalTo(UX.barHeight)
        }
        
        searchView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(UX.searchViewLeadingOffset)
            make.top.equalToSuperview().offset(UX.searchViewTopBottomSpacing)
            make.bottom.equalToSuperview().inset(UX.searchViewTopBottomSpacing)
        }
        
        searchTextField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(UX.searchTextFieldLeadingOffset)
            make.centerY.equalToSuperview()
        }
        searchTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        searchTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        matchCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(searchTextField.snp.trailing)
            make.trailing.equalToSuperview().inset(13)
            make.centerY.equalToSuperview()
        }
        matchCountLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        matchCountLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        previousButton.snp.makeConstraints { make in
            make.leading.equalTo(searchView.snp.trailing).offset(UX.previousButtonLeadingOffset)
            make.centerY.equalToSuperview()
        }

        nextButton.snp.makeConstraints { make in
            make.leading.equalTo(previousButton.snp.trailing).offset(UX.nextButtonLeadingOffset)
            make.centerY.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.leading.equalTo(nextButton.snp.trailing).offset(UX.closeButtonLeadingTrailingSpacing)
            make.trailing.equalToSuperview().inset(UX.closeButtonLeadingTrailingSpacing)
            make.trailing.centerY.equalToSuperview()
        }

        topBorder.snp.makeConstraints { make in
            make.height.equalTo(UX.topBorderHeight)
            make.left.right.top.equalToSuperview()
        }
    }

    @objc private func didFindPrevious(_ sender: UIButton) {
        delegate?.findInPage(self, didFindPreviousWithText: searchTextField.text ?? "")
    }

    @objc private func didFindNext(_ sender: UIButton) {
        delegate?.findInPage(self, didFindNextWithText: searchTextField.text ?? "")
    }

    @objc private func didTextChange(_ sender: UITextField) {
        matchCountLabel.isHidden = searchTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true
        saveSearchText(searchTextField.text)
        delegate?.findInPage(self, didTextChange: searchTextField.text ?? "")
    }

    @objc private func didPressClose(_ sender: UIButton) {
        delegate?.findInPageDidPressClose(self)
    }

    private func saveSearchText(_ searchText: String?) {
        guard let text = searchText, !text.isEmpty else { return }
        UserDefaults.standard.set(text, forKey: EcosiaFindInPageBar.savedTextKey)
    }
}

extension EcosiaFindInPageBar: UITextFieldDelegate {
    // Keyboard with a .search returnKeyType doesn't dismiss when return pressed. Handle this manually.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            textField.resignFirstResponder()
            return false
        }
        return true
    }
}
