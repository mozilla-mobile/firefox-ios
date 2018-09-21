/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol AddSearchEngineDelegate {
    func addSearchEngineViewController(_ addSearchEngineViewController: AddSearchEngineViewController, name: String, searchTemplate: String)
}

class AddSearchEngineViewController: UIViewController, UITextViewDelegate {
    private let REQUEST_TIMEOUT: TimeInterval = 4

    private var delegate: AddSearchEngineDelegate
    private var searchEngineManager: SearchEngineManager
    private var saveButton: UIBarButtonItem?
    private var dataTask: URLSessionDataTask?
    
    private let leftMargin = 10
    private let rowHeight = 44
    
    private var nameInput = UITextField()
    private var templateInput = UITextView()
    private var templatePlaceholderLabel = SmartLabel()
    
    init(delegate: AddSearchEngineDelegate, searchEngineManager: SearchEngineManager) {
        self.delegate = delegate
        self.searchEngineManager = searchEngineManager

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        title = UIConstants.strings.AddSearchEngineTitle
        
        setupUI()
        setupEvents()
        navigationItem.rightBarButtonItem?.isEnabled = false
        nameInput.becomeFirstResponder()
    }
    
    private func setupUI() {
        view.backgroundColor = UIConstants.colors.background
        
        let container = UIView()
        view.addSubview(container)
        
        let nameLabel = SmartLabel()
        nameLabel.text = UIConstants.strings.NameToDisplay
        nameLabel.textColor = UIConstants.colors.settingsTextLabel
        container.addSubview(nameLabel)
        
        nameInput.attributedPlaceholder = NSAttributedString(string: UIConstants.strings.AddSearchEngineName, attributes: [.foregroundColor: UIConstants.colors.settingsDetailLabel])
        nameInput.backgroundColor = UIConstants.colors.cellBackground
        nameInput.textColor = UIConstants.colors.settingsTextLabel
        nameInput.leftView = UIView(frame: CGRect(x: 0, y: 0, width: leftMargin, height: rowHeight))
        nameInput.leftViewMode = .always
        nameInput.font = UIFont.systemFont(ofSize: 15)
        nameInput.accessibilityIdentifier = "nameInput"
        nameInput.autocorrectionType = .no
        container.addSubview(nameInput)

        let templateContainer = UIView()
        templateContainer.backgroundColor = UIConstants.colors.cellBackground
        container.addSubview(templateContainer)

        templatePlaceholderLabel.backgroundColor = UIConstants.colors.cellBackground
        templatePlaceholderLabel.textColor = UIConstants.colors.settingsDetailLabel
        templatePlaceholderLabel.text = UIConstants.strings.AddSearchEngineTemplatePlaceholder
        templatePlaceholderLabel.font = UIFont.systemFont(ofSize: 15)
        templatePlaceholderLabel.numberOfLines = 0
        templateContainer.addSubview(templatePlaceholderLabel)
        
        let templateLabel = SmartLabel()
        templateLabel.text = UIConstants.strings.AddSearchEngineTemplate
        templateLabel.textColor = UIConstants.colors.settingsTextLabel
        container.addSubview(templateLabel)

        templateInput.backgroundColor = .clear
        templateInput.textColor = UIConstants.colors.settingsTextLabel
        templateInput.keyboardType = .URL
        templateInput.font = UIFont.systemFont(ofSize: 15)
        templateInput.accessibilityIdentifier = "templateInput"
        templateInput.autocapitalizationType = .none
        templateInput.keyboardAppearance = .dark
        templateInput.autocorrectionType = .no
        templateContainer.addSubview(templateInput)

        let exampleLabel = SmartLabel()
        let learnMore = NSAttributedString(string: UIConstants.strings.learnMore, attributes: [.foregroundColor : UIConstants.colors.settingsLink])
        let subtitle = NSMutableAttributedString(string: UIConstants.strings.AddSearchEngineTemplateExample, attributes: [.foregroundColor : UIConstants.colors.settingsDetailLabel])
        let space = NSAttributedString(string: " ", attributes: [:])
        subtitle.append(space)
        subtitle.append(learnMore)

        exampleLabel.numberOfLines = 1
        exampleLabel.attributedText = subtitle
        exampleLabel.font = UIFont.systemFont(ofSize: 12)
        exampleLabel.adjustsFontSizeToFitWidth = true
        exampleLabel.minimumScaleFactor = 0.5
        exampleLabel.isUserInteractionEnabled = true


        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(learnMoreTapped))
        exampleLabel.addGestureRecognizer(tapGesture)
        container.addSubview(exampleLabel)
        
        container.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.height.equalTo(rowHeight)
            make.leading.equalTo(leftMargin)
            make.width.equalToSuperview()
        }
        
        nameInput.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom)
            make.height.equalTo(rowHeight)
            make.width.equalToSuperview()
        }

        templateLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameInput.snp.bottom).offset(16)
            make.leading.equalTo(leftMargin)
            make.height.equalTo(rowHeight)
        }

        templateContainer.snp.makeConstraints { (make) in
            make.top.equalTo(templateLabel.snp.bottom)
            make.height.equalTo(88)
            make.width.equalToSuperview()
        }

        
        templateInput.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.trailing.equalToSuperview().offset(-4)
            make.leading.equalToSuperview().offset(5)
        }

        templatePlaceholderLabel.snp.makeConstraints { (make) in
            make.height.equalTo(44)
            make.top.equalToSuperview().offset(4)
            make.leading.equalToSuperview().offset(9)
            make.trailing.equalToSuperview().offset(-leftMargin)
        }
        
        exampleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(templateInput.snp.bottom).offset(2)
            make.leading.equalToSuperview().offset(leftMargin)
            make.trailing.equalToSuperview().offset(-leftMargin)
        }
    }

    @objc func learnMoreTapped() {
        guard let url = SupportUtils.URLForTopic(topic: "add-search-engine-ios") else { return }
        let contentViewController = SettingsContentViewController(url: url)
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
        guard let name = nameInput.text else { return }
        guard let template = templateInput.text else { return }
        
        if !AddSearchEngineViewController.isValidTemplate(template) || !searchEngineManager.isValidSearchEngineName(name) {
            presentRetryError()
            showIndicator(false)
            return
        }

        showIndicator(true)

        let searchString = template.replacingOccurrences(of: "%s", with: "Firefox Focus".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)

        guard let url = URL(string: searchString) else {
            presentRetryError()
            showIndicator(false)
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = REQUEST_TIMEOUT

        dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let statusCode = response.flatMap({ $0 as? HTTPURLResponse })?.statusCode else {
                DispatchQueue.main.async { self.presentRetryError(); self.showIndicator(false) }
                return }

            DispatchQueue.main.async {
                guard statusCode < 400 else {
                    self.presentRetryError()
                    self.navigationItem.rightBarButtonItem = self.saveButton
                    return }

                self.delegate.addSearchEngineViewController(self, name: name, searchTemplate: template)
                Toast(text: UIConstants.strings.NewSearchEngineAdded).show()
                self.navigationController?.popViewController(animated: true)
            }
        }

        dataTask?.resume()
    }

    private func presentRetryError() {
        let controller = UIAlertController(title: UIConstants.strings.addSearchEngineError, message: nil, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: UIConstants.strings.errorTryAgain, style: .default, handler: { _ in

        }))
        self.present(controller, animated: true, completion: nil)
    }

    func showIndicator(_ shouldShow: Bool) {
        guard shouldShow else { self.navigationItem.rightBarButtonItem = self.saveButton; return }

        let indicatorView = UIActivityIndicatorView(style: .white)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: indicatorView)
        indicatorView.startAnimating()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        templatePlaceholderLabel.isHidden = !textView.text.isEmpty
    }
    
    func textViewDidChange(_ textView: UITextView) {
        templatePlaceholderLabel.isHidden = !textView.text.isEmpty
        navigationItem.rightBarButtonItem?.isEnabled = !templateInput.text.isEmpty && !nameInput.text!.isEmpty
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        templatePlaceholderLabel.isHidden = !textView.text.isEmpty
    }
    
    static func isValidTemplate(_ template:String) -> Bool {
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
