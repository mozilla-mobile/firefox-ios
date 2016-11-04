/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit

protocol URLBarDelegate: class {
    func urlBar(_ urlBar: URLBar, didEnterText text: String)
    func urlBar(_ urlBar: URLBar, didSubmitText text: String)
    func urlBarDidPressActivateButton(_ urlBar: URLBar)
    func urlBarDidFocus(_ urlBar: URLBar)
    func urlBarDidDismiss(_ urlBar: URLBar)
    func urlBarDidPressDelete(_ urlBar: URLBar)
}

class URLBar: UIView {
    weak var delegate: URLBarDelegate?

    let progressBar = UIProgressView(progressViewStyle: .bar)
    fileprivate(set) var isEditing = false

    fileprivate let buttonContainer = UIView()
    fileprivate let cancelButton = UIButton()
    fileprivate let deleteButton = InsetButton()
    fileprivate let domainCompletion = DomainCompletion()

    private let toolset = BrowserToolset()
    private let urlTextContainer = UIView()
    private let urlText = URLTextField()
    private let lockIcon = UIImageView(image: #imageLiteral(resourceName: "icon_https"))
    private var showButtons = false
    private var isActivated = false

    private var hideButtonContainerConstraint: Constraint!
    private var fullWidthURLTextConstraint: Constraint!
    private var centeredURLConstraint: Constraint!
    private var showSettingsConstraints = [Constraint]()
    private var hideLockConstraints = [Constraint]()
    private var hideToolsetConstraints = [Constraint]()
    private var showToolsetConstraints = [Constraint]()

    init() {
        super.init(frame: CGRect.zero)

        toolset.sendButton.isEnabled = false
        toolset.stopReloadButton.isEnabled = false
        addSubview(toolset.backButton)
        addSubview(toolset.forwardButton)
        addSubview(toolset.stopReloadButton)
        addSubview(toolset.sendButton)
        addSubview(toolset.settingsButton)

        urlTextContainer.backgroundColor = UIConstants.colors.urlTextBackground
        urlTextContainer.layer.cornerRadius = UIConstants.layout.urlBarCornerRadius
        addSubview(urlTextContainer)

        let textAndLockContainer = UIView()
        urlTextContainer.addSubview(textAndLockContainer)

        lockIcon.isHidden = true
        lockIcon.alpha = 0
        lockIcon.contentMode = .center
        lockIcon.setContentCompressionResistancePriority(1000, for: .horizontal)
        lockIcon.setContentHuggingPriority(1000, for: .horizontal)
        textAndLockContainer.addSubview(lockIcon)

        // UITextField doesn't allow customization of the clear button, so we create
        // our own so we can use it as the rightView.
        let clearButton = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        clearButton.isHidden = true
        clearButton.setImage(#imageLiteral(resourceName: "icon_clear"), for: .normal)
        clearButton.addTarget(self, action: #selector(didPressClear), for: .touchUpInside)

        urlText.font = UIConstants.fonts.urlText
        urlText.tintColor = UIConstants.colors.urlTextFont
        urlText.textColor = UIConstants.colors.urlTextFont
        urlText.keyboardType = .webSearch
        urlText.autocapitalizationType = .none
        urlText.autocorrectionType = .no
        urlText.rightView = clearButton
        urlText.rightViewMode = .whileEditing
        urlText.setContentHuggingPriority(1000, for: .vertical)
        urlText.autocompleteDelegate = self
        urlText.source = domainCompletion
        textAndLockContainer.addSubview(urlText)

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
        activateButton.titleLabel?.font = UIConstants.fonts.urlText
        activateButton.setTitleColor(UIConstants.colors.urlTextPlaceholder, for: .normal)
        activateButton.titleEdgeInsets = UIEdgeInsetsMake(0, UIConstants.layout.urlBarWidthInset, 0, UIConstants.layout.urlBarWidthInset)
        activateButton.addTarget(self, action: #selector(didPressActivate), for: .touchUpInside)
        addSubview(activateButton)

        progressBar.isHidden = true
        progressBar.alpha = 0
        progressBar.progressTintColor = UIConstants.colors.progressBar
        addSubview(progressBar)

        // The URL text container is 50% width, so divide the remaining space equally among the buttons.
        let toolsetButtonWidthMultiplier = 0.5 / 6

        toolset.backButton.snp.makeConstraints { make in
            make.leading.centerY.equalTo(self)

            showToolsetConstraints.append(make.width.equalTo(self).multipliedBy(toolsetButtonWidthMultiplier).constraint)

            // Other toolset buttons are set equal to the back button size,
            // so hiding the back button will hide them all.
            hideToolsetConstraints.append(make.size.equalTo(0).constraint)
        }

        toolset.forwardButton.snp.makeConstraints { make in
            make.leading.equalTo(toolset.backButton.snp.trailing)
            make.centerY.equalTo(self)
            make.size.equalTo(toolset.backButton)
        }

        toolset.stopReloadButton.snp.makeConstraints { make in
            make.leading.equalTo(toolset.forwardButton.snp.trailing)
            make.centerY.equalTo(self)
            make.size.equalTo(toolset.backButton)
        }

        urlTextContainer.snp.makeConstraints { make in
            make.leading.equalTo(toolset.stopReloadButton.snp.trailing).inset(-UIConstants.layout.urlBarMargin)
            make.top.bottom.equalTo(self).inset(UIConstants.layout.urlBarMargin)
            make.trailing.equalTo(buttonContainer.snp.leading)
        }

        textAndLockContainer.snp.makeConstraints { make in
            make.top.bottom.equalTo(urlTextContainer)
            make.leading.greaterThanOrEqualTo(urlTextContainer).priority(999)
            make.trailing.lessThanOrEqualTo(urlTextContainer)

            centeredURLConstraint = make.centerX.equalTo(self).constraint
            fullWidthURLTextConstraint = make.leading.trailing.equalTo(urlTextContainer).constraint
        }

        lockIcon.snp.makeConstraints { make in
            make.top.bottom.equalTo(textAndLockContainer)

            make.leading.equalTo(textAndLockContainer).inset(UIConstants.layout.lockIconInset).priority(999)
            make.trailing.equalTo(urlText.snp.leading).inset(-UIConstants.layout.lockIconInset).priority(999)

            hideLockConstraints.append(contentsOf: [
                make.leading.equalTo(textAndLockContainer.snp.leading).constraint,
                make.trailing.equalTo(urlText.snp.leading).constraint,
                make.width.equalTo(0).constraint
            ])
        }

        urlText.snp.makeConstraints { make in
            make.top.bottom.trailing.equalTo(textAndLockContainer)
        }

        buttonContainer.snp.makeConstraints { make in
            make.top.bottom.equalTo(urlTextContainer)

            make.width.greaterThanOrEqualTo(deleteButton).inset(-UIConstants.layout.urlBarMargin).priority(998)
            make.width.greaterThanOrEqualTo(cancelButton).inset(-UIConstants.layout.urlBarMargin).priority(998)
            make.width.greaterThanOrEqualTo(toolset.backButton).priority(998)

            // This will shrink the container to be as small as possible while still meeting the width requirements above.
            make.width.equalTo(0).priority(500)

            // Keep the button container hidden until we start browsing.
            // Set the width equal to the URL bar margin so there's still a gap between the trailing edges...
            hideButtonContainerConstraint = make.width.equalTo(UIConstants.layout.urlBarMargin).priority(999).constraint

            /// ...unless we're showing the Settings button (iPad only).
            if UIDevice.current.userInterfaceIdiom == .pad {
                showSettingsConstraints.append(make.width.equalTo(0).constraint)
            }
        }

        toolset.sendButton.snp.makeConstraints { make in
            make.leading.equalTo(buttonContainer.snp.trailing)
            make.centerY.equalTo(self)
            make.size.equalTo(toolset.backButton)
        }

        toolset.settingsButton.snp.makeConstraints { make in
            make.leading.equalTo(toolset.sendButton.snp.trailing)
            make.centerY.trailing.equalTo(self)

            if UIDevice.current.userInterfaceIdiom == .phone {
                // We don't show the Settings button on phones.
                make.width.equalTo(0)
            } else {
                // Like the other toolset buttons, we usually want this to be equal to the back button size.
                // But there's a one-off state after activation on iPads/landscape where we show Settings
                // with all the other buttons hidden, so we allow this constraint to be overridden.
                make.width.equalTo(toolset.backButton).priority(999)

                // Normally, the Settings button will be equal to the other toolset widths.
                // But there's a one-off state after activation on iPads/landscape where we show Settings
                // with all the other buttons hidden, so we have to set the width manually.
                showSettingsConstraints.append(make.width.equalTo(self).multipliedBy(toolsetButtonWidthMultiplier).constraint)
            }
        }

        deleteButton.snp.makeConstraints { make in
            make.center.equalTo(buttonContainer)
        }

        cancelButton.snp.makeConstraints { make in
            make.center.equalTo(buttonContainer)
        }

        progressBar.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.bottom.equalTo(self).offset(-1)
            make.height.equalTo(1)
        }

        activateButton.snp.makeConstraints { make in
            make.edges.equalTo(urlTextContainer)
        }

        centeredURLConstraint.deactivate()
        showToolsetConstraints.forEach { $0.deactivate() }
        showSettingsConstraints.forEach { $0.deactivate() }
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

    weak var toolsetDelegate: BrowserToolsetDelegate? {
        didSet {
            toolset.delegate = toolsetDelegate
        }
    }

    var canGoBack: Bool = false {
        didSet {
            toolset.canGoBack = canGoBack
        }
    }

    var canGoForward: Bool = false {
        didSet {
            toolset.canGoForward = canGoForward
        }
    }

    var isLoading: Bool = false {
        didSet {
            toolset.isLoading = isLoading
        }
    }

    var showToolset: Bool = false {
        didSet {
            updateToolsetConstraints()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Since the URL text field is smaller and centered on iPads, make sure
        // that touching the surrounding area will trigger editing.
        if let touch = touches.first {
            let point = touch.location(in: urlTextContainer)
            if urlTextContainer.bounds.contains(point) {
                urlText.becomeFirstResponder()
                return
            }
        }

        super.touchesEnded(touches, with: event)
    }

    private func updateLockIcon() {
        let visible = !isEditing && (url?.scheme == "https")
        let duration = UIConstants.layout.urlBarFadeAnimationDuration / 2

        lockIcon.animateHidden(!visible, duration: duration)

        self.layoutIfNeeded()
        UIView.animate(withDuration: duration) {
            if visible {
                self.hideLockConstraints.forEach { $0.deactivate() }
            } else {
                self.hideLockConstraints.forEach { $0.activate() }
            }

            self.layoutIfNeeded()
        }
    }

    fileprivate func present() {
        guard !isEditing else { return }

        isEditing = true
        updateLockIcon()
        toolset.sendButton.isEnabled = false
        delegate?.urlBarDidFocus(self)

        if showButtons {
            cancelButton.animateHidden(false, duration: UIConstants.layout.urlBarFadeAnimationDuration)
            deleteButton.animateHidden(true, duration: UIConstants.layout.urlBarFadeAnimationDuration)
        }

        self.layoutIfNeeded()
        UIView.animate(withDuration: UIConstants.layout.urlBarFadeAnimationDuration) {
            // Show the text field background when editing.
            self.urlTextContainer.backgroundColor = UIConstants.colors.urlTextBackground

            // Hide the URL toolset buttons if we're on iPad/landscape.
            self.updateToolsetConstraints()

            self.layoutIfNeeded()
        }
    }

    @objc func dismiss() {
        guard isEditing else { return }

        isEditing = false
        updateLockIcon()
        urlText.resignFirstResponder()
        setTextToURL()
        self.toolset.sendButton.isEnabled = true
        delegate?.urlBarDidDismiss(self)

        cancelButton.animateHidden(true, duration: UIConstants.layout.urlBarFadeAnimationDuration)
        deleteButton.animateHidden(false, duration: UIConstants.layout.urlBarFadeAnimationDuration)

        self.layoutIfNeeded()
        UIView.animate(withDuration: UIConstants.layout.urlBarFadeAnimationDuration) {
            // Hide the text field background when we're done editing.
            self.urlTextContainer.backgroundColor = nil

            // We don't show Cancel/Erase for the initial URL bar at app launch.
            // If this is the first dismissal, we've entered the browsing state, so show them.
            if !self.showButtons {
                self.showButtons = true
                self.hideButtonContainerConstraint.deactivate()
                self.toolset.stopReloadButton.isEnabled = true
            }

            // Reveal the URL bar buttons on iPad/landscape.
            self.updateToolsetConstraints()

            self.layoutIfNeeded()
        }
    }

    /// Show the URL toolset buttons if we're on iPad/landscape and not editing; hide them otherwise.
    /// This method is intended to be called inside `UIView.animate` block.
    private func updateToolsetConstraints() {
        let isHidden = !showButtons || !showToolset
        toolset.backButton.animateHidden(isHidden, duration: 0.3)
        toolset.forwardButton.animateHidden(isHidden, duration: 0.3)
        toolset.stopReloadButton.animateHidden(isHidden, duration: 0.3)
        toolset.sendButton.animateHidden(isHidden, duration: 0.3)

        // There's a one-off state after activating but before browsing where we want to show
        // the Settings button in the URL bar.
        if isActivated && !showButtons && showToolset {
            showSettingsConstraints.forEach { $0.activate() }
        } else {
            showSettingsConstraints.forEach { $0.deactivate() }
        }
        toolset.settingsButton.animateHidden(!showToolset, duration: 0.3)

        if isHidden {
            centeredURLConstraint.deactivate()
            showToolsetConstraints.forEach { $0.deactivate() }
            hideToolsetConstraints.forEach { $0.activate() }
            fullWidthURLTextConstraint.activate()
        } else {
            hideToolsetConstraints.forEach { $0.deactivate() }
            showToolsetConstraints.forEach { $0.activate() }

            // If we're editing, stretch the text field to the full width of its container.
            // Otherwise it will size to fit, allowing it to be centered in the container.
            if isEditing {
                centeredURLConstraint.deactivate()
                fullWidthURLTextConstraint.activate()
            } else {
                fullWidthURLTextConstraint.deactivate()
                centeredURLConstraint.activate()
            }
        }
    }

    @objc private func didPressDelete() {
        delegate?.urlBarDidPressDelete(self)
    }

    @objc private func didPressClear() {
        urlText.text = nil
        urlText.rightView?.isHidden = true
        delegate?.urlBar(self, didEnterText: "")
    }

    @objc private func didPressActivate(_ button: UIButton) {
        isActivated = true

        UIView.animate(withDuration: UIConstants.layout.urlBarMoveToTopAnimationDuration, animations: {
            button.contentHorizontalAlignment = .left
            self.layoutIfNeeded()
        }, completion: { finished in
            self.urlText.placeholder = UIConstants.strings.urlTextPlaceholder
            button.removeFromSuperview()
        })

        self.urlText.becomeFirstResponder()
        delegate?.urlBarDidPressActivateButton(self)
    }

    fileprivate func setTextToURL() {
        urlText.text = url?.absoluteString ?? nil
    }
}

extension URLBar: AutocompleteTextFieldDelegate {
    func autocompleteTextFieldShouldBeginEditing(_ autocompleteTextField: AutocompleteTextField) -> Bool {
        present()
        autocompleteTextField.highlightAll()
        return true
    }

    func autocompleteTextFieldShouldReturn(_ autocompleteTextField: AutocompleteTextField) -> Bool {
        delegate?.urlBar(self, didSubmitText: autocompleteTextField.text ?? "")
        return true
    }

    func autocompleteTextField(_ autocompleteTextField: AutocompleteTextField, didTextChange text: String) {
        autocompleteTextField.rightView?.isHidden = text.isEmpty
        delegate?.urlBar(self, didEnterText: text)
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

    override fileprivate func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        return super.rightViewRect(forBounds: bounds).offsetBy(dx: -UIConstants.layout.urlBarWidthInset, dy: 0)
    }
}
