/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AutocompleteTextField
import SnapKit
import Telemetry

protocol URLBarDelegate: class {
    func urlBar(_ urlBar: URLBar, didEnterText text: String)
    func urlBar(_ urlBar: URLBar, didSubmitText text: String)
    func urlBar(_ urlBar: URLBar, didAddCustomURL url: URL)
    func urlBarDidActivate(_ urlBar: URLBar)
    func urlBarDidDeactivate(_ urlBar: URLBar)
    func urlBarDidFocus(_ urlBar: URLBar)
    func urlBarDidPressScrollTop(_: URLBar, tap: UITapGestureRecognizer)
    func urlBarDidDismiss(_ urlBar: URLBar)
    func urlBarDidPressDelete(_ urlBar: URLBar)
    func urlBarDidTapShield(_ urlBar: URLBar)
}

class URLBar: UIView {
    weak var delegate: URLBarDelegate?
    var userInputText: String?

    let progressBar = GradientProgressBar(progressViewStyle: .bar)
    var inBrowsingMode: Bool = false
    var shouldPresent = false
    fileprivate(set) var isEditing = false

    fileprivate let cancelButton = InsetButton()
    fileprivate let deleteButton = InsetButton()
    fileprivate let domainCompletion = DomainCompletion(completionSources: [TopDomainsCompletionSource(), CustomCompletionSource()])

    private let toolset = BrowserToolset()
    private let urlTextContainer = UIView()
    private let urlText = URLTextField()
    var draggableUrlTextView: UIView { return urlText }
    private let truncatedUrlText = UITextView()
    private let shieldIcon = TrackingProtectionBadge()
    private let lockIcon = UIImageView(image: #imageLiteral(resourceName: "icon_https"))
    private let smallLockIcon = UIImageView(image: #imageLiteral(resourceName: "icon_https_small"))
    private let urlBarBackgroundView = UIView()
    private let textAndLockContainer = UIView()
    private let collapsedUrlAndLockWrapper = UIView()
    private let collapsedTrackingProtectionBadge = CollapsedTrackingProtectionBadge()

    private var fullWidthURLTextConstraints = [Constraint]()
    private var centeredURLConstraints = [Constraint]()
    private var hideShieldConstraints = [Constraint]()
    private var hideLockConstraints = [Constraint]()
    private var hideSmallLockConstraints = [Constraint]()
    private var hideToolsetConstraints = [Constraint]()
    private var showToolsetConstraints = [Constraint]()
    private var isEditingConstraints = [Constraint]()
    private var preActivationConstraints = [Constraint]()
    private var postActivationConstraints = [Constraint]()

    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(didSingleTap(sender:)))
        singleTap.numberOfTapsRequired = 1
        addGestureRecognizer(singleTap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(displayURLContextMenu))
        self.addGestureRecognizer(longPress)
        
        addSubview(toolset.backButton)
        addSubview(toolset.forwardButton)
        addSubview(toolset.stopReloadButton)
        addSubview(toolset.sendButton)

        urlBarBackgroundView.backgroundColor = UIConstants.colors.urlTextBackground
        urlBarBackgroundView.layer.cornerRadius = UIConstants.layout.urlBarCornerRadius
        addSubview(urlBarBackgroundView)

        urlText.isUserInteractionEnabled = false
        addSubview(urlTextContainer)

        urlTextContainer.addSubview(shieldIcon)
        urlTextContainer.addSubview(textAndLockContainer)

        shieldIcon.isHidden = true
        shieldIcon.tintColor = .white
        shieldIcon.alpha = 0
        shieldIcon.contentMode = .center
        shieldIcon.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        shieldIcon.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        shieldIcon.accessibilityIdentifier = "URLBar.trackingProtectionIcon"

        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.numberOfTapsRequired = 1
        gestureRecognizer.cancelsTouchesInView = true
        gestureRecognizer.addTarget(self, action: #selector(didTapShieldIcon))
        shieldIcon.isUserInteractionEnabled = true
        shieldIcon.addGestureRecognizer(gestureRecognizer)

        lockIcon.isHidden = true
        lockIcon.alpha = 0
        lockIcon.contentMode = .center
        lockIcon.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        lockIcon.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        textAndLockContainer.addSubview(lockIcon)

        smallLockIcon.alpha = 0
        smallLockIcon.contentMode = .center
        smallLockIcon.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        smallLockIcon.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        smallLockIcon.accessibilityIdentifier = "Collapsed.smallLockIcon"

        truncatedUrlText.alpha = 0
        truncatedUrlText.isUserInteractionEnabled = false
        truncatedUrlText.font = UIConstants.fonts.truncatedUrlText
        truncatedUrlText.tintColor = UIConstants.colors.urlTextFont
        truncatedUrlText.backgroundColor = UIColor.clear
        truncatedUrlText.contentMode = .bottom
        truncatedUrlText.textColor = UIConstants.colors.urlTextFont
        truncatedUrlText.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        truncatedUrlText.isScrollEnabled = false
        truncatedUrlText.accessibilityIdentifier = "Collapsed.truncatedUrlText"
        
        collapsedTrackingProtectionBadge.alpha = 0
        collapsedTrackingProtectionBadge.tintColor = .white
        collapsedTrackingProtectionBadge.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        collapsedTrackingProtectionBadge.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .horizontal)

        collapsedUrlAndLockWrapper.addSubview(smallLockIcon)
        collapsedUrlAndLockWrapper.addSubview(truncatedUrlText)
        collapsedUrlAndLockWrapper.addSubview(collapsedTrackingProtectionBadge)
        addSubview(collapsedUrlAndLockWrapper)

        // UITextField doesn't allow customization of the clear button, so we create
        // our own so we can use it as the rightView.
        let clearButton = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        clearButton.isHidden = true
        clearButton.setImage(#imageLiteral(resourceName: "icon_clear"), for: .normal)
        clearButton.addTarget(self, action: #selector(didPressClear), for: .touchUpInside)

        urlText.font = UIConstants.fonts.urlText
        urlText.tintColor = UIConstants.colors.urlTextFont
        urlText.textColor = UIConstants.colors.urlTextFont
        urlText.highlightColor = UIConstants.colors.urlTextHighlight
        urlText.keyboardType = .webSearch
        urlText.autocapitalizationType = .none
        urlText.autocorrectionType = .no
        urlText.rightView = clearButton
        urlText.rightViewMode = .whileEditing
        urlText.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        urlText.autocompleteDelegate = self
        urlText.completionSource = domainCompletion
        urlText.accessibilityIdentifier = "URLBar.urlText"
        urlText.placeholder = UIConstants.strings.urlTextPlaceholder
        textAndLockContainer.addSubview(urlText)

        cancelButton.isHidden = true
        cancelButton.alpha = 0
        cancelButton.setTitle(UIConstants.strings.urlBarCancel, for: .normal)
        cancelButton.titleLabel?.font = UIConstants.fonts.cancelButton
        cancelButton.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        cancelButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        cancelButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        cancelButton.accessibilityIdentifier = "URLBar.cancelButton"
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
        deleteButton.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        deleteButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
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
        hiddenDeleteButton.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        hiddenDeleteButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        addSubview(hiddenDeleteButton)

        progressBar.isHidden = true
        progressBar.alpha = 0
        addSubview(progressBar)

        let toolsetButtonWidthMultiplier = 0.08

        toolset.backButton.snp.makeConstraints { make in
            make.leading.equalTo(safeAreaLayoutGuide)
            make.centerY.equalTo(self)

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

        shieldIcon.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalTo(24).priority(900)

            hideShieldConstraints.append(contentsOf:[
                make.width.equalTo(0).constraint
            ])
        }

        textAndLockContainer.snp.makeConstraints { make in
            make.top.bottom.equalTo(urlTextContainer)
            make.leading.equalTo(shieldIcon.snp.trailing).priority(999)
            make.trailing.lessThanOrEqualTo(urlTextContainer)

            centeredURLConstraints.append(make.centerX.equalTo(self).constraint)
            fullWidthURLTextConstraints.append(make.trailing.equalTo(urlTextContainer).constraint)
        }

        lockIcon.snp.makeConstraints { make in
            make.top.bottom.equalTo(textAndLockContainer)

            make.leading.equalTo(textAndLockContainer).inset(UIConstants.layout.lockIconInset).priority(999)

            // Account for the content inset of the URLTextField to balance
            // the spacing around the lock icon
            make.trailing.equalTo(urlText.snp.leading).inset(-(UIConstants.layout.lockIconInset - 4)).priority(999)

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
            make.trailing.equalTo(safeAreaLayoutGuide)
            make.centerY.equalTo(self)
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
            make.bottom.equalTo(self).offset(1)
            make.height.equalTo(3)
        }

        smallLockIcon.snp.makeConstraints { make in
            make.leading.equalTo(collapsedUrlAndLockWrapper)
            make.trailing.equalTo(truncatedUrlText.snp.leading)
            make.bottom.equalTo(self)

            hideLockConstraints.append(contentsOf: [
                make.width.equalTo(0).constraint
            ])
        }
        
        collapsedTrackingProtectionBadge.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(10)
            make.width.height.equalTo(smallLockIcon)
            make.bottom.top.equalTo(smallLockIcon)
        }

        truncatedUrlText.snp.makeConstraints { make in
            make.leading.equalTo(smallLockIcon.snp.trailing)
            make.trailing.equalTo(collapsedUrlAndLockWrapper)
            make.bottom.equalTo(smallLockIcon).offset(5)
        }

        collapsedUrlAndLockWrapper.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.bottom.equalTo(smallLockIcon)
            make.height.equalTo(UIConstants.layout.collapsedUrlBarHeight)
            make.leading.equalTo(smallLockIcon)
            make.trailing.equalTo(truncatedUrlText)
        }

        centeredURLConstraints.forEach { $0.deactivate() }
        showToolsetConstraints.forEach { $0.deactivate() }
        postActivationConstraints.forEach { $0.deactivate() }
        
    }
    
    @objc public func activateTextField() {
        urlText.isUserInteractionEnabled = true
        urlText.becomeFirstResponder()
    }
    
    public func dismissTextField() {
        urlText.isUserInteractionEnabled = false
        urlText.endEditing(true)
    }
    
    @objc private func displayURLContextMenu(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            self.becomeFirstResponder()
            let customURLItem = UIMenuItem(title: UIConstants.strings.customURLMenuButton, action: #selector(addCustomURL))
            let copyItem = UIMenuItem(title: UIConstants.strings.copyMenuButton, action: #selector(copyToClipboard))
            UIMenuController.shared.setTargetRect(self.bounds, in: self)
            UIMenuController.shared.menuItems = [copyItem, customURLItem]
            UIMenuController.shared.setMenuVisible(true, animated: true)
        }
    }
    
    @objc func addCustomURL() {
        guard let url = self.url else { return }
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.quickAddCustomDomainButton)
        delegate?.urlBar(self, didAddCustomURL: url)
    }
    
    @objc func copyToClipboard() {
        UIPasteboard.general.string = self.urlText.text ?? ""
    }
    
    @objc func pasteAndGo() {
        present()
        delegate?.urlBarDidActivate(self)
        delegate?.urlBar(self, didSubmitText: UIPasteboard.general.string!)

        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.pasteAndGo)
    }

    //Adds Menu Item
    func addCustomMenu() {
        if UIPasteboard.general.string != nil && urlText.isFirstResponder {
            let lookupMenu = UIMenuItem(title: UIConstants.strings.urlPasteAndGo, action: #selector(pasteAndGo))
            UIMenuController.shared.menuItems = [lookupMenu]
        }
    }
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        addCustomMenu()
        return super.canPerformAction(action, withSender: sender)
    }
    var url: URL? = nil {
        didSet {
            if !urlText.isEditing {
                setTextToURL()
                updateLockIcon()
                updateShieldIcon()
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
        if urlText.isUserInteractionEnabled,
            let touch = touches.first {
            let point = touch.location(in: urlTextContainer)
            if urlTextContainer.bounds.contains(point) {
                urlText.becomeFirstResponder()
                return
            }
        }
        super.touchesEnded(touches, with: event)
    }

    func ensureBrowsingMode() {
        shouldPresent = false
        isEditing = true
        inBrowsingMode = true
        dismiss()
        postActivationConstraints.forEach { $0.activate() }
        preActivationConstraints.forEach { $0.deactivate() }
    }

    func fillUrlBar(text: String) {
        urlText.text = text
    }

    private func updateLockIcon() {
        let visible = !isEditing && (url?.scheme == "https")
        let duration = UIConstants.layout.urlBarTransitionAnimationDuration / 2

        lockIcon.animateHidden(!visible, duration: duration)

        self.layoutIfNeeded()
        UIView.animate(withDuration: duration) {
            if visible {
                self.hideLockConstraints.forEach { $0.deactivate() }
                self.hideSmallLockConstraints.forEach { $0.deactivate() }
            } else {
                self.hideLockConstraints.forEach { $0.activate() }
                self.hideSmallLockConstraints.forEach { $0.activate() }
            }

            self.layoutIfNeeded()
        }
    }

    private func updateShieldIcon() {
        let visible = !isEditing && url != nil
        let duration = UIConstants.layout.urlBarTransitionAnimationDuration / 2

        shieldIcon.animateHidden(!visible, duration: duration)
        self.layoutIfNeeded()

        UIView.animate(withDuration: duration) {
            if visible {
                self.hideShieldConstraints.forEach { $0.deactivate() }
            } else {
                self.hideShieldConstraints.forEach { $0.activate() }
            }
            self.layoutIfNeeded()
        }

    }

    fileprivate func present() {
        guard !isEditing else { return }

        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration) {
            self.preActivationConstraints.forEach { $0.deactivate() }
            self.postActivationConstraints.forEach { $0.activate() }
            self.layoutIfNeeded()
        }

        isEditing = true
        shouldPresent = false
        updateLockIcon()
        updateShieldIcon()
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
        updateShieldIcon()
        let _ = urlText.resignFirstResponder()
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

    @objc private func didSingleTap(sender: UITapGestureRecognizer) {
        delegate?.urlBarDidPressScrollTop(self, tap: sender)
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

    @objc private func didTapShieldIcon() {
        delegate?.urlBarDidTapShield(self)
    }

    private func deactivate() {
        urlText.text = nil
        urlText.rightView?.isHidden = true

        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration, animations: {
            self.postActivationConstraints.forEach { $0.deactivate() }
            self.preActivationConstraints.forEach { $0.activate() }
            self.layoutIfNeeded()
        })

        delegate?.urlBarDidDeactivate(self)
    }

    fileprivate func setTextToURL() {
        var displayURL: String? = nil
        var truncatedURL: String? = nil

        if let url = url {
            // Strip the username/password to prevent domain spoofing.
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.user = nil
            components?.password = nil
            displayURL = components?.url?.absoluteString
            truncatedURL = components?.host
        }
        urlText.text = displayURL
        truncatedUrlText.text = truncatedURL
    }

    func collapseUrlBar(expandAlpha: CGFloat, collapseAlpha: CGFloat) {
        deleteButton.alpha = expandAlpha
        urlTextContainer.alpha = expandAlpha
        truncatedUrlText.alpha = collapseAlpha
        collapsedUrlAndLockWrapper.alpha = collapseAlpha
        toolset.backButton.alpha = expandAlpha
        toolset.forwardButton.alpha = expandAlpha
        toolset.stopReloadButton.alpha = expandAlpha
        toolset.sendButton.alpha = expandAlpha
        collapsedTrackingProtectionBadge.alpha = collapseAlpha
        // updating the small lock icon status here in order to prevent the icon from flashing on start up
        let visible = !isEditing && (url?.scheme == "https")
        smallLockIcon.alpha = visible ? collapseAlpha : 0
        self.layoutIfNeeded()
    }
    
    func updateTrackingProtectionBadge(trackingStatus: TrackingProtectionStatus) {
        shieldIcon.updateState(trackingStatus: trackingStatus)
        collapsedTrackingProtectionBadge.updateState(trackingStatus: trackingStatus)
    }
}

extension URLBar: AutocompleteTextFieldDelegate {
    func autocompleteTextFieldShouldBeginEditing(_ autocompleteTextField: AutocompleteTextField) -> Bool {

        autocompleteTextField.highlightAll()
        
        if !isEditing && inBrowsingMode {
            present()
            delegate?.urlBarDidActivate(self)
        }
        
        // When text.characters.count == 0, it is the HomeView
        if let text = autocompleteTextField.text, !isEditing, text.count == 0 {
            shouldPresent = true
        }

        return true
    }

    func autocompleteTextFieldShouldReturn(_ autocompleteTextField: AutocompleteTextField) -> Bool {
        
        if let autocompleteText = autocompleteTextField.text, autocompleteText != userInputText {
            Telemetry.default.recordEvent(TelemetryEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.autofill))
        }
        userInputText = nil
        
        delegate?.urlBar(self, didSubmitText: autocompleteTextField.text ?? "")
        return true
    }

    func autocompleteTextField(_ autocompleteTextField: AutocompleteTextField, didTextChange text: String) {
        userInputText = text
        
        autocompleteTextField.rightView?.isHidden = text.isEmpty

        if !isEditing && shouldPresent {
            present()
            delegate?.urlBarDidActivate(self)
        }

        delegate?.urlBar(self, didEnterText: text)
    }
}

private class URLTextField: AutocompleteTextField {
    
    // Disable user interaction on resign so that touch and hold on URL bar creates menu
    override func resignFirstResponder() -> Bool {
        isUserInteractionEnabled = false
        return super.resignFirstResponder()
    }
    
    override var placeholder: String? {
        didSet {
            attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: [NSAttributedStringKey.foregroundColor: UIConstants.colors.urlTextPlaceholder])
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

class TrackingProtectionBadge: UIView {
    let counterLabel = SmartLabel()
    let trackingProtectionOff = UIImageView(image: #imageLiteral(resourceName: "tracking_protection_off").imageFlippedForRightToLeftLayoutDirection())
    let trackingProtectionCounter = UIImageView(image: #imageLiteral(resourceName: "tracking_protection_counter").imageFlippedForRightToLeftLayoutDirection())
    let counterLabelWrapper = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setupViews()
    }

    func setupViews() {
        counterLabel.backgroundColor = .clear
        counterLabel.textColor = UIColor.white
        counterLabel.textAlignment = .center
        counterLabel.font = UIFont.boldSystemFont(ofSize: 8)
        counterLabel.text = "0"
        counterLabel.accessibilityIdentifier = "TrackingProtectionBadge.counterLabel"
        trackingProtectionOff.alpha = 0
        
        addSubview(trackingProtectionOff)
        addSubview(trackingProtectionCounter)
        counterLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        counterLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        counterLabelWrapper.addSubview(counterLabel)
        addSubview(counterLabelWrapper)

        trackingProtectionCounter.setContentHuggingPriority(.required, for: .horizontal)
        trackingProtectionCounter.snp.makeConstraints { make in
            make.leading.equalToSuperview().priority(1000)
            make.centerY.equalToSuperview().priority(500)
            make.width.equalTo(24).priority(500)
            make.trailing.equalToSuperview()
        }

        trackingProtectionOff.setContentHuggingPriority(.required, for: .horizontal)
        trackingProtectionOff.snp.makeConstraints { make in
            make.leading.equalToSuperview().priority(1000)
            make.centerY.equalToSuperview().priority(500)
        }

        counterLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        counterLabelWrapper.snp.makeConstraints { make in
            make.width.height.equalTo(12)
            make.bottom.equalTo(trackingProtectionCounter).offset(-2).priority(500)
            make.leading.equalTo(trackingProtectionCounter).offset(13).priority(500)
        }

        counterLabel.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview().priority(500)
            make.leading.greaterThanOrEqualToSuperview().offset(2)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateState(trackingStatus: TrackingProtectionStatus) {
        switch trackingStatus {
        case .on(let info):
            trackingProtectionOff.alpha = 0
            trackingProtectionCounter.alpha = 1
            counterLabel.alpha = 1
            counterLabel.text = String(info.total)
            counterLabel.sizeToFit()
        default:
            trackingProtectionOff.alpha = 1
            trackingProtectionCounter.alpha = 0
            counterLabel.alpha = 0
        }
    }
}

class CollapsedTrackingProtectionBadge: TrackingProtectionBadge {
    let trackingProtection = UIImageView(image: #imageLiteral(resourceName: "tracking_protection"))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func setupViews() {
        addSubview(trackingProtectionOff)
        addSubview(trackingProtection)
        addSubview(counterLabel)
        
        trackingProtection.snp.makeConstraints { make in
            make.leading.centerY.equalTo(self)
            make.width.height.equalTo(18)
        }

        trackingProtectionOff.snp.makeConstraints { make in
            make.leading.centerY.equalTo(self)
            make.width.height.equalTo(18)
        }
        
        counterLabel.backgroundColor = .clear
        counterLabel.textColor = UIColor.white
        counterLabel.font = UIFont.boldSystemFont(ofSize: 12)
        counterLabel.textAlignment = .center
        counterLabel.snp.makeConstraints { make in
            make.leading.equalTo(trackingProtection.snp.trailing).offset(4)
            make.centerY.equalTo(trackingProtection)
        }
    }
    
    override func updateState(trackingStatus: TrackingProtectionStatus) {
        switch trackingStatus {
        case .on(let info):
            trackingProtectionOff.alpha = 0
            trackingProtection.alpha = 1
            counterLabel.alpha = 1
            counterLabel.text = String(info.total)
        default:
            trackingProtectionOff.alpha = 1
            trackingProtection.alpha = 0
            counterLabel.alpha = 0
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
