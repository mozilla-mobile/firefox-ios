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
    func urlBarDidLongPress(_ urlBar: URLBar)
    func urlBarDidPressPageActions(_ urlBar: URLBar)
}

class URLBar: UIView {
    weak var delegate: URLBarDelegate?
    var userInputText: String?

    let progressBar = GradientProgressBar(progressViewStyle: .bar)
    var inBrowsingMode: Bool = false
    var shouldPresent = false
    fileprivate(set) var isEditing = false
    
    private let cancelButton = InsetButton()
    fileprivate let deleteButton = InsetButton()
    fileprivate let domainCompletion = DomainCompletion(completionSources: [TopDomainsCompletionSource(), CustomCompletionSource()])

    private let toolset = BrowserToolset()
    private let urlText = URLTextField()
    var draggableUrlTextView: UIView { return urlText }
    private let truncatedUrlText = UITextView()
    private let lockIcon = UIImageView(image: #imageLiteral(resourceName: "icon_https"))
    private let smallLockIcon = UIImageView(image: #imageLiteral(resourceName: "icon_https_small"))
    private let urlBarBorderView = UIView()
    private let urlBarBackgroundView = UIView()
    private let textAndLockContainer = UIView()
    private let collapsedUrlAndLockWrapper = UIView()
    private let collapsedTrackingProtectionBadge = CollapsedTrackingProtectionBadge()
    
    let pageActionsButton = InsetButton()
    let shieldIcon = TrackingProtectionBadge()

    private var fullWidthURLTextConstraints = [Constraint]()
    private var centeredURLConstraints = [Constraint]()
    private var hideLockConstraints = [Constraint]()
    private var hideSmallLockConstraints = [Constraint]()
    private var hidePageActionsConstraints = [Constraint]()
    private var hideCancelConstraints = [Constraint]()
    private var hideToolsetConstraints = [Constraint]()
    private var showToolsetConstraints = [Constraint]()
    private var isEditingConstraints = [Constraint]()

    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(didSingleTap(sender:)))
        singleTap.numberOfTapsRequired = 1
        addGestureRecognizer(singleTap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(urlBarDidLongPress))
        self.addGestureRecognizer(longPress)
        
        addSubview(toolset.backButton)
        addSubview(toolset.forwardButton)
        addSubview(toolset.stopReloadButton)
        addSubview(toolset.settingsButton)
        
        urlBarBorderView.backgroundColor = UIConstants.Photon.Grey10.withAlphaComponent(0.1)
        urlBarBorderView.layer.cornerRadius = UIConstants.layout.urlBarCornerRadius
        urlBarBorderView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        urlBarBorderView.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        addSubview(urlBarBorderView)

        urlBarBackgroundView.backgroundColor = UIConstants.Photon.Grey10.withAlphaComponent(0.2)
        urlBarBackgroundView.layer.cornerRadius = UIConstants.layout.urlBarCornerRadius
        urlBarBackgroundView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        urlBarBackgroundView.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        urlBarBorderView.addSubview(urlBarBackgroundView)
        addSubview(shieldIcon)

        urlText.isUserInteractionEnabled = false
        urlBarBackgroundView.addSubview(textAndLockContainer)

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
        
        pageActionsButton.isHidden = true
        pageActionsButton.alpha = 0
        pageActionsButton.setImage(#imageLiteral(resourceName: "icon_page_action"), for: .normal)
        pageActionsButton.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        pageActionsButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        pageActionsButton.addTarget(self, action: #selector(didPressPageActions), for: .touchUpInside)
        pageActionsButton.accessibilityIdentifier = "URLBar.pageActionsButton"
        pageActionsButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 8, bottom: 8 ,right: 10)
        textAndLockContainer.addSubview(pageActionsButton)

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
        let myImage = UIImage(named: "icon_cancel")
        cancelButton.setImage(myImage, for: .normal)
        
        cancelButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        cancelButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        cancelButton.accessibilityIdentifier = "URLBar.cancelButton"
        cancelButton.contentEdgeInsets = UIEdgeInsets(top: UIConstants.layout.urlBarMargin,
                                                      left: UIConstants.layout.urlBarMargin,
                                                      bottom: UIConstants.layout.urlBarMargin,
                                                      right: UIConstants.layout.urlBarMargin)
        addSubview(cancelButton)
        
        deleteButton.isHidden = true
        deleteButton.alpha = 0
        deleteButton.setImage(#imageLiteral(resourceName: "icon_delete"), for: .normal)
        deleteButton.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        deleteButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        deleteButton.addTarget(self, action: #selector(didPressDelete), for: .touchUpInside)
        deleteButton.contentEdgeInsets = UIEdgeInsets(top: UIConstants.layout.urlBarMargin,
                                                      left: UIConstants.layout.urlBarMargin,
                                                      bottom: UIConstants.layout.urlBarMargin,
                                                      right: UIConstants.layout.urlBarMargin)
        deleteButton.accessibilityIdentifier = "URLBar.deleteButton"
        addSubview(deleteButton)

        progressBar.isHidden = true
        progressBar.alpha = 0
        addSubview(progressBar)

        var toolsetButtonWidthMultiplier : CGFloat {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return 0.04
            }
            else {
                return 0.05
            }
        }

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
        
        toolset.settingsButton.snp.makeConstraints { make in
            make.trailing.equalTo(safeAreaLayoutGuide)
            make.centerY.equalTo(self)
            make.size.equalTo(toolset.backButton)
        }

        toolset.stopReloadButton.snp.makeConstraints { make in
            make.leading.equalTo(toolset.forwardButton.snp.trailing)
            make.centerY.equalTo(self)
            make.size.equalTo(toolset.backButton)
        }
        
        urlBarBorderView.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(shieldIcon.snp.trailing).priority(.required)
            make.leading.equalTo(shieldIcon.snp.trailing).priority(.medium)
            make.trailing.lessThanOrEqualTo(deleteButton.snp.leading).priority(.required)
            make.trailing.equalTo(deleteButton.snp.leading).priority(.medium)
            make.height.equalTo(42).priority(.medium)
            make.top.bottom.equalToSuperview().inset(UIConstants.layout.urlBarMargin)
            
            isEditingConstraints.append(make.height.equalTo(48).priority(.high).constraint)
            isEditingConstraints.append(make.leading.greaterThanOrEqualToSuperview().offset(UIConstants.layout.urlBarMargin).constraint)
            isEditingConstraints.append(make.leading.greaterThanOrEqualTo(cancelButton.snp.trailing).constraint)
            isEditingConstraints.append(make.trailing.lessThanOrEqualTo(safeAreaLayoutGuide.snp.trailing).offset(-UIConstants.layout.urlBarMargin).constraint)
        }

        urlBarBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIConstants.layout.urlBarBorderInset)
        }

        shieldIcon.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(UIConstants.layout.urlBarButtonTargetSize)
            hideToolsetConstraints.append(make.leading.equalToSuperview().constraint)
            showToolsetConstraints.append(make.leading.equalTo(toolset.stopReloadButton.snp.trailing).offset(UIConstants.layout.urlBarToolsetOffset).constraint)
            make.width.equalTo(UIConstants.layout.urlBarButtonTargetSize).priority(900)

            isEditingConstraints.append(make.width.equalTo(0).constraint)
        }

        textAndLockContainer.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().priority(999)
            make.trailing.lessThanOrEqualToSuperview()

            centeredURLConstraints.append(make.centerX.equalToSuperview().constraint)
            fullWidthURLTextConstraints.append(make.trailing.equalToSuperview().constraint)
        }
        
        pageActionsButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(textAndLockContainer).priority(.required)
            make.width.equalTo(UIConstants.layout.urlBarButtonTargetSize).priority(900)
            
            hidePageActionsConstraints.append(contentsOf:[
                make.size.equalTo(0).constraint
                ])
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
            make.top.bottom.equalToSuperview()
            make.trailing.equalTo(pageActionsButton.snp.leading)
        }

        toolset.settingsButton.snp.makeConstraints { make in
            make.trailing.equalTo(safeAreaLayoutGuide)
            make.centerY.equalTo(self)
            make.size.equalTo(toolset.backButton)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(safeAreaLayoutGuide.snp.leading)
            hideCancelConstraints.append(make.width.equalTo(0).priority(.required).constraint)
        }
        hideCancelConstraints.forEach { $0.activate() }

        deleteButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(UIConstants.layout.urlBarButtonTargetSize)

            isEditingConstraints.append(make.width.equalTo(0).constraint)
            hideToolsetConstraints.append(make.trailing.equalToSuperview().constraint)
            showToolsetConstraints.append(make.trailing.greaterThanOrEqualTo(toolset.settingsButton.snp.leading).offset(-UIConstants.layout.urlBarToolsetOffset).constraint)
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
            UIMenuController.shared.setTargetRect(self.bounds, in: self)
            UIMenuController.shared.setMenuVisible(true, animated: true)
        }
    }
    
    @objc func addCustomURL() {
        guard let url = self.url else { return }
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.quickAddCustomDomainButton)
        delegate?.urlBar(self, didAddCustomURL: url)
    }
    
    @objc func copyToClipboard() {
        UIPasteboard.general.string = self.url?.absoluteString ?? ""
    }
    
    @objc func paste(clipboardString: String) {
        present()
        urlText.text = clipboardString
        activateTextField()
    }
    
    @objc func pasteAndGo(clipboardString: String) {
        present()
        delegate?.urlBarDidActivate(self)
        delegate?.urlBar(self, didSubmitText: clipboardString)
            
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.pasteAndGo)
    }
    
    @objc func pasteAndGoFromContextMenu() {
        guard let clipboardString = UIPasteboard.general.string else { return }
        present()
        delegate?.urlBarDidActivate(self)
        delegate?.urlBar(self, didSubmitText: clipboardString)
        
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.pasteAndGo)
    }

    //Adds Menu Item
    func addCustomMenu() {
        if UIPasteboard.general.string != nil && urlText.isFirstResponder {
            let lookupMenu = UIMenuItem(title: UIConstants.strings.urlPasteAndGo, action: #selector(pasteAndGoFromContextMenu))
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
                updateUrlIcons()
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
            let point = touch.location(in: urlBarBorderView)
            if urlBarBorderView.bounds.contains(point) {
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

    private func updateUrlIcons() {
        let visible = !isEditing && url != nil
        let duration = UIConstants.layout.urlBarTransitionAnimationDuration / 2

        pageActionsButton.animateHidden(!visible, duration: duration)
        shieldIcon.animateHidden(!visible, duration: duration)
        self.layoutIfNeeded()

        UIView.animate(withDuration: duration) {
            if visible {
                self.hidePageActionsConstraints.forEach { $0.deactivate() }
            } else {
                self.hidePageActionsConstraints.forEach { $0.activate() }
            }
            self.layoutIfNeeded()
        }

    }

    fileprivate func present() {
        guard !isEditing else { return }

        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration) {
            self.layoutIfNeeded()
        }

        isEditing = true
        shouldPresent = false
        updateLockIcon()
        updateUrlIcons()
        toolset.settingsButton.isEnabled = true
        delegate?.urlBarDidFocus(self)

        cancelButton.animateHidden(false, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
        hideCancelConstraints.forEach { $0.deactivate() }
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
                    make.edges.equalToSuperview().inset(UIConstants.layout.urlBarBorderInset)
                }

                self.urlBarBorderView.backgroundColor = UIConstants.Photon.Grey10.withAlphaComponent(0.1)
                self.urlBarBackgroundView.backgroundColor = UIConstants.Photon.Grey10.withAlphaComponent(0.2)
            }

            self.layoutIfNeeded()
        }
    }

    @objc func dismiss() {
        guard isEditing else { return }

        isEditing = false
        updateLockIcon()
        updateUrlIcons()
        let _ = urlText.resignFirstResponder()
        delegate?.urlBarDidDismiss(self)
        setTextToURL()
        
        cancelButton.animateHidden(true, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
        hideCancelConstraints.forEach { $0.activate() }

        if inBrowsingMode {
            deleteButton.animateHidden(false, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
        } else {
            deactivate()
        }

        self.layoutIfNeeded()
        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration) {

            if self.inBrowsingMode {
                self.isEditingConstraints.forEach { $0.deactivate() }
                // Reveal the URL bar buttons on iPad/landscape.
                self.updateToolsetConstraints()

                self.urlBarBackgroundView.snp.remakeConstraints { make in
                    make.edges.equalToSuperview().inset(1)
                }

                self.urlBarBorderView.backgroundColor = UIConstants.Photon.Grey90.withAlphaComponent(0.2)
                self.urlBarBackgroundView.backgroundColor = UIConstants.Photon.Grey10.withAlphaComponent(0.2)
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
        let isHidden = !inBrowsingMode || !showToolset || isEditing
        toolset.backButton.animateHidden(isHidden, duration: 0.3)
        toolset.forwardButton.animateHidden(isHidden, duration: 0.3)
        toolset.stopReloadButton.animateHidden(isHidden, duration: 0.3)
        toolset.settingsButton.animateHidden(isHidden, duration: 0.3)

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
    
    @objc func urlBarDidLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            delegate?.urlBarDidLongPress(self)
        }
    }

    private func deactivate() {
        urlText.text = nil
        urlText.rightView?.isHidden = true

        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration, animations: {
            self.layoutIfNeeded()
        })

        delegate?.urlBarDidDeactivate(self)
    }
    
    @objc private func didPressPageActions() {
        delegate?.urlBarDidPressPageActions(self)
    }

    fileprivate func setTextToURL(displayFullUrl: Bool = false) {
        var fullUrl: String? = nil
        var truncatedURL: String? = nil
        var displayText: String? = nil
        
        if let url = url {
            // Strip the username/password to prevent domain spoofing.
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.user = nil
            components?.password = nil
            fullUrl = components?.url?.absoluteString
            truncatedURL = components?.host

            if let stackValue = SearchHistoryUtils.pullSearchFromStack(), !stackValue.isUrl {
                displayText = stackValue
            } else {
                displayText = truncatedURL
            }

            urlText.text = displayFullUrl ? fullUrl : displayText
            truncatedUrlText.text = truncatedURL
        }
    }

    func collapseUrlBar(expandAlpha: CGFloat, collapseAlpha: CGFloat) {
        urlBarBorderView.alpha = expandAlpha
        urlBarBackgroundView.alpha = expandAlpha
        truncatedUrlText.alpha = collapseAlpha
        collapsedUrlAndLockWrapper.alpha = collapseAlpha
        toolset.backButton.alpha = expandAlpha
        toolset.forwardButton.alpha = expandAlpha
        toolset.stopReloadButton.alpha = expandAlpha
        toolset.settingsButton.alpha = expandAlpha
        collapsedTrackingProtectionBadge.alpha = collapseAlpha
        if isEditing {
            deleteButton.alpha = collapseAlpha
            shieldIcon.alpha = collapseAlpha
        } else {
            deleteButton.alpha = expandAlpha
            shieldIcon.alpha = expandAlpha
        }
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

        setTextToURL(displayFullUrl: true)
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
            attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: [.foregroundColor: UIConstants.colors.urlTextPlaceholder])
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
    
    private func textFieldDidEndEditing(_ textField: UITextField) {
        textField.layoutIfNeeded()
    }
}

class TrackingProtectionBadge: UIView {
    let trackingProtectionOff = UIImageView(image: #imageLiteral(resourceName: "tracking_protection_off").imageFlippedForRightToLeftLayoutDirection())
    let trackingProtectionOn = UIImageView(image: #imageLiteral(resourceName: "tracking_protection").imageFlippedForRightToLeftLayoutDirection())

    override init(frame: CGRect) {
        super.init(frame: frame)
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setupViews()
    }

    func setupViews() {
        trackingProtectionOff.alpha = 0
        
        addSubview(trackingProtectionOff)
        addSubview(trackingProtectionOn)

        trackingProtectionOn.setContentHuggingPriority(.required, for: .horizontal)
        trackingProtectionOn.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.width.equalTo(UIConstants.layout.urlBarButtonImageSize)
        }

        trackingProtectionOff.setContentHuggingPriority(.required, for: .horizontal)
        trackingProtectionOff.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.width.equalTo(UIConstants.layout.urlBarButtonImageSize)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateState(trackingStatus: TrackingProtectionStatus) {
        switch trackingStatus {
        case .on:
            trackingProtectionOff.alpha = 0
            trackingProtectionOn.alpha = 1
        default:
            trackingProtectionOff.alpha = 1
            trackingProtectionOn.alpha = 0
        }
    }
}

class CollapsedTrackingProtectionBadge: TrackingProtectionBadge {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func setupViews() {
        addSubview(trackingProtectionOff)
        addSubview(trackingProtectionOn)
        
        trackingProtectionOn.snp.makeConstraints { make in
            make.leading.centerY.equalTo(self)
            make.width.height.equalTo(18)
        }

        trackingProtectionOff.snp.makeConstraints { make in
            make.leading.centerY.equalTo(self)
            make.width.height.equalTo(18)
        }
    }
    
    override func updateState(trackingStatus: TrackingProtectionStatus) {
        switch trackingStatus {
        case .on:
            trackingProtectionOff.alpha = 0
            trackingProtectionOn.alpha = 1
        default:
            trackingProtectionOff.alpha = 1
            trackingProtectionOn.alpha = 0
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
