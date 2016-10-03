/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol URLBarDelegate: class {
    func urlBar(urlBar: URLBar, didSubmitText text: String)
}

class URLBar: UIView, UITextFieldDelegate {
    weak var delegate: URLBarDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let urlText = URLTextField()
        urlText.font = UIConstants.fonts.urlTextFont
        urlText.textColor = UIConstants.colors.urlTextFont
        urlText.layer.cornerRadius = UIConstants.layout.urlTextCornerRadius
        urlText.backgroundColor = UIConstants.colors.urlTextBackground
        urlText.placeholder = UIConstants.strings.urlTextPlaceholder
        urlText.keyboardType = .webSearch
        urlText.autocapitalizationType = .none
        urlText.delegate = self

        addSubview(urlText)
        urlText.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalTo(self).inset(UIConstants.layout.urlBarInset)
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.urlBar(urlBar: self, didSubmitText: textField.text!)
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
        return bounds.insetBy(dx: 8, dy: 8)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 8, dy: 8)
    }
}
