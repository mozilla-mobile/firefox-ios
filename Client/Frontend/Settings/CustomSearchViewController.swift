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
    private var engineTitle: String?
    
    private var spinnerView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Custom Search Engine"
        initSpinnerView()
    }

    func initSpinnerView(){
        spinnerView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        self.view.addSubview (spinnerView)
        
        spinnerView.snp_makeConstraints { make in
            make.center.equalTo(view)
            return
        }
        spinnerView.hidesWhenStopped = true
    }
    
    func addSearchEngine(searchQuery: String) {
        
        let processedSearchQuery = getProcessedSearchQuery(withSearchQuery: searchQuery)
        guard processedSearchQuery != nil,
            let url = NSURL(string: processedSearchQuery!.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLFragmentAllowedCharacterSet())!),
            let shortName = self.engineTitle where
            self.engineTitle != ""
            else {
                spinnerView.stopAnimating()
                let alert = ThirdPartySearchAlerts.incorrectCustomEngineForm()
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
        saveEngineWithFavicon(forProcessedQuery: processedSearchQuery!, withEncodedUrl: url ,withShortname: shortName, forProfile: profile)
    }

    func getProcessedSearchQuery(withSearchQuery searchQuery: String) -> String? {
        let SearchTermComponent = "%s"      //Placeholder in User Entered String
        let placeholder = "{searchTerms}"   //Placeholder looked for when using Custom Search Engine in OpenSearch.swift
        
        if searchQuery.componentsSeparatedByString(SearchTermComponent).count - 1 == 1{
            return searchQuery.stringByReplacingOccurrencesOfString(SearchTermComponent, withString: placeholder)
        } else {
            return nil
        }

    }
    
    func saveEngineWithFavicon(forProcessedQuery processedSearchQuery: String, withEncodedUrl url: NSURL, withShortname shortName: String ,forProfile profile: Profile) {
        
        spinnerView.startAnimating()
        FaviconFetcher.getForURL(url, profile: profile).uponQueue(dispatch_get_main_queue()) { result in
            var iconImage: UIImage?
            var iconURL: NSURL?
            if let favicons = result.successValue where favicons.count > 0,
                let faviconImageURL = favicons.first?.url.asURL {
                iconURL = faviconImageURL
            } else {
                iconImage = FaviconFetcher.getDefaultFavicon(url)
            }
            
            SDWebImageManager.sharedManager().downloadImageWithURL(iconURL, options: SDWebImageOptions.ContinueInBackground, progress: nil) { (image, error, cacheType, success, url) in
                self.spinnerView.stopAnimating()
                if image != nil {
                    iconImage = image
                }
                guard iconImage != nil else {
                    let alert = ThirdPartySearchAlerts.failedToAddThirdPartySearch()
                    self.presentViewController(alert, animated: true, completion: nil)
                    return
                }
                self.profile.searchEngines.addSearchEngine(OpenSearchEngine(engineID: nil, shortName: shortName, image: iconImage!, searchTemplate: processedSearchQuery, suggestTemplate: nil, isCustomEngine: true))
                self.navigationController?.popViewControllerAnimated(true)
                let Toast = SimpleToast()
                Toast.showAlertWithText(Strings.ThirdPartySearchEngineAdded)
            }
        }
    
    }
    
    override func generateSettings() -> [SettingSection] {
        
        func URLFromString(string: String?) -> NSURL? {
            guard let string = string else {
                return nil
            }
            return NSURL(string: string)
        }
        
        let titleField = CustomSearchEngineField(placeholder: "Title", settingDidChange: {fieldText in
            self.engineTitle = fieldText
            print(self.engineTitle)
            }, settingIsValid: { text in
                if text != nil && text != "" {
                    return true
                } else {
                    return false
                }
        })
        titleField.textField.accessibilityIdentifier = "customEngineTitle"
        
        let urlField = CustomSearchEngineField(placeholder: "URL (Replace Query with %s)", settingDidChange: {fieldText in
            self.urlString = fieldText
            }, settingIsValid: { text in
                //Can check url text text validity here.
                return true
        })
        urlField.textField.accessibilityIdentifier = "customEngineUrl"
        
        let basicSettings: [Setting] = [ titleField, urlField]
        
        let settings: [SettingSection] = [
            SettingSection(title: NSAttributedString(string: "Custom Engine URL"), children: basicSettings),
            SettingSection(children: [
            ButtonSetting(title: NSAttributedString(string: "Save"), accessibilityIdentifier: "saveCustomEngine", onClick: addCustomSearchEngine())
                ])
        ]
        
        return settings
    }
    
    func addCustomSearchEngine() -> (UINavigationController? -> ()) {
        return { nav in
            self.view.endEditing(true)
            self.spinnerView.startAnimating()
            if let url = self.urlString {
                self.addSearchEngine(url)
            }
        }
    }
    
}


class CustomSearchEngineField: Setting, UITextFieldDelegate {
    
    private let Padding: CGFloat = 8

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
            make.height.equalTo(44)
            make.trailing.equalTo(cell.contentView).offset(-Padding)
            make.leading.equalTo(cell.contentView).offset(Padding)
        }
//        textField.text = prefs.stringForKey(prefKey) ?? defaultValue
        textFieldDidChange(textField)
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
