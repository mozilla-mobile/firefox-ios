/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit

protocol URLBarDelegate: class {
    func urlBar(urlBar: URLBar, didSubmitText text: String)
    func urlBarDidCancel(urlBar: URLBar)
}

class URLBar: UIView {
    weak var delegate: URLBarDelegate?

    private let urlText = URLTextField()
    private let cancelButton = InsetButton()
    fileprivate var cancelButtonWidthConstraint: Constraint!

    init() {
        super.init(frame: CGRect.zero)

        urlText.font = UIConstants.fonts.urlTextFont
        urlText.textColor = UIConstants.colors.urlTextFont
        urlText.layer.cornerRadius = UIConstants.layout.urlTextCornerRadius
        urlText.backgroundColor = UIConstants.colors.urlTextBackground
        urlText.placeholder = UIConstants.strings.urlTextPlaceholder
        urlText.keyboardType = .webSearch
        urlText.autocapitalizationType = .none
        urlText.autocorrectionType = .no
        urlText.delegate = self

        cancelButton.setTitle(UIConstants.strings.urlBarCancel, for: .normal)
        cancelButton.titleLabel?.font = UIConstants.fonts.smallerFont
        cancelButton.titleEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        cancelButton.addTarget(self, action: #selector(didCancel), for: .touchUpInside)

        addSubview(urlText)
        urlText.snp.makeConstraints { make in
            make.top.leading.bottom.equalTo(self).inset(UIConstants.layout.urlBarMargin)
            make.trailing.lessThanOrEqualTo(self).inset(UIConstants.layout.urlBarMargin)
        }

        addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.leading.equalTo(urlText.snp.trailing).priority(500)
            make.trailing.equalTo(self)
            make.centerY.equalTo(urlText)
            self.cancelButtonWidthConstraint = make.width.equalTo(0).constraint
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var text: String? {
        get {
            return urlText.text
        }

        set {
            urlText.text = newValue
        }
    }

    @objc private func didCancel() {
        urlText.resignFirstResponder()
        delegate?.urlBarDidCancel(urlBar: self)
    }

    func focus() {
        urlText.becomeFirstResponder()
    }
}

extension URLBar: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        cancelButtonWidthConstraint.deactivate()
        textField.selectAll(nil)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        cancelButtonWidthConstraint.activate()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.urlBar(urlBar: self, didSubmitText: textField.text!)
        textField.resignFirstResponder()
        return true
    }
}

private class URLTextField: UITextField {
    override var placeholder: String? {
        didSet {
            attributedPlaceholder = NSAttributedString(string: placeholder!, attributes: [NSForegroundColorAttributeName: UIConstants.colors.urlTextPlaceholder])
        }
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: UIConstants.layout.urlBarWidthInset, dy: UIConstants.layout.urlBarHeightInset)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: UIConstants.layout.urlBarWidthInset, dy: UIConstants.layout.urlBarHeightInset)
    }
}
