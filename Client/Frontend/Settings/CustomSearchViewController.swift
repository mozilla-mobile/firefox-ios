/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import SnapKit
import Storage
import WebImage

private let log = Logger.browserLogger

class CustomSearchViewController: SettingsTableViewController {
    
    private var urlString: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Custom Search Engine"
    }
    
    func faviconFor(url: NSURL) -> Favicon? {
        var resultFavicon: Favicon?
        FaviconFetcher.getForURL(url, profile: profile).uponQueue(dispatch_get_main_queue()) { result in
            guard let favicons = result.successValue where favicons.count > 0,
                let _ = favicons.first?.url.asURL else {
                    return
            }
            resultFavicon = favicons.first!
        }
        return resultFavicon
    }
    
    func addSearchEngine(searchQuery: String) {
        var iconURL: NSURL?
        var iconImage: UIImage?
        let SearchTermComponent = "%s"
        let placeholder = "{searchTerms}"
        var processedSearchQuery = ""
        if searchQuery.componentsSeparatedByString(SearchTermComponent).count - 1 == 1{
            processedSearchQuery = searchQuery.stringByReplacingOccurrencesOfString(SearchTermComponent, withString: placeholder)
        }
        guard processedSearchQuery != "",
            let url = NSURL(string: processedSearchQuery.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLFragmentAllowedCharacterSet())!),
            let shortName = url.domainURL().host
            else {
                let alert = ThirdPartySearchAlerts.failedToAddThirdPartySearch()
                self.presentViewController(alert, animated: true, completion: nil)
                return
        }
        if let favicon = faviconFor(url) {
            iconURL = NSURL(string: favicon.url)
        }
            iconImage = FaviconFetcher.getDefaultFavicon(url)
        
        let alert = ThirdPartySearchAlerts.addThirdPartySearchEngine { alert in
            //                self.customSearchEngineButton.tintColor = UIColor.grayColor()
            //                self.customSearchEngineButton.userInteractionEnabled = false
            SDWebImageManager.sharedManager().downloadImageWithURL(iconURL, options: SDWebImageOptions.ContinueInBackground, progress: nil) { (image, error, cacheType, success, url) in
                if image != nil {
                    iconImage = image
                }
                guard iconImage != nil else {
                    let alert = ThirdPartySearchAlerts.failedToAddThirdPartySearch()
                    self.presentViewController(alert, animated: true, completion: nil)
                    return
                }
                self.profile.searchEngines.addSearchEngine(OpenSearchEngine(engineID: nil, shortName: shortName, image: iconImage!, searchTemplate: processedSearchQuery, suggestTemplate: nil, isCustomEngine: true))
                let Toast = SimpleToast()
                Toast.showAlertWithText(Strings.ThirdPartySearchEngineAdded)
            }
        }
        
        self.presentViewController(alert, animated: true, completion: {})
    }
    
    override func generateSettings() -> [SettingSection] {
        
        func URLFromString(string: String?) -> NSURL? {
            guard let string = string else {
                return nil
            }
            return NSURL(string: string)
        }
        
        let basicSettings: [Setting] = [
            CustomSearchEngineField(placeholder: "URL (Replace Query with %s)", settingDidChange: {fieldText in
                    self.urlString = fieldText
                }, settingIsValid: { text in
                    //Can check url text text validity here.
                    return true
            })
            ]
        
        let settings: [SettingSection] = [
            SettingSection(title: NSAttributedString(string: "Custom Engine URL"), children: basicSettings),
            SettingSection(children: [
            ButtonSetting(title: NSAttributedString(string: "Save"), accessibilityIdentifier: "SaveCustomEngine", onClick: addCustomSearchEngine())
                ])
        ]
        
        return settings
    }
    
    func addCustomSearchEngine() -> (UINavigationController? -> ()) {
        return { nav in
            self.addSearchEngine(self.urlString!)
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
