/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AutocompleteTextField
import Telemetry

protocol AddCustomDomainViewControllerDelegate: class {
    func addCustomDomainViewControllerDidFinish(_ viewController: AddCustomDomainViewController)
}

class AddCustomDomainViewController: UIViewController, UITextFieldDelegate {
    private let autocompleteSource: CustomAutocompleteSource
    private let inputLabel = SmartLabel()
    private let textInput: UITextField = InsetTextField(insetBy: 10)
    private let inputDescription = SmartLabel()
    weak var delegate: AddCustomDomainViewControllerDelegate?
    
    init(autocompleteSource: CustomAutocompleteSource) {
        self.autocompleteSource = autocompleteSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        title = UIConstants.strings.autocompleteAddCustomUrl
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: UIConstants.strings.cancel, style: .plain, target: self, action: #selector(AddCustomDomainViewController.cancelTapped))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: UIConstants.strings.save, style: .done, target: self, action: #selector(AddCustomDomainViewController.doneTapped))
        self.navigationItem.rightBarButtonItem?.accessibilityIdentifier = "saveButton"
        
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIConstants.colors.background

        inputLabel.text = UIConstants.strings.autocompleteAddCustomUrlLabel
        inputLabel.font = UIConstants.fonts.settingsInputLabel
        inputLabel.textColor = UIConstants.colors.settingsTextLabel
        view.addSubview(inputLabel)

        textInput.backgroundColor = UIConstants.colors.urlTextBackground
        textInput.keyboardType = .URL
        textInput.autocapitalizationType = .none
        textInput.autocorrectionType = .no
        textInput.returnKeyType = .done
        textInput.textColor = UIColor.white
        textInput.delegate = self
        textInput.attributedPlaceholder = NSAttributedString(string: UIConstants.strings.autocompleteAddCustomUrlPlaceholder, attributes: [.foregroundColor: UIConstants.colors.inputPlaceholder])
        textInput.accessibilityIdentifier = "urlInput"
        textInput.becomeFirstResponder()
        view.addSubview(textInput)

        inputDescription.text = UIConstants.strings.autocompleteAddCustomUrlExample
        inputDescription.textColor = UIConstants.colors.settingsTextLabel
        inputDescription.font = UIConstants.fonts.settingsDescriptionText
        view.addSubview(inputDescription)

        inputLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.trailing.equalToSuperview()
            make.leading.equalToSuperview().offset(10)
        }

        textInput.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(inputLabel.snp.bottom).offset(10)
        }

        inputDescription.snp.makeConstraints { make in
            make.top.equalTo(textInput.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(10)
        }
    }
    
    @objc func cancelTapped() {
        finish()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        doneTapped()
        return true
    }
    
    @objc func doneTapped() {
        self.resignFirstResponder()
        guard let domain = textInput.text, !domain.isEmpty else {
            Toast(text: UIConstants.strings.autocompleteAddCustomUrlError).show()
            return
        }

        switch autocompleteSource.add(suggestion: domain) {
        case .error(.duplicateDomain):
            finish()
        case .error(let error):
            guard !error.message.isEmpty else { return }
            Toast(text: error.message).show()
        case .success:
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.change, object: TelemetryEventObject.customDomain)
            Toast(text: UIConstants.strings.autocompleteCustomURLAdded).show()
            finish()
        }
    }

    private func finish() {
        delegate?.addCustomDomainViewControllerDidFinish(self)
        if UIDevice.current.userInterfaceIdiom == .pad {
            dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
