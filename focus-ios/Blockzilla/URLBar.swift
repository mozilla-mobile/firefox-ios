/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit

protocol URLBarDelegate: class {
    func urlBar(urlBar: URLBar, didEnterText text: String)
    func urlBar(urlBar: URLBar, didSubmitText text: String)
    func urlBarDidPressActivateButton(urlBar: URLBar)
    func urlBarDidFocus(urlBar: URLBar)
    func urlBarDidDismiss(urlBar: URLBar)
    func urlBarDidPressDelete(urlBar: URLBar)
}

class URLBar: UIView {
    weak var delegate: URLBarDelegate?

    let progressBar = UIProgressView(progressViewStyle: .bar)

    fileprivate let cancelButton = InsetButton()
    fileprivate var cancelButtonWidthConstraint: Constraint!
    fileprivate let deleteButton = InsetButton()
    fileprivate let domainCompletion = DomainCompletion()

    fileprivate var isEditing = false
    fileprivate var deleteButtonWidthConstraint: Constraint!
    fileprivate var deleteButtonTrailingConstraint: Constraint!

    private let urlTextContainer = UIView()
    private let urlText = URLTextField()

    init() {
        super.init(frame: CGRect.zero)

        urlTextContainer.backgroundColor = UIConstants.colors.urlTextBackground
        urlTextContainer.layer.cornerRadius = UIConstants.layout.urlBarCornerRadius

        // UITextField doesn't allow customization of the clear button, so we create
        // our own so we can use it as the rightView.
        let clearButton = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        clearButton.isHidden = true
        clearButton.setImage(#imageLiteral(resourceName: "icon_clear"), for: .normal)
        clearButton.addTarget(self, action: #selector(didPressClear), for: .touchUpInside)

        urlText.font = UIConstants.fonts.urlTextFont
        urlText.tintColor = UIConstants.colors.urlTextFont
        urlText.textColor = UIConstants.colors.urlTextFont
        urlText.keyboardType = .webSearch
        urlText.autocapitalizationType = .none
        urlText.autocorrectionType = .no
        urlText.rightView = clearButton
        urlText.rightViewMode = .whileEditing
        urlText.setContentHuggingPriority(1000, for: .vertical)
        urlText.autocompleteDelegate = self

        cancelButton.setTitle(UIConstants.strings.urlBarCancel, for: .normal)
        cancelButton.titleLabel?.font = UIConstants.fonts.cancelButton
        cancelButton.titleEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        cancelButton.setContentHuggingPriority(1000, for: .horizontal)
        cancelButton.setContentCompressionResistancePriority(1000, for: .horizontal)
        cancelButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)

        deleteButton.setTitle(UIConstants.strings.clearButton, for: .normal)
        deleteButton.titleLabel?.font = UIConstants.fonts.deleteButton
        deleteButton.titleEdgeInsets = UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 10)
        deleteButton.backgroundColor = UIColor.lightGray
        deleteButton.layer.borderWidth = 1
        deleteButton.layer.cornerRadius = 2
        deleteButton.layer.borderColor = UIConstants.colors.deleteButtonBorder.cgColor
        deleteButton.layer.backgroundColor = UIConstants.colors.deleteButtonBackgroundNormal.cgColor
        deleteButton.setContentHuggingPriority(1000, for: .horizontal)
        deleteButton.setContentCompressionResistancePriority(1000, for: .horizontal)
        deleteButton.addTarget(self, action: #selector(didPressDelete), for: .touchUpInside)

        addSubview(urlTextContainer)
        urlTextContainer.addSubview(urlText)
        urlTextContainer.addSubview(deleteButton)
        addSubview(cancelButton)

        let activateButton = UIButton()
        activateButton.setTitle(UIConstants.strings.urlTextPlaceholder, for: .normal)
        activateButton.titleLabel?.font = UIConstants.fonts.urlTextFont
        activateButton.setTitleColor(UIConstants.colors.urlTextPlaceholder, for: .normal)
        activateButton.titleEdgeInsets = UIEdgeInsetsMake(0, UIConstants.layout.urlBarWidthInset, 0, 0)
        activateButton.addTarget(self, action: #selector(didPressActivate), for: .touchUpInside)
        addSubview(activateButton)

        progressBar.isHidden = true
        progressBar.alpha = 0
        progressBar.progressTintColor = UIConstants.colors.progressBar
        addSubview(progressBar)

        urlTextContainer.snp.makeConstraints { make in
            make.top.leading.bottom.equalTo(self).inset(UIConstants.layout.urlBarMargin)

            // Two required constraints.
            make.trailing.lessThanOrEqualTo(cancelButton.snp.leading)
            make.trailing.lessThanOrEqualTo(self).inset(UIConstants.layout.urlBarMargin)

            // Because of the two required constraints above, the first optional constraint
            // here will fail if the Cancel button has 0 width; the second will fail if the
            // Cancel button is visible. As a result, only one of these two constraints will
            // be in effect at a time.
            make.trailing.equalTo(cancelButton.snp.leading).priority(500)
            make.trailing.equalTo(self).priority(500)
        }

        urlText.snp.makeConstraints { make in
            make.leading.top.bottom.equalTo(urlTextContainer)
        }

        activateButton.snp.makeConstraints { make in
            make.edges.equalTo(urlTextContainer)
        }

        deleteButton.snp.makeConstraints { make in
            make.leading.equalTo(urlText.snp.trailing)
            make.centerY.equalTo(urlTextContainer)
            self.deleteButtonTrailingConstraint = make.trailing.equalTo(urlTextContainer).constraint
            self.deleteButtonWidthConstraint = make.size.equalTo(0).constraint
        }

        cancelButton.snp.makeConstraints { make in
            make.trailing.equalTo(self)
            make.centerY.equalTo(urlText)
            self.cancelButtonWidthConstraint = make.size.equalTo(0).constraint
        }

        progressBar.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.bottom.equalTo(self).offset(-1)
            make.height.equalTo(1)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var url: URL? = nil {
        didSet {
            if !urlText.isEditing {
                setTextToURL()
            }
        }
    }

    var showButtons = false

    fileprivate func activate() {
        guard !isEditing else { return }

        isEditing = true

        urlText.highlightAll()
        delegate?.urlBarDidFocus(urlBar: self)

        guard showButtons else { return }

        self.layoutIfNeeded()
        UIView.animate(withDuration: 0.3) {
            self.cancelButton.alpha = 1
            self.cancelButtonWidthConstraint.deactivate()

            self.deleteButton.alpha = 0
            self.deleteButtonWidthConstraint.activate()

            self.deleteButtonTrailingConstraint.update(offset: 0)

            self.layoutIfNeeded()
        }
    }

    @objc func dismiss() {
        guard isEditing else { return }

        isEditing = false
        urlText.resignFirstResponder()
        setTextToURL()
        delegate?.urlBarDidDismiss(urlBar: self)

        guard showButtons else { return }

        self.layoutIfNeeded()
        UIView.animate(withDuration: 0.3) {
            self.cancelButton.alpha = 0
            self.cancelButtonWidthConstraint.activate()

            self.deleteButton.alpha = 1
            self.deleteButtonWidthConstraint.deactivate()
            self.deleteButtonTrailingConstraint.update(offset: -5)

            self.layoutIfNeeded()
        }
    }

    @objc private func didPressDelete() {
        delegate?.urlBarDidPressDelete(urlBar: self)
    }

    @objc private func didPressClear() {
        urlText.clear()
    }

    @objc private func didPressActivate(_ button: UIButton) {
        UIView.animate(withDuration: UIConstants.layout.urlBarMoveToTopAnimationDuration, animations: {
            button.contentHorizontalAlignment = .left
            self.layoutIfNeeded()
        }, completion: { finished in
            self.urlText.placeholder = UIConstants.strings.urlTextPlaceholder
            button.removeFromSuperview()
        })

        self.urlText.becomeFirstResponder()
        delegate?.urlBarDidPressActivateButton(urlBar: self)
    }

    fileprivate func setTextToURL() {
        urlText.text = url?.absoluteString ?? nil
    }
}

extension URLBar: AutocompleteTextFieldDelegate {
    func autocompleteTextFieldShouldBeginEditing(_ autocompleteTextField: AutocompleteTextField) -> Bool {
        activate()
        return true
    }

    func autocompleteTextFieldShouldEndEditing(_ autocompleteTextField: AutocompleteTextField) -> Bool {
        return true
    }

    func autocompleteTextFieldShouldReturn(_ autocompleteTextField: AutocompleteTextField) -> Bool {
        delegate?.urlBar(urlBar: self, didSubmitText: autocompleteTextField.text!)
        return true
    }

    func autocompleteTextField(_ autocompleteTextField: AutocompleteTextField, didEnterText text: String) {
        let completion = domainCompletion.completion(forText: text)
        autocompleteTextField.setAutocompleteSuggestion(completion)
        autocompleteTextField.rightView?.isHidden = text.isEmpty
        delegate?.urlBar(urlBar: self, didEnterText: text)
    }
}

private class URLTextField: AutocompleteTextField {
    override var placeholder: String? {
        didSet {
            attributedPlaceholder = NSAttributedString(string: placeholder!, attributes: [NSForegroundColorAttributeName: UIConstants.colors.urlTextPlaceholder])
        }
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return getInsetRect(forBounds: bounds)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return getInsetRect(forBounds: bounds)
    }

    private func getInsetRect(forBounds bounds: CGRect) -> CGRect {
        // Add internal padding.
        let inset = bounds.insetBy(dx: UIConstants.layout.urlBarWidthInset, dy: UIConstants.layout.urlBarHeightInset)

        // Add a right margin so we don't overlap with the clear button.
        var clearButtonWidth: CGFloat = 0
        if let clearButton = rightView, isEditing {
            clearButtonWidth = clearButton.bounds.width + CGFloat(5)
        }

        return CGRect(x: inset.origin.x, y: inset.origin.y, width: inset.width - clearButtonWidth, height: inset.height)
    }

    override private func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        return super.rightViewRect(forBounds: bounds).offsetBy(dx: -UIConstants.layout.urlBarWidthInset, dy: 0)
    }
}
