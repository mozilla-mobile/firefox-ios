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
    internal var description: String {
        return "Search Engine Not Added"
    }
}

class CustomSearchViewController: SettingsTableViewController {
    
    private var urlString: String?
    private var engineTitle = ""
    private lazy var spinnerView: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingsAddCustomEngineTitle
        view.addSubview(spinnerView)
        spinnerView.snp_makeConstraints { make in
            make.center.equalTo(self.view.snp_center)
        }
    }

    private func addSearchEngine(searchQuery: String, title: String) {
        spinnerView.startAnimating()
        createEngine(forQuery: searchQuery, andName: title).uponQueue(dispatch_get_main_queue()) { result in
            self.spinnerView.stopAnimating()
            guard let engine = result.successValue else {
                let alert = ThirdPartySearchAlerts.incorrectCustomEngineForm()
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            self.profile.searchEngines.addSearchEngine(engine)
            self.navigationController?.popViewControllerAnimated(true)
            SimpleToast().showAlertWithText(Strings.ThirdPartySearchEngineAdded)
        }
    }


    func createEngine(forQuery query: String, andName name: String) -> Deferred<Maybe<OpenSearchEngine>> {
        let deferred = Deferred<Maybe<OpenSearchEngine>>()
        guard let template = getSearchTemplate(withString: query),
            let url = NSURL(string: template.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLFragmentAllowedCharacterSet())!) where url.isWebPage() else {
                deferred.fill(Maybe(failure: CustomSearchError()))
                return deferred
        }
        FaviconFetcher.fetchFavImageForURL(forURL: url, profile: profile).uponQueue(dispatch_get_main_queue()) { result in
            let image = result.successValue ?? FaviconFetcher.getDefaultFavicon(url)
            let engine = OpenSearchEngine(engineID: nil, shortName: name, image: image, searchTemplate: template, suggestTemplate: nil, isCustomEngine: true)

            //Make sure a valid scheme is used
            let url = engine.searchURLForQuery("test")
            let maybe = (url == nil) ? Maybe(failure: CustomSearchError()) : Maybe(success: engine)
            deferred.fill(maybe)
        }
        return deferred
    }

    func getSearchTemplate(withString query: String) -> String? {
        let SearchTermComponent = "%s"      //Placeholder in User Entered String
        let placeholder = "{searchTerms}"   //Placeholder looked for when using Custom Search Engine in OpenSearch.swift

        if query.contains(SearchTermComponent) {
            return query.stringByReplacingOccurrencesOfString(SearchTermComponent, withString: placeholder)
        }
        return nil
    }

    override func generateSettings() -> [SettingSection] {

        func URLFromString(string: String?) -> NSURL? {
            guard let string = string else {
                return nil
            }
            return NSURL(string: string)
        }
        
        let titleField = CustomSearchEngineTextView(placeholder: Strings.SettingsAddCustomEngineTitlePlaceholder, labelText: Strings.SettingsAddCustomEngineTitleLabel, settingDidChange: {fieldText in
            guard let title = fieldText else {
                return
            }
            self.engineTitle = title
            }, settingIsValid: { text in
                return text != nil && text != ""
        })
        titleField.textField.accessibilityIdentifier = "customEngineTitle"

        let urlField = CustomSearchEngineTextView(placeholder: Strings.SettingsAddCustomEngineURLPlaceholder, labelText: Strings.SettingsAddCustomEngineURLLabel, height: 133, settingDidChange: {fieldText in
            self.urlString = fieldText
            }, settingIsValid: { text in
                //Can check url text text validity here.
                return true
        })
        
        urlField.textField.autocapitalizationType = .None
        urlField.textField.accessibilityIdentifier = "customEngineUrl"
        
        let basicSettings: [Setting] = [titleField, urlField]
        
        let settings: [SettingSection] = [
            SettingSection(footerTitle: NSAttributedString(string: Strings.SettingsAddCustomEngineFooter), children: basicSettings)
        ]
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: #selector(self.addCustomSearchEngine(_:)))
        
        return settings
    }
    
    func addCustomSearchEngine(nav: UINavigationController?) {
        self.view.endEditing(true)
        if let url = self.urlString {
            self.addSearchEngine(url, title: self.engineTitle)
        }
    }
}

class CustomSearchEngineTextView: Setting, UITextViewDelegate {
    
    private let Padding: CGFloat = 8
    private let TextFieldOffset: CGFloat = 80
    private let TextLabelHeight: CGFloat = 44
    private var TextFieldHeight: CGFloat = 44
    
    private let defaultValue: String?
    private let placeholder: String
    private let labelText: String
    private let settingDidChange: (String? -> Void)?
    private let settingIsValid: (String? -> Bool)?
    
    let textField = UITextView()
    let placeholderLabel = UILabel()
    
    init(defaultValue: String? = nil, placeholder: String, labelText: String, height: CGFloat = 44, settingIsValid isValueValid: (String? -> Bool)? = nil, settingDidChange: (String? -> Void)? = nil) {
        self.defaultValue = defaultValue
        self.TextFieldHeight = height
        self.settingDidChange = settingDidChange
        self.settingIsValid = isValueValid
        self.placeholder = placeholder
        self.labelText = labelText
        textField.addSubview(placeholderLabel)
        super.init(cellHeight: TextFieldHeight)
    }
    
    override func onConfigureCell(cell: UITableViewCell) {
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
        textField.autocorrectionType = .No
        textField.delegate = self
        cell.userInteractionEnabled = true
        cell.accessibilityTraits = UIAccessibilityTraitNone
        cell.contentView.addSubview(textField)
        cell.textLabel?.text = labelText
        cell.selectionStyle = .None
        
        textField.snp_makeConstraints { make in
            make.height.equalTo(TextFieldHeight)
            make.trailing.equalTo(cell.contentView).offset(-Padding)
            make.leading.equalTo(cell.contentView).offset(TextFieldOffset)
        }
        cell.textLabel?.snp_remakeConstraints { make in
            make.trailing.equalTo(textField.snp_leading).offset(-Padding)
            make.leading.equalTo(cell.contentView).offset(Padding)
            make.height.equalTo(TextLabelHeight)
        }
    }
    
    override func onClick(navigationController: UINavigationController?) {
        textField.becomeFirstResponder()
    }
    
    private func isValid(value: String?) -> Bool {
        guard let test = settingIsValid else {
            return true
        }
        return test(prepareValidValue(userInput: value))
    }

    func prepareValidValue(userInput value: String?) -> String? {
        return value
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        placeholderLabel.hidden = textField.text != ""
    }
    
    func textViewDidChange(textView: UITextView) {
        placeholderLabel.hidden = textField.text != ""
        settingDidChange?(textView.text)
        let color = isValid(textField.text) ? UIConstants.TableViewRowTextColor : UIConstants.DestructiveRed
        textField.textColor = color
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        placeholderLabel.hidden = textField.text != ""
        settingDidChange?(textView.text)
    }
}
