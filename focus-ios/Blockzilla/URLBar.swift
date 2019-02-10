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
    enum State {
        case `default`
        case browsing
        case editing
    }

    var state = State.default {
        didSet {
            guard oldValue != state else { return }
            updateViews()

            if oldValue == .editing {
                _ = urlText.resignFirstResponder()
                delegate?.urlBarDidDismiss(self)
            } else if state == .editing {
                delegate?.urlBarDidFocus(self)
            }
        }
    }

    weak var delegate: URLBarDelegate?
    var userInputText: String?

    let progressBar = GradientProgressBar(progressViewStyle: .bar)
    var inBrowsingMode: Bool = false {
        didSet {
            updateBarState()
        }
    }
    private(set) var isEditing = false {
        didSet {
            updateBarState()
        }
    }
    var shouldPresent = false

    private let leftBarViewLayoutGuide = UILayoutGuide()
    private let rightBarViewLayoutGuide = UILayoutGuide()

    private let cancelButton = InsetButton()
    private let deleteButton = InsetButton()
    private let domainCompletion = DomainCompletion(completionSources: [TopDomainsCompletionSource(), CustomCompletionSource()])

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

    var centerURLBar = false {
        didSet {
            guard oldValue != centerURLBar else { return }
            activateConstraints(centerURLBar, shownConstraints: centeredURLConstraints, hiddenConstraints: fullWidthURLConstraints)
        }
    }
    private var centeredURLConstraints = [Constraint]()
    private var fullWidthURLConstraints = [Constraint]()

    var hidePageActions = true {
        didSet {
            guard oldValue != hidePageActions else { return }
            activateConstraints(hidePageActions, shownConstraints: showPageActionsConstraints, hiddenConstraints: hidePageActionsConstraints)
        }
    }
    private var hidePageActionsConstraints = [Constraint]()
    private var showPageActionsConstraints = [Constraint]()

    private var showToolset = false {
        didSet {
            guard oldValue != showToolset else { return }
            activateConstraints(showToolset, shownConstraints: showToolsetConstraints, hiddenConstraints: hideToolsetConstraints)
        }
    }
    private var hideToolsetConstraints = [Constraint]()
    private var showToolsetConstraints = [Constraint]()

    private var compressBar = false {
        didSet {
            guard oldValue != compressBar else { return }
            activateConstraints(compressBar, shownConstraints: compressedBarConstraints, hiddenConstraints: expandedBarConstraints)
        }
    }
    private var compressedBarConstraints = [Constraint]()
    private var expandedBarConstraints = [Constraint]()

    private var showLeftBar = false {
        didSet {
            guard oldValue != showLeftBar else { return }
            activateConstraints(showLeftBar, shownConstraints: showLeftBarViewConstraints, hiddenConstraints: hideLeftBarViewConstraints)
        }
    }
    private var showLeftBarViewConstraints = [Constraint]()
    private var hideLeftBarViewConstraints = [Constraint]()

    private var hideLockConstraints = [Constraint]()
    private var showLockConstraints = [Constraint]()
    private var hideSmallLockConstraints = [Constraint]()

    override var canBecomeFirstResponder: Bool {
        return true
    }

    convenience init() {
        self.init(frame: CGRect.zero)

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(didSingleTap(sender:)))
        singleTap.numberOfTapsRequired = 1
        textAndLockContainer.addGestureRecognizer(singleTap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(urlBarDidLongPress))
        textAndLockContainer.addGestureRecognizer(longPress)

        let dragInteraction = UIDragInteraction(delegate: self)
        textAndLockContainer.addInteraction(dragInteraction)

        addSubview(toolset.backButton)
        addSubview(toolset.forwardButton)
        addSubview(toolset.stopReloadButton)
        addSubview(toolset.settingsButton)
        addSubview(shieldIcon)

        urlText.isUserInteractionEnabled = false
        urlBarBackgroundView.addSubview(textAndLockContainer)

        shieldIcon.isHidden = true
        shieldIcon.tintColor = .white
        shieldIcon.alpha = 0
        shieldIcon.contentMode = .center
        shieldIcon.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        shieldIcon.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        shieldIcon.accessibilityIdentifier = "URLBar.trackingProtectionIcon"

        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.numberOfTapsRequired = 1
        gestureRecognizer.cancelsTouchesInView = true
        gestureRecognizer.addTarget(self, action: #selector(didTapShieldIcon))
        shieldIcon.isUserInteractionEnabled = true
        shieldIcon.addGestureRecognizer(gestureRecognizer)

        cancelButton.isHidden = true
        cancelButton.alpha = 0
        let myImage = UIImage(named: "icon_cancel")
        cancelButton.setImage(myImage, for: .normal)

        cancelButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        cancelButton.addTarget(self, action: #selector(cancelPressed), for: .touchUpInside)
        cancelButton.accessibilityIdentifier = "URLBar.cancelButton"
        cancelButton.contentEdgeInsets = UIEdgeInsets(top: UIConstants.layout.urlBarMargin,
                                                      left: UIConstants.layout.urlBarMargin,
                                                      bottom: UIConstants.layout.urlBarMargin,
                                                      right: UIConstants.layout.urlBarMargin)
        addSubview(cancelButton)

        deleteButton.isHidden = true
        deleteButton.alpha = 0
        deleteButton.setImage(#imageLiteral(resourceName: "icon_delete"), for: .normal)
        deleteButton.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        deleteButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        deleteButton.addTarget(self, action: #selector(didPressDelete), for: .touchUpInside)
        deleteButton.contentEdgeInsets = UIEdgeInsets(top: UIConstants.layout.urlBarMargin,
                                                      left: UIConstants.layout.urlBarMargin,
                                                      bottom: UIConstants.layout.urlBarMargin,
                                                      right: UIConstants.layout.urlBarMargin)
        deleteButton.accessibilityIdentifier = "URLBar.deleteButton"
        addSubview(deleteButton)

        lockIcon.isHidden = true
        lockIcon.alpha = 0
        lockIcon.contentMode = .center
        lockIcon.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        lockIcon.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        textAndLockContainer.addSubview(lockIcon)

        pageActionsButton.isHidden = true
        pageActionsButton.alpha = 0
        pageActionsButton.setImage(#imageLiteral(resourceName: "icon_page_action"), for: .normal)
        pageActionsButton.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        pageActionsButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        pageActionsButton.addTarget(self, action: #selector(didPressPageActions), for: .touchUpInside)
        pageActionsButton.accessibilityIdentifier = "URLBar.pageActionsButton"
        pageActionsButton.contentEdgeInsets = UIConstants.layout.urlBarPageActionsButtonInsets
        textAndLockContainer.addSubview(pageActionsButton)

        urlBarBorderView.backgroundColor = UIConstants.Photon.Grey10.withAlphaComponent(0.1)
        urlBarBorderView.layer.cornerRadius = UIConstants.layout.urlBarCornerRadius
        urlBarBorderView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        urlBarBorderView.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        addSubview(urlBarBorderView)

        urlBarBackgroundView.backgroundColor = UIConstants.Photon.Grey10.withAlphaComponent(0.2)
        urlBarBackgroundView.layer.cornerRadius = UIConstants.layout.urlBarCornerRadius
        urlBarBackgroundView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        urlBarBackgroundView.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        urlBarBorderView.addSubview(urlBarBackgroundView)

        smallLockIcon.alpha = 0
        smallLockIcon.contentMode = .center
        smallLockIcon.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        smallLockIcon.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        smallLockIcon.accessibilityIdentifier = "Collapsed.smallLockIcon"

        truncatedUrlText.alpha = 0
        truncatedUrlText.isUserInteractionEnabled = false
        truncatedUrlText.font = UIConstants.fonts.truncatedUrlText
        truncatedUrlText.tintColor = UIConstants.colors.urlTextFont
        truncatedUrlText.backgroundColor = UIColor.clear
        truncatedUrlText.contentMode = .bottom
        truncatedUrlText.textColor = UIConstants.colors.urlTextFont
        truncatedUrlText.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .vertical)
        truncatedUrlText.isScrollEnabled = false
        truncatedUrlText.accessibilityIdentifier = "Collapsed.truncatedUrlText"

        collapsedTrackingProtectionBadge.alpha = 0
        collapsedTrackingProtectionBadge.tintColor = .white
        collapsedTrackingProtectionBadge.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        collapsedTrackingProtectionBadge.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)

        collapsedUrlAndLockWrapper.addSubview(smallLockIcon)
        collapsedUrlAndLockWrapper.addSubview(truncatedUrlText)
        collapsedUrlAndLockWrapper.addSubview(collapsedTrackingProtectionBadge)
        addSubview(collapsedUrlAndLockWrapper)

        // UITextField doesn't allow customization of the clear button, so we create
        // our own so we can use it as the rightView.
        let clearButton = UIButton(frame: CGRect(x: 0, y: 0, width: UIConstants.layout.urlBarClearButtonWidth, height: UIConstants.layout.urlBarClearButtonHeight))
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
        urlText.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .vertical)
        urlText.autocompleteDelegate = self
        urlText.completionSource = domainCompletion
        urlText.accessibilityIdentifier = "URLBar.urlText"
        urlText.placeholder = UIConstants.strings.urlTextPlaceholder
        textAndLockContainer.addSubview(urlText)

        progressBar.isHidden = true
        progressBar.alpha = 0
        addSubview(progressBar)

        var toolsetButtonWidthMultiplier: CGFloat {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return 0.04
            } else {
                return 0.05
            }
        }

        addLayoutGuide(leftBarViewLayoutGuide)
        leftBarViewLayoutGuide.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.equalTo(UIConstants.layout.urlBarButtonTargetSize)
            make.width.equalTo(UIConstants.layout.urlBarButtonTargetSize).priority(900)

            hideToolsetConstraints.append(make.leading.equalTo(safeAreaLayoutGuide).offset(UIConstants.layout.urlBarMargin).constraint)
            showToolsetConstraints.append(make.leading.equalTo(toolset.stopReloadButton.snp.trailing).offset(UIConstants.layout.urlBarToolsetOffset).constraint)
        }

        addLayoutGuide(rightBarViewLayoutGuide)
        rightBarViewLayoutGuide.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.equalTo(UIConstants.layout.urlBarButtonTargetSize)

            hideToolsetConstraints.append(make.trailing.equalTo(safeAreaLayoutGuide.snp.trailing).inset(UIConstants.layout.urlBarMargin).constraint)
            showToolsetConstraints.append(make.trailing.greaterThanOrEqualTo(toolset.settingsButton.snp.leading).offset(-UIConstants.layout.urlBarToolsetOffset).constraint)
        }

        toolset.backButton.snp.makeConstraints { make in
            make.leading.equalTo(safeAreaLayoutGuide).offset(UIConstants.layout.urlBarMargin)
            make.centerY.equalTo(self)
            make.width.equalTo(self).multipliedBy(toolsetButtonWidthMultiplier)
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
            make.height.equalTo(42).priority(.medium)
            make.top.bottom.equalToSuperview().inset(UIConstants.layout.urlBarMargin)

            compressedBarConstraints.append(make.height.equalTo(48).constraint)
            compressedBarConstraints.append(make.trailing.equalTo(safeAreaLayoutGuide.snp.trailing).inset(UIConstants.layout.urlBarMargin).constraint)

            expandedBarConstraints.append(make.trailing.equalTo(rightBarViewLayoutGuide.snp.leading).constraint)

            showLeftBarViewConstraints.append(make.leading.equalTo(leftBarViewLayoutGuide.snp.trailing).offset(UIConstants.layout.urlBarIconInset).constraint)
            hideLeftBarViewConstraints.append(make.leading.equalTo(safeAreaLayoutGuide.snp.leading).offset(UIConstants.layout.urlBarMargin).constraint)
        }

        urlBarBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIConstants.layout.urlBarBorderInset)
        }

        shieldIcon.snp.makeConstraints { (make) in
            make.top.bottom.leading.trailing.equalTo(leftBarViewLayoutGuide)
        }

        cancelButton.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalTo(leftBarViewLayoutGuide)
        }

        deleteButton.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalTo(rightBarViewLayoutGuide)
        }

        textAndLockContainer.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().priority(999)

            centeredURLConstraints.append(make.centerX.equalToSuperview().constraint)
            fullWidthURLConstraints.append(make.trailing.equalToSuperview().constraint)
        }

        pageActionsButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(textAndLockContainer).priority(.required)
            make.width.equalTo(UIConstants.layout.urlBarButtonTargetSize).priority(900)
        }

        lockIcon.snp.makeConstraints { make in
            make.top.bottom.equalTo(textAndLockContainer)
            make.leading.equalTo(textAndLockContainer).inset(UIConstants.layout.lockIconInset).priority(999)
        }

        urlText.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()

            hideLockConstraints.append(make.leading.equalToSuperview().constraint)
            // Account for the content inset of the URLTextField to balance
            // the spacing around the lock icon
            showLockConstraints.append(make.leading.equalTo(lockIcon.snp.trailing).inset(UIConstants.layout.lockIconInset - 4).constraint)
            hidePageActionsConstraints.append(make.trailing.equalToSuperview().constraint)
            showPageActionsConstraints.append(make.trailing.equalTo(pageActionsButton.snp.leading).constraint)
        }

        toolset.settingsButton.snp.makeConstraints { make in
            make.trailing.equalTo(safeAreaLayoutGuide)
            make.centerY.equalTo(self)
            make.size.equalTo(toolset.backButton)
        }

        progressBar.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.bottom.equalTo(self).offset(UIConstants.layout.progressBarHeight)
            make.height.equalTo(UIConstants.layout.progressBarHeight)
        }

        smallLockIcon.snp.makeConstraints { make in
            make.leading.equalTo(collapsedUrlAndLockWrapper)
            make.trailing.equalTo(truncatedUrlText.snp.leading)
            make.bottom.equalTo(self)
        }

        collapsedTrackingProtectionBadge.snp.makeConstraints { make in
            make.leading.equalTo(safeAreaLayoutGuide).offset(UIConstants.layout.collapsedProtectionBadgeOffset)
            make.width.height.equalTo(smallLockIcon)
            make.bottom.top.equalTo(smallLockIcon)
        }

        truncatedUrlText.snp.makeConstraints { make in
            make.leading.equalTo(smallLockIcon.snp.trailing)
            make.trailing.equalTo(collapsedUrlAndLockWrapper)
            make.bottom.equalTo(smallLockIcon).offset(UIConstants.layout.truncatedUrlTextOffset)
        }

        collapsedUrlAndLockWrapper.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.bottom.equalTo(smallLockIcon)
            make.height.equalTo(UIConstants.layout.collapsedUrlBarHeight)
            make.leading.equalTo(smallLockIcon)
            make.trailing.equalTo(truncatedUrlText)
        }

        hideLeftBarViewConstraints.forEach { $0.activate() }
        showLeftBarViewConstraints.forEach { $0.deactivate() }
        showToolsetConstraints.forEach { $0.deactivate() }
        expandedBarConstraints.forEach { $0.activate() }
        updateToolsetConstraints()
    }

    @objc public func activateTextField() {
        urlText.isUserInteractionEnabled = true
        urlText.becomeFirstResponder()
    }

    private func displayClearButton(shouldDisplay: Bool, animated: Bool = true) {
        // Prevent the rightView's position from being animated
        urlText.rightView?.layer.removeAllAnimations()
        urlText.rightView?.animateHidden(!shouldDisplay, duration: animated ? UIConstants.layout.urlBarTransitionAnimationDuration : 0)
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
        isEditing = true
        urlText.text = clipboardString
        activateTextField()
    }

    @objc func pasteAndGo(clipboardString: String) {
        isEditing = true
        delegate?.urlBarDidActivate(self)
        delegate?.urlBar(self, didSubmitText: clipboardString)

        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.pasteAndGo)
    }

    @objc func pasteAndGoFromContextMenu() {
        guard let clipboardString = UIPasteboard.general.string else { return }
        pasteAndGo(clipboardString: clipboardString)
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

    var shouldShowToolset: Bool = false {
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
        inBrowsingMode = true
        isEditing = false
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
                self.showLockConstraints.forEach { $0.activate() }
                self.hideSmallLockConstraints.forEach { $0.deactivate() }
            } else {
                self.showLockConstraints.forEach { $0.deactivate() }
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

        self.layoutIfNeeded()

        UIView.animate(withDuration: duration) {
            if visible {
                self.hidePageActionsConstraints.forEach { $0.deactivate() }
                self.showPageActionsConstraints.forEach { $0.activate() }
            } else {
                self.showPageActionsConstraints.forEach { $0.deactivate() }
                self.hidePageActionsConstraints.forEach { $0.activate() }
            }
            self.layoutIfNeeded()
        }
    }

    private func updateBarState() {
        if isEditing {
            state = .editing
        } else if inBrowsingMode {
            state = .browsing
        } else {
            state = .default
        }
    }

    private func updateViews() {
        self.updateToolsetConstraints()
        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration, animations: {
            self.layoutIfNeeded()
        })

        updateLockIcon()
        updateUrlIcons()
        displayClearButton(shouldDisplay: false)
        self.layoutIfNeeded()

        let borderColor: UIColor
        let backgroundColor: UIColor
        let showBackgroundView: Bool

        switch state {
        case .default:
            showLeftBar = false
            compressBar = true
            showBackgroundView = true

            shieldIcon.animateHidden(true, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
            cancelButton.animateHidden(true, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
            deleteButton.animateHidden(true, duration: UIConstants.layout.urlBarTransitionAnimationDuration)

            setTextToURL()
            deactivate()
            borderColor = UIConstants.Photon.Grey10.withAlphaComponent(0.1)
            backgroundColor = UIConstants.Photon.Grey10.withAlphaComponent(0.2)
        case .browsing:
            showLeftBar = true
            compressBar = false
            showBackgroundView = false

            shieldIcon.animateHidden(false, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
            cancelButton.animateHidden(true, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
            deleteButton.animateHidden(false, duration: UIConstants.layout.urlBarTransitionAnimationDuration)

            setTextToURL()
            borderColor = UIConstants.Photon.Grey90.withAlphaComponent(0.2)
            backgroundColor = UIConstants.Photon.Grey10.withAlphaComponent(0.2)
        case .editing:
            showLeftBar = true
            compressBar = true
            showBackgroundView = true

            shieldIcon.animateHidden(true, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
            cancelButton.animateHidden(false, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
            deleteButton.animateHidden(true, duration: UIConstants.layout.urlBarTransitionAnimationDuration)

            toolset.settingsButton.isEnabled = true
            borderColor = UIConstants.Photon.Grey10.withAlphaComponent(0.1)
            backgroundColor = UIConstants.Photon.Grey10.withAlphaComponent(0.2)
        }

        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration, animations: {
            self.layoutIfNeeded()

            self.urlBarBackgroundView.snp.remakeConstraints { make in
                make.edges.equalToSuperview().inset(showBackgroundView ? UIConstants.layout.urlBarBorderInset : 1)
            }

            self.urlBarBorderView.backgroundColor = borderColor
            self.urlBarBackgroundView.backgroundColor = backgroundColor
        }, completion: { finished in
            if finished {
                self.displayClearButton(shouldDisplay: self.isEditing)
            }
        })
    }

    /* This separate @objc function is necessary as selector methods pass sender by default. Calling
     dismiss() directly from a selector would pass the sender as "completion" which results in a crash. */
    @objc func cancelPressed() {
        isEditing = false
    }

    func dismiss(completion: (() -> Void)? = nil) {
        guard isEditing else {
            completion?()
            return
        }

        isEditing = false
        completion?()
    }

    @objc private func didSingleTap(sender: UITapGestureRecognizer) {
        delegate?.urlBarDidPressScrollTop(self, tap: sender)
    }

    /// Show the URL toolset buttons if we're on iPad/landscape and not editing; hide them otherwise.
    /// This method is intended to be called inside `UIView.animate` block.
    private func updateToolsetConstraints() {
        let isHidden: Bool

        switch state {
        case .default:
            isHidden = true
            showToolset = false
            centerURLBar = false
        case .browsing:
            isHidden = !shouldShowToolset
            showToolset = !isHidden
            centerURLBar = shouldShowToolset
        case .editing:
            isHidden = true
            showToolset = false
            centerURLBar = false
        }

        toolset.backButton.animateHidden(isHidden, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
        toolset.forwardButton.animateHidden(isHidden, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
        toolset.stopReloadButton.animateHidden(isHidden, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
        toolset.settingsButton.animateHidden(isHidden, duration: UIConstants.layout.urlBarTransitionAnimationDuration)

    }

    @objc private func didPressDelete() {
        // Prevent layout issues where the user taps Erase and the URL at the same time.
        guard !isEditing else { return }

        isUserInteractionEnabled = false

        delegate?.urlBarDidPressDelete(self)
    }

    @objc private func didPressClear() {
        urlText.text = nil
        userInputText = nil
        displayClearButton(shouldDisplay: false)
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
        displayClearButton(shouldDisplay: false)

        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration, animations: {
            self.layoutIfNeeded()
        })

        delegate?.urlBarDidDeactivate(self)
    }

    @objc private func didPressPageActions() {
        delegate?.urlBarDidPressPageActions(self)
    }

    private func setTextToURL(displayFullUrl: Bool = false) {
        var fullUrl: String?
        var truncatedURL: String?
        var displayText: String?

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

    private func activateConstraints(_ activate: Bool, shownConstraints: [Constraint]?, hiddenConstraints: [Constraint]?) {
        (activate ? hiddenConstraints : shownConstraints)?.forEach { $0.deactivate() }
        (activate ? shownConstraints : hiddenConstraints)?.forEach { $0.activate() }
    }

    func collapseUrlBar(expandAlpha: CGFloat, collapseAlpha: CGFloat) {
        urlBarBorderView.alpha = expandAlpha
        urlBarBackgroundView.alpha = expandAlpha
        truncatedUrlText.alpha = collapseAlpha
        collapsedUrlAndLockWrapper.alpha = collapseAlpha
        toolset.backButton.alpha = shouldShowToolset ? expandAlpha : 0
        toolset.forwardButton.alpha = shouldShowToolset ? expandAlpha : 0
        toolset.stopReloadButton.alpha = shouldShowToolset ? expandAlpha : 0
        toolset.settingsButton.alpha = shouldShowToolset ? expandAlpha : 0

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
            isEditing = true
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

        if Settings.getToggle(.enableSearchSuggestions) {
            Telemetry.default.recordEvent(TelemetryEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.searchSuggestionNotSelected))
        }

        return true
    }

    func autocompleteTextField(_ autocompleteTextField: AutocompleteTextField, didTextChange text: String) {
        userInputText = text

        autocompleteTextField.rightView?.isHidden = text.isEmpty

        if !isEditing && shouldPresent {
            isEditing = true
            delegate?.urlBarDidActivate(self)
        }

        delegate?.urlBar(self, didEnterText: text)
    }
}

extension URLBar: UIDragInteractionDelegate {
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        guard let url = url, let itemProvider = NSItemProvider(contentsOf: url) else { return [] }
        let dragItem = UIDragItem(itemProvider: itemProvider)
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.drag, object: TelemetryEventObject.searchBar)
        return [dragItem]
    }

    func dragInteraction(_ interaction: UIDragInteraction, previewForLifting item: UIDragItem, session: UIDragSession) -> UITargetedDragPreview? {
        let params = UIDragPreviewParameters()
        params.backgroundColor = UIColor.clear
        return UITargetedDragPreview(view: draggableUrlTextView, parameters: params)
    }

    func dragInteraction(_ interaction: UIDragInteraction, sessionDidMove session: UIDragSession) {
        for item in session.items {
            item.previewProvider = {
                guard let url = self.url else {
                    return UIDragPreview(view: UIView())
                }
                return UIDragPreview(for: url)
            }
        }
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
            make.width.height.equalTo(UIConstants.layout.trackingProtectionHeight)
        }

        trackingProtectionOff.snp.makeConstraints { make in
            make.leading.centerY.equalTo(self)
            make.width.height.equalTo(UIConstants.layout.trackingProtectionHeight)
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
