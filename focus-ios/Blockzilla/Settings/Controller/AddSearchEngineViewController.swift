/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol AddSearchEngineDelegate {
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

    private var nameInput = UITextField()
    private var templateInput = UITextView()
    private var templatePlaceholderLabel = UITextView()
    private var scrollView =  UIScrollView()
    private var container = UIView()

    init(delegate: AddSearchEngineDelegate, searchEngineManager: SearchEngineManager) {
        self.delegate = delegate
        self.searchEngineManager = searchEngineManager

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
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

        scrollView.snp.makeConstraints { (make) in
            make.leading.trailing.top.bottom.equalToSuperview()
        }
        scrollView.showsVerticalScrollIndicator = false

        let nameLabel = SmartLabel()
        nameLabel.text = UIConstants.strings.NameToDisplay
        nameLabel.textColor = .primaryText
        container.addSubview(nameLabel)

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
        container.addSubview(nameInput)

        let templateContainer = UIView()
        templateContainer.backgroundColor = .systemGroupedBackground
        container.addSubview(templateContainer)

        templatePlaceholderLabel.backgroundColor = .secondarySystemGroupedBackground
        templatePlaceholderLabel.textColor = .primaryText.withAlphaComponent(0.65)
        templatePlaceholderLabel.text = UIConstants.strings.AddSearchEngineTemplatePlaceholder
        templatePlaceholderLabel.font = .body15
        templatePlaceholderLabel.contentInset = UIEdgeInsets(top: -2, left: 3, bottom: 0, right: 0)
        templatePlaceholderLabel.isEditable = false
        templatePlaceholderLabel.layer.cornerRadius = UIConstants.layout.settingsCellCornerRadius
        templatePlaceholderLabel.layer.masksToBounds = true
        templateContainer.addSubview(templatePlaceholderLabel)

        let templateLabel = SmartLabel()
        templateLabel.text = UIConstants.strings.AddSearchEngineTemplate
        templateLabel.textColor = .primaryText
        container.addSubview(templateLabel)

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
        templateContainer.addSubview(templateInput)

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

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(learnMoreTapped))
        exampleLabel.addGestureRecognizer(tapGesture)
        container.addSubview(exampleLabel)

        scrollView.addSubview(container)
        container.snp.makeConstraints { (make) in
            make.leading.trailing.top.bottom.equalToSuperview()
            make.width.height.equalToSuperview()
        }

        nameLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(UIConstants.layout.addSearchEngineInputOffset)
            make.height.equalTo(rowHeight)
            make.leading.equalTo(leftMargin)
            make.width.equalToSuperview()
        }

        nameInput.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom)
            make.height.equalTo(rowHeight)
            make.leading.trailing.equalToSuperview().inset(UIConstants.layout.settingsItemInset)
        }

        templateLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameInput.snp.bottom).offset(UIConstants.layout.addSearchEngineInputOffset)
            make.height.equalTo(rowHeight)
            make.leading.trailing.equalToSuperview().inset(UIConstants.layout.settingsItemOffset)
        }

        templateContainer.snp.makeConstraints { (make) in
            make.top.equalTo(templateLabel.snp.bottom)
            make.height.equalTo(UIConstants.layout.addSearchEngineTemplateContainerHeight)
            make.width.equalToSuperview()
        }

        templateInput.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(UIConstants.layout.settingsItemInset)
        }

        templatePlaceholderLabel.snp.makeConstraints { (make) in
            make.edges.equalTo(templateInput)
        }

        exampleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(templateInput.snp.bottom).offset(UIConstants.layout.addSearchEngineExampleLabelOffset)
            make.leading.equalToSuperview().offset(leftMargin)
            make.trailing.equalToSuperview().offset(-leftMargin)
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        updateContainerConstraints()
    }

    private func updateContainerConstraints() {
        scrollView.snp.updateConstraints { make in
            switch (UIDevice.current.userInterfaceIdiom, UIDevice.current.orientation) {
            case (.phone, .landscapeLeft):
                make.leading.equalTo(view).offset(self.view.safeAreaInsets.left)
                make.trailing.equalTo(view)
                scrollView.isScrollEnabled = true
            case (.phone, .landscapeRight):
                make.leading.equalTo(view)
                make.trailing.equalTo(view).inset(self.view.safeAreaInsets.right)
                scrollView.isScrollEnabled = true
            default:
                make.leading.trailing.equalTo(view)
                scrollView.isScrollEnabled = false
            }

        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateContainerConstraints()
    }

    @objc func learnMoreTapped() {
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

    @objc func cancelTapped() {
        dataTask?.cancel()
        self.navigationController?.popViewController(animated: true)
    }

    @objc func saveTapped() {
        guard let name = nameInput.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        guard let template = templateInput.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }

        if !AddSearchEngineViewController.isValidTemplate(template) || !searchEngineManager.isValidSearchEngineName(name) {
            presentRetryError()
            showIndicator(false)
            return
        }

        showIndicator(true)

        let searchString = template.replacingOccurrences(of: "%s", with: "Firefox Focus".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)

        guard URL(string: searchString) != nil else {
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

        guard let url = URL(string: template.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!) else { return false }
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
            self.container.snp.updateConstraints { (make) in
                make.bottom.equalToSuperview().offset(-state.intersectionHeightForView(view: self.view))
            }
            self.view.layoutIfNeeded()
        }
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        self.updateViewConstraints()
        UIView.animate(withDuration: state.animationDuration) {
            self.container.snp.updateConstraints { (make) in
                make.height.equalToSuperview()
                self.view.layoutIfNeeded()
            }
        }
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidHideWithState state: KeyboardState) { }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) { }

}
