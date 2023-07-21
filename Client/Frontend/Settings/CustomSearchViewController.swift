// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import SnapKit
import Storage
import SiteImageView

class CustomSearchError: MaybeErrorType {
    enum Reason {
        case DuplicateEngine, FormInput
    }

    var reason: Reason!

    internal var description: String {
        return "Search Engine Not Added"
    }

    init(_ reason: Reason) {
        self.reason = reason
    }
}

class CustomSearchViewController: SettingsTableViewController {
    private let faviconFetcher: SiteImageHandler
    private var urlString: String?
    private var engineTitle = ""
    var successCallback: (() -> Void)?
    private lazy var spinnerView: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = themeManager.currentTheme.colors.iconSpinner
        spinner.hidesWhenStopped = true
        return spinner
    }()

    init(faviconFetcher: SiteImageHandler = DefaultSiteImageHandler.factory()) {
        self.faviconFetcher = faviconFetcher
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = .SettingsAddCustomEngineTitle
        view.addSubview(spinnerView)
        spinnerView.snp.makeConstraints { make in
            make.center.equalTo(self.view.snp.center)
        }
    }

    private func addSearchEngine(_ searchQuery: String, title: String) {
        spinnerView.startAnimating()

        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                let engine = try await createEngine(query: trimmedQuery, name: trimmedTitle)
                self.spinnerView.stopAnimating()
                self.profile.searchEngines.addSearchEngine(engine)

                CATransaction.begin() // Use transaction to call callback after animation has been completed
                CATransaction.setCompletionBlock(self.successCallback)
                _ = self.navigationController?.popViewController(animated: true)
                CATransaction.commit()
            } catch {
                self.spinnerView.stopAnimating()
                let alert: UIAlertController
                let error = error as? CustomSearchError

                alert = (error?.reason == .DuplicateEngine) ?
                    ThirdPartySearchAlerts.duplicateCustomEngine() : ThirdPartySearchAlerts.incorrectCustomEngineForm()

                self.navigationItem.rightBarButtonItem?.isEnabled = true
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    func createEngine(query: String, name: String) async throws -> OpenSearchEngine {
        guard let template = getSearchTemplate(withString: query),
              let encodedTemplate = template.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
              let url = URL(string: encodedTemplate),
              url.isWebPage()
        else {
            throw CustomSearchError(.FormInput)
        }

        // ensure we haven't already stored this template
        guard engineExists(name: name, template: template) == false else {
            throw CustomSearchError(.DuplicateEngine)
        }

        let siteImageModel = SiteImageModel(id: UUID(),
                                            expectedImageType: .favicon,
                                            siteURLString: url.absoluteString)
        let result = await faviconFetcher.getImage(site: siteImageModel)

        let engine = OpenSearchEngine(engineID: nil,
                                      shortName: name,
                                      image: result.faviconImage ?? UIImage(),
                                      searchTemplate: template,
                                      suggestTemplate: nil,
                                      isCustomEngine: true)

        // Make sure a valid scheme is used
        guard engine.searchURLForQuery("test") != nil else {
            throw CustomSearchError(.FormInput)
        }

        return engine
    }

    private func engineExists(name: String, template: String) -> Bool {
        return profile.searchEngines.orderedEngines.contains { (engine) -> Bool in
            return engine.shortName == name || engine.searchTemplate == template
        }
    }

    func getSearchTemplate(withString query: String) -> String? {
        let SearchTermComponent = "%s"      // Placeholder in User Entered String
        let placeholder = "{searchTerms}"   // Placeholder looked for when using Custom Search Engine in OpenSearch.swift

        if query.contains(SearchTermComponent) {
            return query.replacingOccurrences(of: SearchTermComponent, with: placeholder)
        }
        return nil
    }

    func updateSaveButton() {
        let isEnabled = !self.engineTitle.isEmptyOrWhitespace() && !(self.urlString?.isEmptyOrWhitespace() ?? true)
        self.navigationItem.rightBarButtonItem?.isEnabled = isEnabled
    }

    override func generateSettings() -> [SettingSection] {
        func URLFromString(_ string: String?) -> URL? {
            guard let string = string else { return nil }
            return URL(string: string)
        }

        let titleField = CustomSearchEngineTextView(
            placeholder: .SettingsAddCustomEngineTitlePlaceholder,
            settingIsValid: { text in
                if let text = text { return !text.isEmpty }

                return false
            }, settingDidChange: {fieldText in
                guard let title = fieldText else { return }
                self.engineTitle = title
                self.updateSaveButton()
            })
        titleField.textField.text = engineTitle
        titleField.textField.accessibilityIdentifier = "customEngineTitle"

        let urlField = CustomSearchEngineTextView(
            placeholder: .SettingsAddCustomEngineURLPlaceholder,
            height: 133,
            keyboardType: .URL,
            settingIsValid: { text in
                // Can check url text text validity here.
                return true
            }, settingDidChange: {fieldText in
                self.urlString = fieldText
                self.updateSaveButton()
            })

        urlField.textField.autocapitalizationType = .none
        urlField.textField.text = urlString
        urlField.textField.accessibilityIdentifier = "customEngineUrl"

        let settings: [SettingSection] = [
            SettingSection(title: NSAttributedString(string: .SettingsAddCustomEngineTitleLabel), children: [titleField]),
            SettingSection(title: NSAttributedString(string: .SettingsAddCustomEngineURLLabel), footerTitle: NSAttributedString(string: "https://youtube.com/search?q=%s"), children: [urlField])
        ]

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.addCustomSearchEngine))
        self.navigationItem.rightBarButtonItem?.accessibilityIdentifier = "customEngineSaveButton"

        self.navigationItem.rightBarButtonItem?.isEnabled = false
        return settings
    }

    @objc
    func addCustomSearchEngine(_ nav: UINavigationController?) {
        self.view.endEditing(true)
        if let url = self.urlString {
            navigationItem.rightBarButtonItem?.isEnabled = false
            self.addSearchEngine(url, title: self.engineTitle)
        }
    }
}

class CustomSearchEngineTextView: Setting, UITextViewDelegate {
    fileprivate let Padding: CGFloat = 8
    fileprivate let TextLabelHeight: CGFloat = 36
    fileprivate var TextLabelWidth: CGFloat {
        let width = textField.frame.width == 0 ? 360 : textField.frame.width
        return width
    }
    fileprivate var TextFieldHeight: CGFloat = 44

    fileprivate let defaultValue: String?
    fileprivate let placeholder: String
    fileprivate let settingDidChange: ((String?) -> Void)?
    fileprivate let settingIsValid: ((String?) -> Bool)?

    let textField = UITextView()
    let placeholderLabel = UILabel()
    var keyboardType: UIKeyboardType = .default

    init(
        defaultValue: String? = nil,
        placeholder: String,
        height: CGFloat = 44,
        keyboardType: UIKeyboardType = .default,
        settingIsValid isValueValid: ((String?) -> Bool)? = nil,
        settingDidChange: ((String?) -> Void)? = nil
    ) {
        self.defaultValue = defaultValue
        self.TextFieldHeight = height
        self.settingDidChange = settingDidChange
        self.settingIsValid = isValueValid
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        textField.addSubview(placeholderLabel)
        super.init(cellHeight: TextFieldHeight)
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        if let id = accessibilityIdentifier {
            textField.accessibilityIdentifier = id + "TextField"
        }

        placeholderLabel.adjustsFontSizeToFitWidth = true
        placeholderLabel.textColor = theme.colors.textSecondary
        placeholderLabel.text = placeholder
        placeholderLabel.isHidden = !textField.text.isEmpty
        textField.font = placeholderLabel.font

        textField.textContainer.lineFragmentPadding = 0
        textField.keyboardType = keyboardType
        if keyboardType == .default {
            textField.autocapitalizationType = .words
        }
        textField.autocorrectionType = .no
        textField.delegate = self
        textField.backgroundColor = theme.colors.layer5
        textField.textColor = theme.colors.textPrimary
        cell.isUserInteractionEnabled = true
        cell.accessibilityTraits = UIAccessibilityTraits.none
        cell.contentView.addSubview(textField)
        cell.selectionStyle = .none

        textField.snp.makeConstraints { make in
            make.height.equalTo(TextFieldHeight)
            make.top.bottom.equalTo(0).inset(Padding / 2)
            make.left.right.equalTo(cell.contentView).inset(Padding)
        }
        textField.layoutIfNeeded()
        placeholderLabel.frame = CGRect(width: TextLabelWidth, height: TextLabelHeight)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        textField.becomeFirstResponder()
    }

    fileprivate func isValid(_ value: String?) -> Bool {
        guard let test = settingIsValid else {
            return true
        }
        return test(prepareValidValue(userInput: value))
    }

    func prepareValidValue(userInput value: String?) -> String? {
        return value
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = !textField.text.isEmpty
    }

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textField.text.isEmpty
        settingDidChange?(textView.text)
        let color = isValid(textField.text) ? theme.colors.textPrimary : theme.colors.textWarning
        textField.textColor = color
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = !textField.text.isEmpty
        settingDidChange?(textView.text)
    }
}
