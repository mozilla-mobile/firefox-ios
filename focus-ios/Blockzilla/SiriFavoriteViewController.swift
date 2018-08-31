/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Intents
import IntentsUI

@available(iOS 12.0, *)
class SiriFavoriteViewController: UIViewController {
    private let inputLabel = SmartLabel()
    private let textInput: UITextField = InsetTextField(insetBy: UIConstants.layout.settingsTextPadding)
    private let inputDescription = SmartLabel()
    private let editView = EditView()
    private var addedToSiri: Bool = false {
        didSet {
            editView.isHidden = !addedToSiri
            setUpRightBarButton()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SiriShortcuts().hasAddedActivity(type: .openURL) { (result: Bool) in
            self.addedToSiri = result
        }
    }
    
    override func viewDidLoad() {
        self.edgesForExtendedLayout = []
        setUpInputUI()
        setUpEditUI()
    }
    
    private func setUpInputUI() {
        title = UIConstants.strings.favoriteUrlTitle
        navigationController?.navigationBar.barTintColor = UIConstants.colors.background
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIConstants.colors.defaultFont]
        navigationController?.navigationBar.isTranslucent = false
        view.backgroundColor = UIConstants.colors.background
        
        inputLabel.text = UIConstants.strings.urlToOpen
        inputLabel.font = UIConstants.fonts.settingsInputLabel
        inputLabel.textColor = UIConstants.colors.settingsTextLabel
        view.addSubview(inputLabel)
        
        textInput.backgroundColor = UIConstants.colors.cellBackground
        textInput.keyboardType = .URL
        textInput.autocapitalizationType = .none
        textInput.autocorrectionType = .no
        textInput.returnKeyType = .done
        textInput.textColor = .white
        textInput.tintColor = UIConstants.colors.siriTint
        textInput.delegate = self
        if let storedFavorite = UserDefaults.standard.value(forKey: "favoriteUrl") as? String {
            textInput.text = storedFavorite
        } else {
            textInput.attributedPlaceholder = NSAttributedString(string: UIConstants.strings.autocompleteAddCustomUrlPlaceholder, attributes: [.foregroundColor: UIConstants.colors.inputPlaceholder])
        }
        
        textInput.accessibilityIdentifier = "urlInput"
        textInput.becomeFirstResponder()
        view.addSubview(textInput)
        
        inputDescription.text = UIConstants.strings.autocompleteAddCustomUrlExample
        inputDescription.textColor = UIConstants.colors.settingsTextLabel
        inputDescription.font = UIConstants.fonts.settingsDescriptionText
        view.addSubview(inputDescription)
        
        inputLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(UIConstants.layout.siriUrlSectionPadding)
            make.trailing.equalToSuperview()
            make.leading.equalToSuperview().offset(UIConstants.layout.settingsTextPadding)
        }
        
        textInput.snp.makeConstraints { make in
            make.height.equalTo(UIConstants.layout.settingsSectionHeight)
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(inputLabel.snp.bottom).offset(UIConstants.layout.settingsTextPadding)
        }
        
        inputDescription.snp.makeConstraints { make in
            make.top.equalTo(textInput.snp.bottom).offset(UIConstants.layout.settingsTextPadding)
            make.leading.equalToSuperview().offset(UIConstants.layout.settingsTextPadding)
        }
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: UIConstants.strings.cancel, style: .plain, target: self, action: #selector(SiriFavoriteViewController.cancelTapped))
        self.navigationItem.leftBarButtonItem?.tintColor = UIConstants.colors.siriTint
    }
    
    private func setUpEditUI() {
        editView.backgroundColor = UIConstants.colors.cellBackground
        view.addSubview(editView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(SiriFavoriteViewController.editTapped))
        editView.addGestureRecognizer(tap)
        
        editView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(UIConstants.layout.settingsSectionHeight)
            make.top.equalTo(inputDescription.snp.bottom).offset(UIConstants.layout.siriUrlSectionPadding)
        }
        
        let editLabel = UILabel()
        editLabel.text = UIConstants.strings.editOpenUrl
        editLabel.textColor = UIConstants.colors.siriTint
        
        editView.addSubview(editLabel)
        editLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(UIConstants.layout.settingsTextPadding)
            make.centerY.equalToSuperview()
        }
        
        let topBorder = UIView()
        topBorder.backgroundColor = UIConstants.colors.settingsSeparator
        editView.addSubview(topBorder)
        topBorder.snp.makeConstraints { make in
            make.height.equalTo(UIConstants.layout.separatorHeight)
            make.top.width.equalToSuperview()
        }
        
        let bottomBorder = UIView()
        bottomBorder.backgroundColor = UIConstants.colors.settingsSeparator
        editView.addSubview(bottomBorder)
        bottomBorder.snp.makeConstraints { make in
            make.height.equalTo(UIConstants.layout.separatorHeight)
            make.width.bottom.equalToSuperview()
        }
    }
    
    private func setUpRightBarButton() {
        let nextButton = UIBarButtonItem(title: UIConstants.strings.NextIntroButtonTitle, style: .done, target: self, action: #selector(SiriFavoriteViewController.nextTapped))
        nextButton.accessibilityIdentifier = "nextButton"
        let doneButton = UIBarButtonItem(title: UIConstants.strings.Done, style: .done, target: self, action: #selector(SiriFavoriteViewController.doneTapped))
        nextButton.accessibilityIdentifier = "doneButton"
        self.navigationItem.rightBarButtonItem = addedToSiri ? doneButton : nextButton
        self.navigationItem.rightBarButtonItem?.tintColor = UIConstants.colors.siriTint
    }
    
    @objc func cancelTapped() {
        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func doneTapped() {
        if saveFavorite() {
            self.navigationController?.popViewController(animated: true)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func nextTapped() {
        if saveFavorite() {
            SiriShortcuts().displayAddToSiri(for: .openURL, in: self)
        }
    }
    
    @objc func editTapped() {
        SiriShortcuts().manageSiri(for: .openURL, in: self)
    }
    
    private func saveFavorite() -> Bool {
        self.resignFirstResponder()
        guard let domain = textInput.text, !domain.isEmpty else {
            Toast(text: UIConstants.strings.autocompleteAddCustomUrlError).show()
            return false
        }
        let regex = try! NSRegularExpression(pattern: "^(\\s+)?(?:https?:\\/\\/)?(?:www\\.)?", options: [.caseInsensitive])
        var sanitizedDomain = regex.stringByReplacingMatches(in: domain, options: [], range: NSMakeRange(0, domain.count), withTemplate: "")
        
        guard !sanitizedDomain.isEmpty, sanitizedDomain.contains(".") else {
            Toast(text: UIConstants.strings.autocompleteAddCustomUrlError).show()
            return false
        }
        if sanitizedDomain.suffix(1) == "/" {
            sanitizedDomain = String(sanitizedDomain.dropLast())
        }
        if !sanitizedDomain.hasPrefix("http://") && !sanitizedDomain.hasPrefix("https://") {
            sanitizedDomain = String(format: "https://%@", sanitizedDomain)
        }
        guard let url = URL(string: sanitizedDomain) else {
            Toast(text: UIConstants.strings.autocompleteAddCustomUrlError).show()
            return false
        }
        UserDefaults.standard.set(url.absoluteString, forKey: "favoriteUrl")
        UserDefaults.standard.set(false, forKey: TipManager.TipKey.siriFavoriteTip)
        return true
    }
}

@available(iOS 12.0, *)
extension SiriFavoriteViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nextTapped()
        return true
    }
}

@available(iOS 12.0, *)
extension SiriFavoriteViewController: INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

@available(iOS 12.0, *)
extension SiriFavoriteViewController: INUIEditVoiceShortcutViewControllerDelegate {
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

class EditView: UIView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = UIConstants.colors.cellSelected
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = UIConstants.colors.cellBackground
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = UIConstants.colors.cellBackground
    }
}
