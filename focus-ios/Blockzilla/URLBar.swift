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
    fileprivate(set) var isEditing = false

    fileprivate let buttonContainer = UIView()
    fileprivate let cancelButton = UIButton()
    fileprivate let deleteButton = InsetButton()
    fileprivate let domainCompletion = DomainCompletion()

    private let urlTextContainer = UIView()
    private let urlText = URLTextField()
    private let lockIcon = UIImageView(image: #imageLiteral(resourceName: "icon_https"))
    private var showButtons = false
    private var deleteButtonSizeConstraint: Constraint!
    private var urlTextContainerConstraint: Constraint!
    private var hideLockConstraints = [Constraint]()

    init() {
        super.init(frame: CGRect.zero)

        urlTextContainer.backgroundColor = UIConstants.colors.urlTextBackground
        urlTextContainer.layer.cornerRadius = UIConstants.layout.urlBarCornerRadius
        addSubview(urlTextContainer)

        lockIcon.isHidden = true
        lockIcon.alpha = 0
        lockIcon.contentMode = .center
        lockIcon.setContentCompressionResistancePriority(1000, for: .horizontal)
        lockIcon.setContentHuggingPriority(1000, for: .horizontal)
        urlTextContainer.addSubview(lockIcon)

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
        urlTextContainer.addSubview(urlText)

        addSubview(buttonContainer)

        cancelButton.isHidden = true
        cancelButton.alpha = 0
        cancelButton.setTitle(UIConstants.strings.urlBarCancel, for: .normal)
        cancelButton.titleLabel?.font = UIConstants.fonts.cancelButton
        cancelButton.setContentHuggingPriority(1000, for: .horizontal)
        cancelButton.setContentCompressionResistancePriority(1000, for: .horizontal)
        cancelButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        buttonContainer.addSubview(cancelButton)

        deleteButton.isHidden = true
        deleteButton.alpha = 0
        deleteButton.setTitle(UIConstants.strings.eraseButton, for: .normal)
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
        buttonContainer.addSubview(deleteButton)

        let activateButton = UIButton()
        activateButton.setTitle(UIConstants.strings.urlTextPlaceholder, for: .normal)
        activateButton.titleLabel?.font = UIConstants.fonts.urlTextFont
        activateButton.setTitleColor(UIConstants.colors.urlTextPlaceholder, for: .normal)
        activateButton.titleEdgeInsets = UIEdgeInsetsMake(0, UIConstants.layout.urlBarWidthInset, 0, UIConstants.layout.urlBarWidthInset)
        activateButton.addTarget(self, action: #selector(didPressActivate), for: .touchUpInside)
        addSubview(activateButton)

        progressBar.isHidden = true
        progressBar.alpha = 0
        progressBar.progressTintColor = UIConstants.colors.progressBar
        addSubview(progressBar)

        urlTextContainer.snp.makeConstraints { make in
            make.top.leading.bottom.equalTo(self).inset(UIConstants.layout.urlBarMargin)

            make.trailing.equalTo(buttonContainer.snp.leading).priority(999)

            // This makes the URL bar stretch across the screen, which overrides the above trailing constraint.
            // We deactivate this when making the first navigation, which in turn activates the above constraint.
            urlTextContainerConstraint = make.trailing.equalTo(self).inset(UIConstants.layout.urlBarMargin).constraint
        }

        buttonContainer.snp.makeConstraints { make in
            make.trailing.equalTo(self)
            make.top.bottom.equalTo(urlTextContainer)

            make.width.greaterThanOrEqualTo(deleteButton).inset(-UIConstants.layout.urlBarMargin)
            make.width.greaterThanOrEqualTo(cancelButton).inset(-UIConstants.layout.urlBarMargin)

            // This will shrink the container to be as small as possible.
            make.width.equalTo(0).priority(500)
        }

        lockIcon.snp.makeConstraints { make in
            make.top.bottom.equalTo(urlTextContainer)

            make.leading.equalTo(urlTextContainer).inset(UIConstants.layout.lockIconInset).priority(999)
            make.trailing.equalTo(urlText.snp.leading).inset(-UIConstants.layout.lockIconInset).priority(999)

            hideLockConstraints = [
                make.leading.equalTo(urlTextContainer.snp.leading).constraint,
                make.trailing.equalTo(urlText.snp.leading).constraint,
                make.width.equalTo(0).constraint
            ]
        }

        urlText.snp.makeConstraints { make in
            make.top.bottom.trailing.equalTo(urlTextContainer)
        }

        activateButton.snp.makeConstraints { make in
            make.edges.equalTo(urlTextContainer)
        }

        deleteButton.snp.makeConstraints { make in
            make.center.equalTo(buttonContainer)

            deleteButtonSizeConstraint = make.size.equalTo(0).constraint
        }

        cancelButton.snp.makeConstraints { make in
            make.center.equalTo(buttonContainer)
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
                updateLockIcon()
            }
        }
    }

    private func updateLockIcon() {
        let visible = !isEditing && (url?.scheme == "https")
        lockIcon.animateHidden(!visible, duration: 0.3)

        self.layoutIfNeeded()
        UIView.animate(withDuration: 0.3) {
            if visible {
                self.hideLockConstraints.forEach { $0.deactivate() }
            } else {
                self.hideLockConstraints.forEach { $0.activate() }
            }

            self.layoutIfNeeded()
        }
    }

    fileprivate func activate() {
        guard !isEditing else { return }

        isEditing = true

        urlText.highlightAll()
        delegate?.urlBarDidFocus(urlBar: self)

        updateLockIcon()

        guard showButtons else { return }

        cancelButton.animateHidden(false, duration: UIConstants.layout.urlBarFadeAnimationDuration)
        deleteButton.animateHidden(true, duration: UIConstants.layout.urlBarFadeAnimationDuration)

        self.layoutIfNeeded()
        UIView.animate(withDuration: UIConstants.layout.urlBarFadeAnimationDuration) {
            self.urlTextContainer.backgroundColor = UIConstants.colors.urlTextBackground
            self.layoutIfNeeded()
        }
    }

    @objc func dismiss() {
        guard isEditing else { return }

        isEditing = false
        urlText.resignFirstResponder()
        setTextToURL()
        delegate?.urlBarDidDismiss(urlBar: self)

        updateLockIcon()

        cancelButton.animateHidden(true, duration: UIConstants.layout.urlBarFadeAnimationDuration)
        deleteButton.animateHidden(false, duration: UIConstants.layout.urlBarFadeAnimationDuration)

        self.layoutIfNeeded()
        UIView.animate(withDuration: UIConstants.layout.urlBarFadeAnimationDuration) {
            self.urlTextContainer.backgroundColor = nil

            if !self.showButtons {
                self.showButtons = true
                self.urlTextContainerConstraint.deactivate()
                self.deleteButtonSizeConstraint.deactivate()
            }

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
