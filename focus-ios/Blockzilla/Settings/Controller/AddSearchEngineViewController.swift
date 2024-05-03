/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol AddSearchEngineDelegate: AnyObject {
    func addSearchEngineViewController(_ addSearchEngineViewController: AddSearchEngineViewController, name: String, searchTemplate: String)
}

class AddSearchEngineViewController: UIViewController, UITextViewDelegate {
    private let REQUEST_TIMEOUT: TimeInterval = 4

    private var delegate: AddSearchEngineDelegate
    private var searchEngineManager: SearchEngineManager
    private var saveButton: UIBarButtonItem?
    private var dataTask: URLSessionDataTask?

    private let leftMargin = UIConstants.layout.settingsItemOffset
    private let rowHeight = UIConstants.layout.addSearchEngineInputHeight

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private lazy var container: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()

    private lazy var nameLabel: SmartLabel = {
        let nameLabel = SmartLabel()
        nameLabel.text = UIConstants.strings.NameToDisplay
        nameLabel.textColor = .primaryText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        return nameLabel
    }()

    private lazy var nameInput: UITextField = {
        let nameInput = UITextField()
        nameInput.attributedPlaceholder = NSAttributedString(string: UIConstants.strings.AddSearchEngineName, attributes: [.foregroundColor: UIColor.primaryText.withAlphaComponent(0.65)])
        nameInput.backgroundColor = .secondarySystemGroupedBackground
        nameInput.textColor = .primaryText
        nameInput.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: rowHeight))
        nameInput.leftViewMode = .always
        nameInput.font = .body15
        nameInput.accessibilityIdentifier = "nameInput"
        nameInput.autocorrectionType = .no
        nameInput.tintColor = .accent
        nameInput.layer.cornerRadius = UIConstants.layout.settingsCellCornerRadius
        nameInput.translatesAutoresizingMaskIntoConstraints = false
        return nameInput
    }()

    private lazy var templateContainer: UIView = {
        let templateContainer = UIView()
        templateContainer.backgroundColor = .systemGroupedBackground
        templateContainer.translatesAutoresizingMaskIntoConstraints = false
        return templateContainer
    }()

    private lazy var templatePlaceholderLabel: UITextView = {
        let templatePlaceholderLabel = UITextView()
        templatePlaceholderLabel.backgroundColor = .secondarySystemGroupedBackground
        templatePlaceholderLabel.textColor = .primaryText.withAlphaComponent(0.65)
        templatePlaceholderLabel.text = UIConstants.strings.AddSearchEngineTemplatePlaceholder
        templatePlaceholderLabel.font = .body15
        templatePlaceholderLabel.contentInset = UIEdgeInsets(top: -2, left: 3, bottom: 0, right: 0)
        templatePlaceholderLabel.isEditable = false
        templatePlaceholderLabel.layer.cornerRadius = UIConstants.layout.settingsCellCornerRadius
        templatePlaceholderLabel.layer.masksToBounds = true
        templatePlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        return templatePlaceholderLabel
    }()

    private lazy var templateLabel: SmartLabel = {
        let templateLabel = SmartLabel()
        templateLabel.text = UIConstants.strings.AddSearchEngineTemplate
        templateLabel.textColor = .primaryText
        templateLabel.translatesAutoresizingMaskIntoConstraints = false
        return templateLabel
    }()

    private lazy var templateInput: UITextView = {
        let templateInput = UITextView()
        templateInput.backgroundColor = .clear
        templateInput.textColor = .primaryText
        templateInput.keyboardType = .URL
        templateInput.font = .body15
        templateInput.accessibilityIdentifier = "templateInput"
        templateInput.autocapitalizationType = .none
        templateInput.keyboardAppearance = .dark
        templateInput.autocorrectionType = .no
        templateInput.tintColor = .accent
        templateInput.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 0, right: 0)
        templateInput.layer.cornerRadius = UIConstants.layout.settingsCellCornerRadius
        templateInput.translatesAutoresizingMaskIntoConstraints = false
        return templateInput
    }()

    private lazy var exampleLabel: SmartLabel = {
        let exampleLabel = SmartLabel()
        let learnMore = NSAttributedString(string: UIConstants.strings.learnMore, attributes: [.foregroundColor: UIColor.accent])
        let subtitle = NSMutableAttributedString(string: UIConstants.strings.AddSearchEngineTemplateExample2, attributes: [.foregroundColor: UIColor.secondaryText])
        let space = NSAttributedString(string: " ", attributes: [:])
        subtitle.append(space)
        subtitle.append(learnMore)
        exampleLabel.numberOfLines = 1
        exampleLabel.attributedText = subtitle
        exampleLabel.font = .footnote12
        exampleLabel.adjustsFontSizeToFitWidth = true
        exampleLabel.minimumScaleFactor = 0.5
        exampleLabel.isUserInteractionEnabled = true
        exampleLabel.translatesAutoresizingMaskIntoConstraints = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(learnMoreTapped))
        exampleLabel.addGestureRecognizer(tapGesture)
        return exampleLabel
    }()

    private var containerBottomConstraint = NSLayoutConstraint()

    init(delegate: AddSearchEngineDelegate, searchEngineManager: SearchEngineManager) {
        self.delegate = delegate
        self.searchEngineManager = searchEngineManager

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        KeyboardHelper.defaultHelper.addDelegate(delegate: self)
        title = UIConstants.strings.AddSearchEngineTitle

        setupUI()
        setupEvents()
        navigationItem.rightBarButtonItem?.isEnabled = false
        nameInput.becomeFirstResponder()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(scrollView)
        scrollView.addSubview(container)
        container.addSubview(nameLabel)
        container.addSubview(nameInput)
        container.addSubview(templateContainer)
        templateContainer.addSubview(templatePlaceholderLabel)
        container.addSubview(templateLabel)
        templateContainer.addSubview(templateInput)
        container.addSubview(exampleLabel)

        containerBottomConstraint = container.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)

        NSLayoutConstraint.activate([
            containerBottomConstraint,
            container.topAnchor.constraint(equalTo: scrollView.topAnchor),
            container.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            container.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            container.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            nameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: UIConstants.layout.addSearchEngineInputOffset),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: leftMargin),
            nameLabel.widthAnchor.constraint(equalTo: container.widthAnchor),
            nameLabel.heightAnchor.constraint(equalToConstant: rowHeight),

            nameInput.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
            nameInput.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: UIConstants.layout.settingsItemInset),
            nameInput.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -UIConstants.layout.settingsItemInset),
            nameInput.heightAnchor.constraint(equalToConstant: rowHeight),

            templateLabel.topAnchor.constraint(equalTo: nameInput.bottomAnchor, constant: UIConstants.layout.addSearchEngineInputOffset),
            templateLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: UIConstants.layout.settingsItemOffset),
            templateLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -UIConstants.layout.settingsItemOffset),
            templateLabel.heightAnchor.constraint(equalToConstant: rowHeight),

            templateContainer.topAnchor.constraint(equalTo: templateLabel.bottomAnchor),
            templateContainer.widthAnchor.constraint(equalTo: container.widthAnchor),
            templateContainer.heightAnchor.constraint(equalToConstant: UIConstants.layout.addSearchEngineTemplateContainerHeight),

            templateInput.topAnchor.constraint(equalTo: templateContainer.topAnchor),
            templateInput.bottomAnchor.constraint(equalTo: templateContainer.bottomAnchor),
            templateInput.leadingAnchor.constraint(equalTo: templateContainer.leadingAnchor, constant: UIConstants.layout.settingsItemInset),
            templateInput.trailingAnchor.constraint(equalTo: templateContainer.trailingAnchor, constant: -UIConstants.layout.settingsItemInset),

            templatePlaceholderLabel.bottomAnchor.constraint(equalTo: templateInput.bottomAnchor),
            templatePlaceholderLabel.topAnchor.constraint(equalTo: templateInput.topAnchor),
            templatePlaceholderLabel.leadingAnchor.constraint(equalTo: templateInput.leadingAnchor),
            templatePlaceholderLabel.trailingAnchor.constraint(equalTo: templateInput.trailingAnchor),

            exampleLabel.topAnchor.constraint(equalTo: templateInput.bottomAnchor, constant: UIConstants.layout.addSearchEngineExampleLabelOffset),
            exampleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: leftMargin),
            exampleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -leftMargin)
        ])
    }

    @objc
    func learnMoreTapped() {
        let contentViewController = SettingsContentViewController(url: URL(forSupportTopic: .addSearchEngine))
        navigationController?.pushViewController(contentViewController, animated: true)
    }

    private func setupEvents() {
        saveButton = UIBarButtonItem(title: UIConstants.strings.save, style: .plain, target: self, action: #selector(AddSearchEngineViewController.saveTapped))
        saveButton?.accessibilityIdentifier = "save"

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: UIConstants.strings.cancel, style: .plain, target: self, action: #selector(AddSearchEngineViewController.cancelTapped))
        navigationItem.rightBarButtonItem = saveButton

        templateInput.delegate = self
        nameInput.delegate = self
    }

    @objc
    func cancelTapped() {
        dataTask?.cancel()
        self.navigationController?.popViewController(animated: true)
    }

    @objc
    func saveTapped() {
        guard let name = nameInput.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        guard let template = templateInput.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }

        if !AddSearchEngineViewController.isValidTemplate(template) || !searchEngineManager.isValidSearchEngineName(name) {
            presentRetryError()
            showIndicator(false)
            return
        }

        showIndicator(true)

        let searchString = template.replacingOccurrences(of: "%s", with: "Firefox Focus".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)

        guard URL(string: searchString, invalidCharacters: false) != nil else {
            presentRetryError()
            showIndicator(false)
            return
        }

        self.delegate.addSearchEngineViewController(self, name: name, searchTemplate: template)
        Toast(text: UIConstants.strings.NewSearchEngineAdded).show()
        self.navigationController?.popViewController(animated: true)
    }

    private func presentRetryError() {
        let controller = UIAlertController(title: UIConstants.strings.addSearchEngineError, message: nil, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: UIConstants.strings.errorTryAgain, style: .default, handler: { _ in
        }))
        self.present(controller, animated: true, completion: nil)
    }

    func showIndicator(_ shouldShow: Bool) {
        guard shouldShow else { self.navigationItem.rightBarButtonItem = self.saveButton; return }

        let indicatorView = UIActivityIndicatorView(style: .medium)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: indicatorView)
        indicatorView.startAnimating()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        templatePlaceholderLabel.isHidden = !textView.text.isEmpty
        templateInput.backgroundColor = textView.text.isEmpty ? .clear : .secondarySystemGroupedBackground
    }

    func textViewDidChange(_ textView: UITextView) {
        templatePlaceholderLabel.isHidden = !textView.text.isEmpty
        templateInput.backgroundColor = textView.text.isEmpty ? .clear : .secondarySystemGroupedBackground
        navigationItem.rightBarButtonItem?.isEnabled = !templateInput.text.isEmpty && !nameInput.text!.isEmpty
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        templatePlaceholderLabel.isHidden = !textView.text.isEmpty
        templateInput.backgroundColor = textView.text.isEmpty ? .clear : .secondarySystemGroupedBackground
    }

    static func isValidTemplate(_ template: String) -> Bool {
        if template.isEmpty {
            return false
        }

        if !template.contains("%s") {
            return false
        }

        guard let url = URL(string: template.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!,
                            invalidCharacters: false)
        else { return false }
        return url.isWebPage()
    }
}

extension AddSearchEngineViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        navigationItem.rightBarButtonItem?.isEnabled = !templateInput.text.isEmpty && !nameInput.text!.isEmpty
        return true
    }
}

extension AddSearchEngineViewController: KeyboardHelperDelegate {
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        self.updateViewConstraints()
        UIView.animate(withDuration: state.animationDuration) {
            self.containerBottomConstraint.isActive = false
            self.containerBottomConstraint = self.container.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor, constant: -state.intersectionHeightForView(view: self.view))
            NSLayoutConstraint.activate([self.containerBottomConstraint])
            self.view.layoutIfNeeded()
        }
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        self.updateViewConstraints()
        UIView.animate(withDuration: state.animationDuration) { [self] in
            self.containerBottomConstraint.isActive = false
            self.containerBottomConstraint = self.container.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor)
            NSLayoutConstraint.activate([self.containerBottomConstraint])
            self.view.layoutIfNeeded()
        }
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidHideWithState state: KeyboardState) { }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) { }
}
