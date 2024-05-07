/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Intents
import IntentsUI

class SiriFavoriteViewController: UIViewController {
    private lazy var cancelButton: UIBarButtonItem = {
        let cancelButton = UIBarButtonItem(title: UIConstants.strings.cancel, style: .plain, target: self, action: #selector(SiriFavoriteViewController.cancelTapped))
        cancelButton.tintColor = .accent
        return cancelButton
    }()

    private lazy var nextButton: UIBarButtonItem = {
       let nextButton = UIBarButtonItem(title: UIConstants.strings.NextIntroButtonTitle, style: .done, target: self, action: #selector(SiriFavoriteViewController.nextTapped))
        nextButton.accessibilityIdentifier = "nextButton"
        nextButton.tintColor = .accent
        return nextButton
    }()

    private lazy var doneButton: UIBarButtonItem = {
        let doneButton = UIBarButtonItem(title: UIConstants.strings.Done, style: .done, target: self, action: #selector(SiriFavoriteViewController.doneTapped))
        doneButton.accessibilityIdentifier = "doneButton"
        doneButton.tintColor = .accent
        return doneButton
    }()

    private lazy var inputLabel: SmartLabel = {
        let inputLabel = SmartLabel()
        inputLabel.text = UIConstants.strings.urlToOpen
        inputLabel.font = .body18
        inputLabel.textColor = .primaryText
        inputLabel.translatesAutoresizingMaskIntoConstraints = false
        return inputLabel
    }()

    private lazy var textInput: UITextField = {
        let textInput: UITextField = InsetTextField(insetBy: UIConstants.layout.settingsTextPadding)
        textInput.backgroundColor = .secondarySystemGroupedBackground
        textInput.keyboardType = .URL
        textInput.autocapitalizationType = .none
        textInput.autocorrectionType = .no
        textInput.returnKeyType = .done
        textInput.textColor = .primaryText
        textInput.tintColor = .accent
        textInput.delegate = self
        textInput.layer.cornerRadius = UIConstants.layout.settingsCellCornerRadius
        if let storedFavorite = UserDefaults.standard.value(forKey: "favoriteUrl") as? String {
            textInput.text = storedFavorite
        } else {
            textInput.attributedPlaceholder = NSAttributedString(string: UIConstants.strings.autocompleteAddCustomUrlPlaceholder, attributes: [.foregroundColor: UIColor.inputPlaceholder])
        }

        textInput.accessibilityIdentifier = "urlInput"
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

    private lazy var editView: EditView = {
        let editView = EditView()
        editView.backgroundColor = .systemGroupedBackground
        editView.translatesAutoresizingMaskIntoConstraints = false
        return editView
    }()

    private lazy var editLabel: UILabel = {
        let editLabel = UILabel()
        editLabel.text = UIConstants.strings.editOpenUrl
        editLabel.textColor = .accent
        editLabel.translatesAutoresizingMaskIntoConstraints = false
        return editLabel
    }()

    private lazy var topBorder: UIView = {
        let topBorder = UIView()
        topBorder.backgroundColor = .systemGray
        topBorder.translatesAutoresizingMaskIntoConstraints = false
        return topBorder
    }()

    private lazy var bottomBorder: UIView = {
        let bottomBorder = UIView()
        bottomBorder.backgroundColor = .systemGray
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        return bottomBorder
    }()

    private var addedToSiri = false {
        didSet {
            editView.isHidden = !addedToSiri
            setUpRightBarButton()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = []
        setUpInputUI()
        setUpEditUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SiriShortcuts().hasAddedActivity(type: .openURL) { (result: Bool) in
            self.addedToSiri = result
        }
    }

    private func setUpInputUI() {
        title = UIConstants.strings.favoriteUrlTitle
        navigationController?.navigationBar.tintColor = .accent
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.defaultFont]
        navigationController?.navigationBar.isTranslucent = false
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(inputLabel)
        view.addSubview(textInput)
        view.addSubview(inputDescription)

        self.navigationItem.leftBarButtonItem = cancelButton

        NSLayoutConstraint.activate([
            inputLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: UIConstants.layout.siriUrlSectionPadding),
            inputLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            inputLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: UIConstants.layout.settingsItemOffset),

            textInput.heightAnchor.constraint(equalToConstant: UIConstants.layout.settingsSectionHeight),
            textInput.topAnchor.constraint(equalTo: inputLabel.bottomAnchor, constant: UIConstants.layout.settingsTextPadding),
            textInput.leadingAnchor.constraint(equalTo: inputLabel.leadingAnchor, constant: -UIConstants.layout.settingsTextPadding),
            textInput.trailingAnchor.constraint(equalTo: inputLabel.trailingAnchor, constant: -UIConstants.layout.settingsTextPadding),

            inputDescription.topAnchor.constraint(equalTo: textInput.bottomAnchor, constant: UIConstants.layout.settingsTextPadding),
            inputDescription.leadingAnchor.constraint(equalTo: inputLabel.leadingAnchor)
        ])
    }

    private func setUpEditUI() {
        view.addSubview(editView)
        editView.addSubview(topBorder)
        editView.addSubview(editLabel)
        editView.addSubview(bottomBorder)

        let tap = UITapGestureRecognizer(target: self, action: #selector(SiriFavoriteViewController.editTapped))
        editView.addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            editView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            editView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            editView.heightAnchor.constraint(equalToConstant: UIConstants.layout.settingsSectionHeight),
            editView.topAnchor.constraint(equalTo: inputDescription.bottomAnchor, constant: UIConstants.layout.siriUrlSectionPadding),

            editLabel.leadingAnchor.constraint(equalTo: inputLabel.leadingAnchor, constant: -UIConstants.layout.settingsTextPadding),
            editLabel.centerYAnchor.constraint(equalTo: editView.centerYAnchor),

            topBorder.heightAnchor.constraint(equalToConstant: UIConstants.layout.separatorHeight),
            topBorder.widthAnchor.constraint(equalTo: editView.widthAnchor),
            topBorder.topAnchor.constraint(equalTo: editView.topAnchor),

            bottomBorder.heightAnchor.constraint(equalToConstant: UIConstants.layout.separatorHeight),
            bottomBorder.widthAnchor.constraint(equalTo: editView.widthAnchor),
            bottomBorder.bottomAnchor.constraint(equalTo: editView.bottomAnchor)
        ])
    }

    private func setUpRightBarButton() {
        self.navigationItem.rightBarButtonItem = addedToSiri ? doneButton : nextButton
    }

    @objc
    func cancelTapped() {
        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
    }

    @objc
    func doneTapped() {
        if saveFavorite() {
            self.navigationController?.popViewController(animated: true)
            self.dismiss(animated: true, completion: nil)
        }
    }

    @objc
    func nextTapped() {
        if saveFavorite() {
            SiriShortcuts().displayAddToSiri(for: .openURL, in: self)
        }
    }

    @objc
    func editTapped() {
        SiriShortcuts().manageSiri(for: .openURL, in: self)
    }

    private func saveFavorite() -> Bool {
        self.resignFirstResponder()
        guard let domain = textInput.text, !domain.isEmpty else {
            Toast(text: UIConstants.strings.autocompleteAddCustomUrlError).show()
            return false
        }
        do {
            let regex = try NSRegularExpression(pattern: "^(\\s+)?(?:https?:\\/\\/)?(?:www\\.)?", options: [.caseInsensitive])
            var sanitizedDomain = regex.stringByReplacingMatches(in: domain, options: [], range: NSRange(location: 0, length: domain.count), withTemplate: "")

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
            guard let url = URL(string: sanitizedDomain, invalidCharacters: false) else {
                Toast(text: UIConstants.strings.autocompleteAddCustomUrlError).show()
                return false
            }
            UserDefaults.standard.set(url.absoluteString, forKey: "favoriteUrl")
            TipManager.siriFavoriteTip = false
        } catch {
            fatalError("Invalid regular expression")
        }
        return true
    }
}

extension SiriFavoriteViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nextTapped()
        return true
    }
}

extension SiriFavoriteViewController: INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        guard voiceShortcut != nil else { return }
        navigationController?.popViewController(animated: true)
    }

    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

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
