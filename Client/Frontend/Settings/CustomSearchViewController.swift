/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import SnapKit
import Storage
import WebImage
import Deferred

private let log = Logger.browserLogger

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

    fileprivate var urlString: String?
    fileprivate var engineTitle = ""
    fileprivate lazy var spinnerView: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        spinner.hidesWhenStopped = true
        return spinner
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingsAddCustomEngineTitle
        view.addSubview(spinnerView)
        spinnerView.snp.makeConstraints { make in
            make.center.equalTo(self.view.snp.center)
        }
    }

    fileprivate func addSearchEngine(_ searchQuery: String, title: String) {
        spinnerView.startAnimating()
        
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        createEngine(forQuery: trimmedQuery, andName: trimmedTitle).uponQueue(DispatchQueue.main) { result in
            self.spinnerView.stopAnimating()
            guard let engine = result.successValue else {
                let alert: UIAlertController
                let error = result.failureValue as? CustomSearchError
                
                alert = (error?.reason == .DuplicateEngine) ?
                    ThirdPartySearchAlerts.duplicateCustomEngine() : ThirdPartySearchAlerts.incorrectCustomEngineForm()
                
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                self.present(alert, animated: true, completion: nil)
                return
            }
            self.profile.searchEngines.addSearchEngine(engine)
            let _ = self.navigationController?.popViewController(animated: true)
            SimpleToast().showAlertWithText(Strings.ThirdPartySearchEngineAdded)
        }
    }

    func createEngine(forQuery query: String, andName name: String) -> Deferred<Maybe<OpenSearchEngine>> {
        let deferred = Deferred<Maybe<OpenSearchEngine>>()
        guard let template = getSearchTemplate(withString: query),
            let url = URL(string: template.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!), url.isWebPage() else {
                deferred.fill(Maybe(failure: CustomSearchError(.FormInput)))
                return deferred
        }
        
        // ensure we haven't already stored this template
        guard engineExists(name: name, template: template) == false else {
            deferred.fill(Maybe(failure: CustomSearchError(.DuplicateEngine)))
            return deferred
        }
        
        FaviconFetcher.fetchFavImageForURL(forURL: url, profile: profile).uponQueue(DispatchQueue.main) { result in
            let image = result.successValue ?? FaviconFetcher.getDefaultFavicon(url)
            let engine = OpenSearchEngine(engineID: nil, shortName: name, image: image, searchTemplate: template, suggestTemplate: nil, isCustomEngine: true)

            //Make sure a valid scheme is used
            let url = engine.searchURLForQuery("test")
            let maybe = (url == nil) ? Maybe(failure: CustomSearchError(.FormInput)) : Maybe(success: engine)
            deferred.fill(maybe)
        }
        return deferred
    }
    
    private func engineExists(name: String, template: String) -> Bool {
        return profile.searchEngines.orderedEngines.contains { (engine) -> Bool in
            return engine.shortName == name || engine.searchTemplate == template
        }
    }

    func getSearchTemplate(withString query: String) -> String? {
        let SearchTermComponent = "%s"      //Placeholder in User Entered String
        let placeholder = "{searchTerms}"   //Placeholder looked for when using Custom Search Engine in OpenSearch.swift

        if query.contains(SearchTermComponent) {
            return query.replacingOccurrences(of: SearchTermComponent, with: placeholder)
        }
        return nil
    }

    override func generateSettings() -> [SettingSection] {

        func URLFromString(_ string: String?) -> URL? {
            guard let string = string else {
                return nil
            }
            return URL(string: string)
        }

        let titleField = CustomSearchEngineTextView(placeholder: Strings.SettingsAddCustomEngineTitlePlaceholder, labelText: Strings.SettingsAddCustomEngineTitleLabel, settingIsValid: { text in
            return text != nil && text != ""
        }, settingDidChange: {fieldText in
            guard let title = fieldText else {
                return
            }
            self.engineTitle = title
        })
        titleField.textField.accessibilityIdentifier = "customEngineTitle"

        let urlField = CustomSearchEngineTextView(placeholder: Strings.SettingsAddCustomEngineURLPlaceholder, labelText: Strings.SettingsAddCustomEngineURLLabel, height: 133, settingIsValid: { text in
            //Can check url text text validity here.
            return true
        }, settingDidChange: {fieldText in
            self.urlString = fieldText
        })

        urlField.textField.autocapitalizationType = .none
        urlField.textField.accessibilityIdentifier = "customEngineUrl"

        let basicSettings: [Setting] = [titleField, urlField]

        let settings: [SettingSection] = [
            SettingSection(footerTitle: NSAttributedString(string: "http://youtube.com/search?q=%s"), children: basicSettings)
        ]

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.addCustomSearchEngine(_:)))
        self.navigationItem.rightBarButtonItem?.accessibilityIdentifier = "customEngineSaveButton"

        return settings
    }

    func addCustomSearchEngine(_ nav: UINavigationController?) {
        self.view.endEditing(true)
        navigationItem.rightBarButtonItem?.isEnabled = false
        if let url = self.urlString {
            self.addSearchEngine(url, title: self.engineTitle)
        }
    }
}

class CustomSearchEngineTextView: Setting, UITextViewDelegate {

    fileprivate let Padding: CGFloat = 8
    fileprivate let TextFieldOffset: CGFloat = 80
    fileprivate let TextLabelHeight: CGFloat = 44
    fileprivate var TextFieldHeight: CGFloat = 44

    fileprivate let defaultValue: String?
    fileprivate let placeholder: String
    fileprivate let labelText: String
    fileprivate let settingDidChange: ((String?) -> Void)?
    fileprivate let settingIsValid: ((String?) -> Bool)?

    let textField = UITextView()
    let placeholderLabel = UILabel()

    init(defaultValue: String? = nil, placeholder: String, labelText: String, height: CGFloat = 44, settingIsValid isValueValid: ((String?) -> Bool)? = nil, settingDidChange: ((String?) -> Void)? = nil) {
        self.defaultValue = defaultValue
        self.TextFieldHeight = height
        self.settingDidChange = settingDidChange
        self.settingIsValid = isValueValid
        self.placeholder = placeholder
        self.labelText = labelText
        textField.addSubview(placeholderLabel)
        super.init(cellHeight: TextFieldHeight)
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        if let id = accessibilityIdentifier {
            textField.accessibilityIdentifier = id + "TextField"
        }

        placeholderLabel.textColor = UIColor(red: 0.0, green: 0.0, blue: 0.0980392, alpha: 0.22)
        placeholderLabel.text = placeholder
        placeholderLabel.frame = CGRect(x: 0, y: 0, width: textField.frame.width, height: TextLabelHeight)
        textField.font = placeholderLabel.font

        textField.textContainer.lineFragmentPadding = 0
        textField.keyboardType = .URL
        textField.autocorrectionType = .no
        textField.delegate = self
        cell.isUserInteractionEnabled = true
        cell.accessibilityTraits = UIAccessibilityTraitNone
        cell.contentView.addSubview(textField)
        cell.textLabel?.text = labelText
        cell.selectionStyle = .none

        textField.snp.makeConstraints { make in
            make.height.equalTo(TextFieldHeight)
            make.trailing.equalTo(cell.contentView).offset(-Padding)
            make.leading.equalTo(cell.contentView).offset(TextFieldOffset)
        }
        cell.textLabel?.snp.remakeConstraints { make in
            make.trailing.equalTo(textField.snp.leading).offset(-Padding)
            make.leading.equalTo(cell.contentView).offset(Padding)
            make.height.equalTo(TextLabelHeight)
        }
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
        placeholderLabel.isHidden = textField.text != ""
    }

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = textField.text != ""
        settingDidChange?(textView.text)
        let color = isValid(textField.text) ? UIConstants.TableViewRowTextColor : UIConstants.DestructiveRed
        textField.textColor = color
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = textField.text != ""
        settingDidChange?(textView.text)
    }
}
