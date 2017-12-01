/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol AddSearchEngineDelegate {
    func addSearchEngineViewController(_ addSearchEngineViewController: AddSearchEngineViewController, name: String, searchTemplate: String)
}

class AddSearchEngineViewController: UIViewController, UITextViewDelegate {
    private var delegate: AddSearchEngineDelegate
    
    private let leftMargin = 10
    private let rowHeight = 44
    
    private var nameInput = UITextField()
    private var templateInput = UITextView()
    private var templatePlaceholderLabel = UILabel()
    
    init(delegate: AddSearchEngineDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        title = UIConstants.strings.AddSearchEngineTitle
        
        setupUI()
        setupEvents()
        nameInput.becomeFirstResponder()
    }
    
    private func setupUI() {
        view.backgroundColor = UIConstants.colors.background
        
        let container = UIView()
        view.addSubview(container)
        
        let nameLabel = UILabel()
        nameLabel.text = UIConstants.strings.NameToDisplay
        nameLabel.textColor = UIConstants.colors.settingsTextLabel
        container.addSubview(nameLabel)
        
        nameInput.attributedPlaceholder = NSAttributedString(string: UIConstants.strings.AddSearchEngineName, attributes: [NSAttributedStringKey.foregroundColor: UIConstants.colors.settingsDetailLabel])
        nameInput.backgroundColor = UIConstants.colors.cellSelected
        nameInput.textColor = UIConstants.colors.settingsTextLabel
        nameInput.leftView = UIView(frame: CGRect(x: 0, y: 0, width: leftMargin, height: rowHeight))
        nameInput.leftViewMode = .always
        nameInput.font = UIFont.systemFont(ofSize: 15)
        nameInput.accessibilityIdentifier = "nameInput"
        container.addSubview(nameInput)
        
        let templateLabel = UILabel()
        templateLabel.text = UIConstants.strings.AddSearchEngineTemplate
        templateLabel.textColor = UIConstants.colors.settingsTextLabel
        container.addSubview(templateLabel)
        
        templateInput.backgroundColor = UIConstants.colors.cellSelected
        templateInput.textColor = UIConstants.colors.settingsTextLabel
        templateInput.keyboardType = .URL
        templateInput.font = UIFont.systemFont(ofSize: 15)
        templateInput.contentInset = UIEdgeInsets(top: 5, left: 7, bottom: 7, right: 5)
        templateInput.accessibilityIdentifier = "templateInput"
        container.addSubview(templateInput)

        templatePlaceholderLabel.backgroundColor = UIConstants.colors.cellSelected
        templatePlaceholderLabel.textColor = UIConstants.colors.settingsDetailLabel
        templatePlaceholderLabel.text = UIConstants.strings.AddSearchEngineTemplatePlaceholder
        templatePlaceholderLabel.font = UIFont.systemFont(ofSize: 15)
        templatePlaceholderLabel.numberOfLines = 0
        templateInput.addSubview(templatePlaceholderLabel)

        let exampleLabel = UILabel()
        exampleLabel.text = UIConstants.strings.AddSearchEngineTemplateExample
        exampleLabel.textColor = UIConstants.colors.settingsTextLabel
        exampleLabel.font = UIFont.systemFont(ofSize: 12)
        container.addSubview(exampleLabel)
        
        container.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(20)
            make.height.equalTo(rowHeight)
            make.leftMargin.equalTo(leftMargin)
            make.width.equalToSuperview()
        }
        
        nameInput.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom)
            make.height.equalTo(rowHeight)
            make.width.equalToSuperview()
        }
        
        templateLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameInput.snp.bottom).offset(20)
            make.left.equalTo(leftMargin)
            make.height.equalTo(rowHeight)
        }
        
        templateInput.snp.makeConstraints { (make) in
            make.top.equalTo(templateLabel.snp.bottom)
            make.height.equalTo(88)
            make.width.equalToSuperview()
        }
        
        templatePlaceholderLabel.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalTo(44)
            make.top.equalTo(0)
            make.left.equalTo(3)
        }
        
        exampleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(templateInput.snp.bottom)
            make.width.equalToSuperview()
            make.left.equalTo(leftMargin)
            make.height.equalTo(rowHeight)
        }
    }
    
    private func setupEvents() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: UIConstants.strings.cancel, style: .plain, target: self, action: #selector(AddSearchEngineViewController.cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: UIConstants.strings.Save, style: .plain, target: self, action: #selector(AddSearchEngineViewController.saveTapped))
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "save"
        templateInput.delegate = self
    }
    
    @objc func cancelTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func saveTapped() {
        guard let name = nameInput.text else { return }
        guard let template = templateInput.text else { return }
        
        delegate.addSearchEngineViewController(self, name: name, searchTemplate: template)
        Toast(text: UIConstants.strings.NewSearchEngineAdded).show()
        self.navigationController?.popViewController(animated: true)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        templatePlaceholderLabel.isHidden = !isNullOrEmpty(text: textView.text)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        templatePlaceholderLabel.isHidden = !isNullOrEmpty(text: textView.text)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        templatePlaceholderLabel.isHidden = !isNullOrEmpty(text: textView.text)
    }
    
    private func isNullOrEmpty(text:String?) -> Bool{
        guard let text = text else { return true }
        return text.isEmpty
    }
}
