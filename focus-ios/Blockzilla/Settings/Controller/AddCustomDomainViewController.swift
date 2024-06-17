/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Glean

protocol AddCustomDomainViewControllerDelegate: AnyObject {
    func addCustomDomainViewControllerDidFinish(_ viewController: AddCustomDomainViewController)
}

class AddCustomDomainViewController: UIViewController, UITextFieldDelegate {
    private lazy var inputLabel: SmartLabel = {
        let inputLabel = SmartLabel()
        inputLabel.text = UIConstants.strings.autocompleteAddCustomUrlLabel
        inputLabel.font = .body18
        inputLabel.textColor = .primaryText
        inputLabel.translatesAutoresizingMaskIntoConstraints = false
        return inputLabel
    }()

    private lazy var textInput: UITextField = {
        let textInput: UITextField = InsetTextField(insetBy: 10)
        textInput.backgroundColor = .secondarySystemGroupedBackground
        textInput.keyboardType = .URL
        textInput.autocapitalizationType = .none
        textInput.autocorrectionType = .no
        textInput.returnKeyType = .done
        textInput.textColor = .primaryText
        textInput.delegate = self
        textInput.attributedPlaceholder = NSAttributedString(string: UIConstants.strings.autocompleteAddCustomUrlPlaceholder, attributes: [.foregroundColor: UIColor.inputPlaceholder])
        textInput.accessibilityIdentifier = "urlInput"
        textInput.layer.cornerRadius = UIConstants.layout.settingsCellCornerRadius
        textInput.tintColor = .accent
        textInput.becomeFirstResponder()
        textInput.translatesAutoresizingMaskIntoConstraints = false
        return textInput
    }()

    private lazy var inputDescription: SmartLabel = {
        let inputDescription = SmartLabel()
        inputDescription.text = UIConstants.strings.autocompleteAddCustomUrlExample
        inputDescription.textColor = .primaryText
        inputDescription.font = .footnote12
        inputDescription.translatesAutoresizingMaskIntoConstraints = false
        return inputDescription
    }()

    private let autocompleteSource: CustomAutocompleteSource
    weak var delegate: AddCustomDomainViewControllerDelegate?

    init(autocompleteSource: CustomAutocompleteSource) {
        self.autocompleteSource = autocompleteSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = UIConstants.strings.autocompleteAddCustomUrl
        navigationController?.navigationBar.tintColor = .accent
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: UIConstants.strings.cancel, style: .plain, target: self, action: #selector(AddCustomDomainViewController.cancelTapped))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: UIConstants.strings.save, style: .done, target: self, action: #selector(AddCustomDomainViewController.doneTapped))
        self.navigationItem.rightBarButtonItem?.accessibilityIdentifier = "saveButton"

        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(inputLabel)
        view.addSubview(textInput)
        view.addSubview(inputDescription)

        NSLayoutConstraint.activate([
            inputLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: UIConstants.layout.settingsAddCustomDomainInputTopOffset),
            inputLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: UIConstants.layout.settingsItemOffset),
            inputLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            textInput.topAnchor.constraint(equalTo: inputLabel.bottomAnchor, constant: UIConstants.layout.settingsAddCustomDomainOffset),
            textInput.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: UIConstants.layout.settingsItemInset),
            textInput.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -UIConstants.layout.settingsItemInset),
            textInput.heightAnchor.constraint(equalToConstant: UIConstants.layout.settingsSectionHeight),

            inputDescription.topAnchor.constraint(equalTo: textInput.bottomAnchor, constant: UIConstants.layout.settingsAddCustomDomainOffset),
            inputDescription.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: UIConstants.layout.settingsItemOffset)
        ])
    }

    @objc
    func cancelTapped() {
        finish()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        doneTapped()
        return true
    }

    @objc
    func doneTapped() {
        self.resignFirstResponder()
        guard let domain = textInput.text, !domain.isEmpty else {
            Toast(text: UIConstants.strings.autocompleteAddCustomUrlError).show()
            return
        }

        switch autocompleteSource.add(suggestion: domain) {
        case .failure(.duplicateDomain):
            finish()
        case .failure(let error):
            guard !error.message.isEmpty else { return }
            Toast(text: error.message).show()
        case .success:
            GleanMetrics.SettingsScreen.autocompleteDomainAdded.add()
            Toast(text: UIConstants.strings.autocompleteCustomURLAdded).show()
            finish()
        }
    }

    private func finish() {
        delegate?.addCustomDomainViewControllerDidFinish(self)
        self.navigationController?.popViewController(animated: true)
    }
}
