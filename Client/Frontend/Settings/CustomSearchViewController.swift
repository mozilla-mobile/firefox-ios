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

class CustomSearchViewController: SettingsTableViewController {
    
    private var urlString: String?
    private var engineTitle = ""
    private var spinnerView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingsAddCustomEngineTitle
        initSpinnerView()
    }

    func initSpinnerView(){
        view.addSubview(spinnerView)
        spinnerView.snp_makeConstraints { make in
            make.center.equalTo(view)
        }
        spinnerView.hidesWhenStopped = true
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
                deferred.fill(Maybe(failure: FaviconError()))
                return deferred
        }
        FaviconFetcher.fetchFavImageForURL(forURL: url, profile: profile).uponQueue(dispatch_get_main_queue()) { result in
            let image = result.successValue ?? FaviconFetcher.getDefaultFavicon(url)
            let engine = OpenSearchEngine(engineID: nil, shortName: name, image: image, searchTemplate: template, suggestTemplate: nil, isCustomEngine: true)

            //Make sure a valid scheme is used
            let url = engine.searchURLForQuery("test")
            let maybe = (url == nil) ? Maybe(failure: FaviconError()) : Maybe(success: engine)
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
        
        let titleField = CustomSearchEngineField(placeholder: "Title", settingDidChange: {fieldText in
            guard let title = fieldText else {
                return
            }
            self.engineTitle = title
            }, settingIsValid: { text in
                return text != nil && text != ""
        })
        titleField.textField.accessibilityIdentifier = "customEngineTitle"
        
        let urlField = CustomSearchEngineField(placeholder: Strings.SettingsAddCustomEngineURLPlaceholder, settingDidChange: {fieldText in
            self.urlString = fieldText
            }, settingIsValid: { text in
                //Can check url text text validity here.
                return true
        })
        urlField.textField.autocapitalizationType = .None
        urlField.textField.accessibilityIdentifier = "customEngineUrl"
        
        let basicSettings: [Setting] = [ titleField, urlField]
        
        let settings: [SettingSection] = [
            SettingSection(title: NSAttributedString(string: Strings.SettingsAddCustomEngineSectionTitle), children: basicSettings),
            SettingSection(children: [
                ButtonSetting(title: NSAttributedString(string: Strings.SettingsAddCustomEngineSaveButtonText), accessibilityIdentifier: "saveCustomEngine", onClick: addCustomSearchEngine)
                ])
        ]
        
        return settings
    }
    
    func addCustomSearchEngine(nav: UINavigationController?) {
            self.view.endEditing(true)
            if let url = self.urlString {
                self.addSearchEngine(url, title: self.engineTitle)
        }
    }
    
}


class CustomSearchEngineField: Setting, UITextFieldDelegate {
    
    private let Padding: CGFloat = 8
    private let TextFieldHeight: CGFloat = 44

    private let defaultValue: String?
    private let placeholder: String
    private let settingDidChange: (String? -> Void)?
    private let settingIsValid: (String? -> Bool)?
    
    let textField = UITextField()
    
    init(defaultValue: String? = nil, placeholder: String, settingIsValid isValueValid: (String? -> Bool)? = nil, settingDidChange: (String? -> Void)? = nil) {
        self.defaultValue = defaultValue
        self.settingDidChange = settingDidChange
        self.settingIsValid = isValueValid
        self.placeholder = placeholder
        super.init()
    }
    
    override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)
        if let id = accessibilityIdentifier {
            textField.accessibilityIdentifier = id + "TextField"
        }
        textField.placeholder = placeholder
        textField.textAlignment = .Left
        textField.keyboardType = .URL
        textField.autocorrectionType = .No
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), forControlEvents: .EditingChanged)
        cell.userInteractionEnabled = true
        cell.accessibilityTraits = UIAccessibilityTraitNone
        cell.contentView.addSubview(textField)
        
        textField.snp_makeConstraints { make in
            make.height.equalTo(TextFieldHeight)
            make.trailing.equalTo(cell.contentView).offset(-Padding)
            make.leading.equalTo(cell.contentView).offset(Padding)
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
    
    /// This gives subclasses an opportunity to treat the user input string
    /// before it is saved or tested.
    /// Default implementation does nothing.
    func prepareValidValue(userInput value: String?) -> String? {
        return value
    }
    
    @objc func textFieldDidChange(textField: UITextField) {
        settingDidChange?(textField.text)
        let color = isValid(textField.text) ? UIConstants.TableViewRowTextColor : UIConstants.DestructiveRed
        textField.textColor = color
    }
    
    @objc func textFieldShouldReturn(textField: UITextField) -> Bool {
        return isValid(textField.text)
    }
    
    @objc func textFieldDidEndEditing(textField: UITextField) {
        settingDidChange?(textField.text)
    }
}
