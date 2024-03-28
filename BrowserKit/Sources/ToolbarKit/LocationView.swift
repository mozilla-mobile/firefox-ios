// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol LocationViewDelegate: AnyObject {
    func locationViewDidEnterText(_ text: String)
    func locationViewDidBeginEditing(_ text: String)
    func locationViewShouldSearchFor(_ text: String)
}

class LocationView: UIView, UITextFieldDelegate {
    private enum UX {
        static let horizontalSpace: CGFloat = 16
    }

    private var notifyTextChanged: (() -> Void)?
    private var locationViewDelegate: LocationViewDelegate?

    private lazy var urlTextField: UITextField = .build { urlTextField in
        urlTextField.accessibilityIdentifier = "url"
        urlTextField.backgroundColor = .clear
        urlTextField.font = UIFont.preferredFont(forTextStyle: .body)
        urlTextField.adjustsFontForContentSizeCategory = true
        urlTextField.delegate = self
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()

        urlTextField.addTarget(self, action: #selector(LocationView.textDidChange), for: .editingChanged)
        notifyTextChanged = { [self] in
            guard urlTextField.isEditing else { return }

            urlTextField.text = urlTextField.text?.lowercased()
            locationViewDelegate?.locationViewDidEnterText(urlTextField.text?.lowercased() ?? "")
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        return urlTextField.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        return urlTextField.resignFirstResponder()
    }

    func configure(_ text: String?, delegate: LocationViewDelegate) {
        urlTextField.text = text
        locationViewDelegate = delegate
    }

    private func setupLayout() {
        addSubview(urlTextField)

        NSLayoutConstraint.activate([
            urlTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.horizontalSpace),
            urlTextField.topAnchor.constraint(equalTo: topAnchor),
            urlTextField.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -UX.horizontalSpace),
            urlTextField.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @objc
    func textDidChange(_ textField: UITextField) {
        notifyTextChanged?()
    }

    // MARK: - UITextFieldDelegate
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        locationViewDelegate?.locationViewDidBeginEditing(textField.text?.lowercased() ?? "")
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let searchText = textField.text?.lowercased(), !searchText.isEmpty else { return false }

        locationViewDelegate?.locationViewShouldSearchFor(searchText)
        textField.resignFirstResponder()
        return true
    }
}
