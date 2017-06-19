/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AutocompleteTextField
import SnapKit

protocol URLBarDelegate: class {
    func urlBar(_ urlBar: URLBar, didEnterText text: String)
    func urlBar(_ urlBar: URLBar, didSubmitText text: String)
    func urlBarDidActivate(_ urlBar: URLBar)
    func urlBarDidDeactivate(_ urlBar: URLBar)
    func urlBarDidFocus(_ urlBar: URLBar)
    func urlBarDidDismiss(_ urlBar: URLBar)
    func urlBarDidPressDelete(_ urlBar: URLBar)
}

class URLBar: UIView {
    weak var delegate: URLBarDelegate?

    let progressBar = UIProgressView(progressViewStyle: .bar)
    var inBrowsingMode: Bool = false
    fileprivate(set) var isEditing = false

    fileprivate let cancelButton = InsetButton()
    fileprivate let deleteButton = InsetButton()
    fileprivate let domainCompletion = DomainCompletion()
    fileprivate let activateButton = UIButton()

    private let toolset = BrowserToolset()
    private let urlTextContainer = UIView()
    private let urlText = URLTextField()
    private let lockIcon = UIImageView(image: #imageLiteral(resourceName: "icon_https"))
    private let urlBarBackgroundView = UIView()

    private var fullWidthURLTextConstraints = [Constraint]()
    private var centeredURLConstraints = [Constraint]()
    private var hideLockConstraints = [Constraint]()
    private var hideToolsetConstraints = [Constraint]()
    private var showToolsetConstraints = [Constraint]()
    private var isEditingConstraints = [Constraint]()
    private var preActivationConstraints = [Constraint]()
    private var postActivationConstraints = [Constraint]()
    
    let menuController = UIMenuController.shared

    init() {
        super.init(frame: CGRect.zero)

        addSubview(toolset.backButton)
        addSubview(toolset.forwardButton)
        addSubview(toolset.stopReloadButton)
        addSubview(toolset.sendButton)

        urlBarBackgroundView.backgroundColor = UIConstants.colors.urlTextBackground
        urlBarBackgroundView.layer.cornerRadius = UIConstants.layout.urlBarCornerRadius
        addSubview(urlBarBackgroundView)

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

        urlText.isUserInteractionEnabled = false
        urlText.font = UIConstants.fonts.urlText
        urlText.tintColor = UIConstants.colors.urlTextFont
        urlText.textColor = UIConstants.colors.urlTextFont
        urlText.highlightColor = UIConstants.colors.urlTextHighlight
        urlText.keyboardType = .webSearch
        urlText.autocapitalizationType = .none
        urlText.autocorrectionType = .no
        urlText.rightView = clearButton
        urlText.rightViewMode = .whileEditing
        urlText.setContentHuggingPriority(1000, for: .vertical)
        urlText.autocompleteDelegate = self
        urlText.completionSource = domainCompletion
        urlText.accessibilityIdentifier = "URLBar.urlText"
        textAndLockContainer.addSubview(urlText)

        cancelButton.isHidden = true
        cancelButton.alpha = 0
        cancelButton.setTitle(UIConstants.strings.urlBarCancel, for: .normal)
        cancelButton.titleLabel?.font = UIConstants.fonts.cancelButton
        cancelButton.setContentHuggingPriority(1000, for: .horizontal)
        cancelButton.setContentCompressionResistancePriority(1000, for: .horizontal)
        cancelButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        addSubview(cancelButton)

        deleteButton.isHidden = true
        deleteButton.alpha = 0
        deleteButton.setTitle(UIConstants.strings.eraseButton, for: .normal)
        deleteButton.titleLabel?.font = UIConstants.fonts.deleteButton
        deleteButton.titleEdgeInsets = UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 10)
        deleteButton.backgroundColor = UIConstants.colors.deleteButtonBackground
        deleteButton.layer.borderWidth = 1
        deleteButton.layer.cornerRadius = 2
        deleteButton.layer.borderColor = UIConstants.colors.deleteButtonBorder.cgColor
        deleteButton.setContentHuggingPriority(1000, for: .horizontal)
        deleteButton.setContentCompressionResistancePriority(1000, for: .horizontal)
        deleteButton.addTarget(self, action: #selector(didPressDelete), for: .touchUpInside)
        deleteButton.accessibilityIdentifier = "URLBar.deleteButton"
        addSubview(deleteButton)

        let buttonContainer = UIView()
        addSubview(buttonContainer)

        // Create an invisible clone of the Erase button, with the same size.
        // This will allow the button container to hold its shape when we shrink the button.
        let hiddenDeleteButton = UIButton()
        hiddenDeleteButton.isUserInteractionEnabled = false
        hiddenDeleteButton.isHidden = true
        hiddenDeleteButton.setTitle(UIConstants.strings.eraseButton, for: .normal)
        hiddenDeleteButton.titleLabel?.font = UIConstants.fonts.deleteButton
        hiddenDeleteButton.setContentHuggingPriority(1000, for: .horizontal)
        hiddenDeleteButton.setContentCompressionResistancePriority(1000, for: .horizontal)
        addSubview(hiddenDeleteButton)

        activateButton.setTitle(UIConstants.strings.urlTextPlaceholder, for: .normal)
        activateButton.titleLabel?.font = UIConstants.fonts.urlText
        activateButton.setTitleColor(UIConstants.colors.urlTextPlaceholder, for: .normal)
        activateButton.titleEdgeInsets = UIEdgeInsetsMake(0, UIConstants.layout.urlBarWidthInset, 0, UIConstants.layout.urlBarWidthInset)
        activateButton.addTarget(self, action: #selector(didPressActivate), for: .touchUpInside)
        activateButton.accessibilityIdentifier = "URLBar.activateButton"
        addSubview(activateButton)

        progressBar.isHidden = true
        progressBar.alpha = 0
        progressBar.progressTintColor = UIConstants.colors.progressBar
        addSubview(progressBar)

        let toolsetButtonWidthMultiplier = 0.08

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

        urlBarBackgroundView.snp.makeConstraints { make in
            make.edges.equalTo(urlTextContainer)
        }

        urlTextContainer.snp.makeConstraints { make in
            make.leading.equalTo(toolset.stopReloadButton.snp.trailing).inset(-UIConstants.layout.urlBarMargin)
            make.top.bottom.equalTo(self).inset(UIConstants.layout.urlBarMargin)

            // Stretch the URL bar as much as we can without breaking constraints.
            make.width.equalTo(self).priority(500)
        }

        textAndLockContainer.snp.makeConstraints { make in
            make.top.bottom.equalTo(urlTextContainer)
            make.leading.greaterThanOrEqualTo(urlTextContainer).priority(999)
            make.trailing.lessThanOrEqualTo(urlTextContainer)

            centeredURLConstraints.append(make.centerX.equalTo(self).constraint)
            fullWidthURLTextConstraints.append(make.leading.trailing.equalTo(urlTextContainer).constraint)
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

        toolset.sendButton.snp.makeConstraints { make in
            make.centerY.trailing.equalTo(self)
            make.size.equalTo(toolset.backButton)
        }

        buttonContainer.snp.makeConstraints { make in
            make.centerY.equalTo(self)

            preActivationConstraints.append(contentsOf: [
                make.size.equalTo(0).constraint,
                make.leading.equalTo(urlTextContainer.snp.trailing).inset(-UIConstants.layout.urlBarMargin).constraint,
                make.trailing.equalTo(toolset.sendButton.snp.leading).constraint,
            ])

            postActivationConstraints.append(contentsOf: [
                make.width.greaterThanOrEqualTo(hiddenDeleteButton).constraint,
                make.width.greaterThanOrEqualTo(cancelButton).constraint,
                make.width.greaterThanOrEqualTo(self).multipliedBy(toolsetButtonWidthMultiplier).constraint,
                make.leading.equalTo(urlTextContainer.snp.trailing).inset(-12).constraint,
                make.trailing.equalTo(toolset.sendButton.snp.leading).inset(-12).constraint,
            ])
        }

        deleteButton.snp.makeConstraints { make in
            make.center.equalTo(buttonContainer)
            isEditingConstraints.append(make.size.equalTo(0).constraint)
        }

        hiddenDeleteButton.snp.makeConstraints { make in
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

        centeredURLConstraints.forEach { $0.deactivate() }
        showToolsetConstraints.forEach { $0.deactivate() }
        postActivationConstraints.forEach { $0.deactivate() }
        
        addCustomMenu()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func pasteAndGo() {
        delegate?.urlBar(self, didSubmitText: UIPasteboard.general.string!)
    }
    //Adds Menu Item
    func addCustomMenu() {
        let lookupMenu = UIMenuItem(title: "Paste & Go", action: #selector(pasteAndGo))
        UIMenuController.shared.menuItems = [lookupMenu]
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

    /// The outer view the URL bar will shrink from/to when transitioning to/from edit mode.
    weak var shrinkFromView: UIView?

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
        let duration = UIConstants.layout.urlBarTransitionAnimationDuration / 2

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

        cancelButton.animateHidden(false, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
        deleteButton.animateHidden(true, duration: UIConstants.layout.urlBarTransitionAnimationDuration)

        self.layoutIfNeeded()
        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration) {
            // Hide the URL toolset buttons if we're on iPad/landscape.
            self.updateToolsetConstraints()

            if self.inBrowsingMode {
                self.isEditingConstraints.forEach { $0.activate() }

                // Shrink the URL text background in from the outer URL bar.
                self.urlBarBackgroundView.alpha = 1
                self.urlBarBackgroundView.snp.remakeConstraints { make in
                    make.edges.equalTo(self.urlTextContainer)
                }
            }

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

        cancelButton.animateHidden(true, duration: UIConstants.layout.urlBarTransitionAnimationDuration)

        if inBrowsingMode {
            deleteButton.animateHidden(false, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
        } else {
            deactivate()
        }

        self.layoutIfNeeded()
        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration) {
            self.isEditingConstraints.forEach { $0.deactivate() }

            if self.inBrowsingMode {
                // Reveal the URL bar buttons on iPad/landscape.
                self.updateToolsetConstraints()

                // Expand the URL text background to the outer URL bar.
                self.urlBarBackgroundView.alpha = 0
                self.urlBarBackgroundView.snp.remakeConstraints { make in
                    make.edges.equalTo(self.shrinkFromView ?? 0)
                }
            }

            self.layoutIfNeeded()
        }
    }

    /// Show the URL toolset buttons if we're on iPad/landscape and not editing; hide them otherwise.
    /// This method is intended to be called inside `UIView.animate` block.
    private func updateToolsetConstraints() {
        let isHidden = !inBrowsingMode || !showToolset
        toolset.backButton.animateHidden(isHidden, duration: 0.3)
        toolset.forwardButton.animateHidden(isHidden, duration: 0.3)
        toolset.stopReloadButton.animateHidden(isHidden, duration: 0.3)
        toolset.sendButton.animateHidden(isHidden, duration: 0.3)

        if isHidden {
            centeredURLConstraints.forEach { $0.deactivate() }
            showToolsetConstraints.forEach { $0.deactivate() }
            hideToolsetConstraints.forEach { $0.activate() }
            fullWidthURLTextConstraints.forEach { $0.activate() }
        } else {
            hideToolsetConstraints.forEach { $0.deactivate() }
            showToolsetConstraints.forEach { $0.activate() }

            // If we're editing, stretch the text field to the full width of its container.
            // Otherwise it will size to fit, allowing it to be centered in the container.
            if isEditing {
                centeredURLConstraints.forEach { $0.deactivate() }
                fullWidthURLTextConstraints.forEach { $0.activate() }
            } else {
                fullWidthURLTextConstraints.forEach { $0.deactivate() }
                centeredURLConstraints.forEach { $0.activate() }
            }
        }
    }

    @objc private func didPressDelete() {
        // Prevent layout issues where the user taps Erase and the URL at the same time.
        guard !isEditing else { return }

        isUserInteractionEnabled = false

        delegate?.urlBarDidPressDelete(self)
    }

    @objc private func didPressClear() {
        urlText.text = nil
        urlText.rightView?.isHidden = true
        delegate?.urlBar(self, didEnterText: "")
    }

    @objc private func didPressActivate(_ button: UIButton) {
        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration, animations: {
            button.contentHorizontalAlignment = .left
            self.preActivationConstraints.forEach { $0.deactivate() }
            self.postActivationConstraints.forEach { $0.activate() }
            self.layoutIfNeeded()
        }, completion: { finished in
            self.urlText.placeholder = UIConstants.strings.urlTextPlaceholder
            button.isHidden = true
        })

        urlText.isUserInteractionEnabled = true
        urlText.becomeFirstResponder()
        delegate?.urlBarDidActivate(self)
    }

    private func deactivate() {
        urlText.text = nil
        urlText.placeholder = nil
        urlText.rightView?.isHidden = true
        activateButton.isHidden = false
        urlText.isUserInteractionEnabled = false

        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration, animations: {
            self.activateButton.contentHorizontalAlignment = .center
            self.postActivationConstraints.forEach { $0.deactivate() }
            self.preActivationConstraints.forEach { $0.activate() }
            self.layoutIfNeeded()
        })

        delegate?.urlBarDidDeactivate(self)
    }

    fileprivate func setTextToURL() {
        var displayURL: String? = nil

        if let url = url {
            // Strip the username/password to prevent domain spoofing.
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.user = nil
            components?.password = nil
            displayURL = components?.url?.absoluteString
        }
        urlText.text = displayURL
    }
}

extension URLBar: AutocompleteTextFieldDelegate {
    func autocompleteTextFieldShouldBeginEditing(_ autocompleteTextField: AutocompleteTextField) -> Bool {
        // shouldBeginEditing is fired out-of-band from the touch event, so check the user interaction
        // flag here to make sure it hasn't changed.
        guard isUserInteractionEnabled else { return false }

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
            attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: [NSForegroundColorAttributeName: UIConstants.colors.urlTextPlaceholder])
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
