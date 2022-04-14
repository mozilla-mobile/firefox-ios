/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Telemetry
import Glean

protocol URLBarDelegate: AnyObject {
    func urlBar(_ urlBar: URLBar, didEnterText text: String)
    func urlBar(_ urlBar: URLBar, didSubmitText text: String)
    func urlBar(_ urlBar: URLBar, didAddCustomURL url: URL)
    func urlBarDidActivate(_ urlBar: URLBar)
    func urlBarDidDeactivate(_ urlBar: URLBar)
    func urlBarDidFocus(_ urlBar: URLBar)
    func urlBarDidPressScrollTop(_: URLBar, tap: UITapGestureRecognizer)
    func urlBarDidDismiss(_ urlBar: URLBar)
    func urlBarDidTapShield(_ urlBar: URLBar)
    func urlBarDidLongPress(_ urlBar: URLBar)
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
            DispatchQueue.main.async {
                self.updateBarState()
            }
        }
    }
    private(set) var isEditing = false {
        didSet {
            DispatchQueue.main.async {
                self.updateBarState()
            }
        }
    }
    var shouldPresent = false
    
    public var contextMenuButton: InsetButton { toolset.contextMenuButton }
    public var deleteButton: InsetButton { toolset.deleteButton }
    
    private let leftBarViewLayoutGuide = UILayoutGuide()
    private let rightBarViewLayoutGuide = UILayoutGuide()

    private let cancelButton = InsetButton()
    private let domainCompletion = DomainCompletion(completionSources: [TopDomainsCompletionSource(), CustomCompletionSource()])

    private let toolset = BrowserToolset()
    private let urlText = URLTextField()
    var draggableUrlTextView: UIView { return urlText }
    private let truncatedUrlText = UITextView()
    private let urlBarBorderView = UIView()
    private let urlBarBackgroundView = UIView()
    private let textAndLockContainer = UIView()
    private let collapsedUrlAndLockWrapper = UIView()
    private let collapsedTrackingProtectionBadge = CollapsedTrackingProtectionBadge()

    let shieldIcon = TrackingProtectionBadge()

    var centerURLBar = false {
        didSet {
            guard oldValue != centerURLBar else { return }
            activateConstraints(centerURLBar, shownConstraints: centeredURLConstraints, hiddenConstraints: fullWidthURLConstraints)
        }
    }
    private var centeredURLConstraints = [Constraint]()
    private var fullWidthURLConstraints = [Constraint]()
    var editingURLTextConstrains = [Constraint]()
    var isIPadRegularDimensions = false {
        didSet {
            updateViews()
            updateURLBarLayoutAfterSplitView()
        }
    }
    
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
            isIPadRegularDimensions = showToolset
            activateConstraints(showToolset, shownConstraints: showToolsetConstraints, hiddenConstraints: hideToolsetConstraints)
            guard UIDevice.current.orientation.isLandscape && UIDevice.current.userInterfaceIdiom == .phone else { return }
            showToolset = false
        }
    }
    private var hideToolsetConstraints = [Constraint]()
    private var showToolsetConstraints = [Constraint]()

    private var compressBar = true {
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

    override var canBecomeFirstResponder: Bool {
        return true
    }

    convenience init() {
        self.init(frame: CGRect.zero)
        isIPadRegularDimensions = traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(didSingleTap(sender:)))
        singleTap.numberOfTapsRequired = 1
        textAndLockContainer.addGestureRecognizer(singleTap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(displayURLContextMenu))
        textAndLockContainer.addGestureRecognizer(longPress)

        let dragInteraction = UIDragInteraction(delegate: self)
        textAndLockContainer.addInteraction(dragInteraction)

        addSubview(toolset.backButton)
        addSubview(toolset.forwardButton)
        addSubview(toolset.deleteButton)
        addSubview(toolset.contextMenuButton)

        urlText.isUserInteractionEnabled = false
        urlBarBackgroundView.addSubview(textAndLockContainer)

        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.numberOfTapsRequired = 1
        gestureRecognizer.cancelsTouchesInView = true
        gestureRecognizer.addTarget(self, action: #selector(didTapShieldIcon))
        shieldIcon.isUserInteractionEnabled = true
        shieldIcon.addGestureRecognizer(gestureRecognizer)
        shieldIcon.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        shieldIcon.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)

        cancelButton.isHidden = true
        cancelButton.alpha = 0
        cancelButton.setImage(#imageLiteral(resourceName: "icon_cancel"), for: .normal)

        cancelButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        cancelButton.addTarget(self, action: #selector(cancelPressed), for: .touchUpInside)
        cancelButton.accessibilityIdentifier = "URLBar.cancelButton"
        addSubview(cancelButton)

        textAndLockContainer.addSubview(toolset.stopReloadButton)

        urlBarBorderView.backgroundColor = .secondaryButton
        urlBarBorderView.layer.cornerRadius = UIConstants.layout.urlBarCornerRadius
        urlBarBorderView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        urlBarBorderView.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        addSubview(urlBarBorderView)

        urlBarBackgroundView.backgroundColor = .locationBar
        urlBarBackgroundView.layer.cornerRadius = UIConstants.layout.urlBarCornerRadius
        urlBarBackgroundView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        urlBarBackgroundView.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        urlBarBorderView.addSubview(urlBarBackgroundView)

        truncatedUrlText.alpha = 0
        truncatedUrlText.isUserInteractionEnabled = false
        truncatedUrlText.font = .footnote12
        truncatedUrlText.tintColor = .primaryText
        truncatedUrlText.textColor = .primaryText
        truncatedUrlText.backgroundColor = UIColor.clear
        truncatedUrlText.contentMode = .bottom
        truncatedUrlText.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .vertical)
        truncatedUrlText.isScrollEnabled = false
        truncatedUrlText.accessibilityIdentifier = "Collapsed.truncatedUrlText"

        collapsedTrackingProtectionBadge.alpha = 0
        collapsedTrackingProtectionBadge.tintColor = .white
        collapsedTrackingProtectionBadge.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        collapsedTrackingProtectionBadge.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)

        collapsedUrlAndLockWrapper.addSubview(truncatedUrlText)
        collapsedUrlAndLockWrapper.addSubview(collapsedTrackingProtectionBadge)
        addSubview(collapsedUrlAndLockWrapper)

        // UITextField doesn't allow customization of the clear button, so we create
        // our own so we can use it as the rightView.
        let clearButton = UIButton(frame: CGRect(x: 0, y: 0, width: UIConstants.layout.urlBarClearButtonWidth, height: UIConstants.layout.urlBarClearButtonHeight))
        clearButton.isHidden = true
        clearButton.setImage(#imageLiteral(resourceName: "icon_clear"), for: .normal)
        clearButton.addTarget(self, action: #selector(didPressClear), for: .touchUpInside)

        urlText.font = .body15
        urlText.tintColor = .primaryText
        urlText.textColor = .primaryText
        urlText.highlightColor = .accent.withAlphaComponent(0.4)
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
        
        shieldIcon.tintColor = .primaryText
        shieldIcon.contentMode = .center
        shieldIcon.accessibilityIdentifier = "URLBar.trackingProtectionIcon"
        addSubview(shieldIcon)

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

            hideToolsetConstraints.append(make.leading.equalTo(leftBarViewLayoutGuide).offset(UIConstants.layout.urlBarMargin).constraint)
            
            showToolsetConstraints.append(make.leading.equalTo( toolset.forwardButton.snp.trailing).offset(UIConstants.layout.urlBarToolsetOffset).constraint)
        }

        addLayoutGuide(rightBarViewLayoutGuide)
        rightBarViewLayoutGuide.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.equalTo(UIConstants.layout.urlBarButtonTargetSize)

            hideToolsetConstraints.append(make.trailing.equalTo(toolset.contextMenuButton.snp.leading).offset(-UIConstants.layout.urlBarIPadToolsetOffset).constraint)
            
            showToolsetConstraints.append(make.trailing.equalTo(toolset.contextMenuButton.snp.leading).offset(-UIConstants.layout.urlBarIPadToolsetOffset).constraint)
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

        toolset.contextMenuButton.snp.makeConstraints { make in
            if inBrowsingMode {
                make.trailing.equalTo(safeAreaLayoutGuide)
            } else {
                make.trailing.equalTo(safeAreaLayoutGuide).offset(-UIConstants.layout.contextMenuButtonMargin)
            }
            make.centerY.equalTo(self)
            make.size.equalTo(UIConstants.layout.contextMenuButtonSize)
        }
        
        toolset.deleteButton.snp.makeConstraints { make in
            make.trailing.equalTo(toolset.contextMenuButton.snp.leading).inset(isIPadRegularDimensions ? UIConstants.layout.deleteButtonOffset : UIConstants.layout.deleteButtonMarginContextMenu)
            make.centerY.equalTo(self)
            make.size.equalTo(toolset.backButton)
        }

        urlBarBorderView.snp.makeConstraints { make in
            make.height.equalTo(UIConstants.layout.urlBarBorderHeight).priority(.medium)
            make.top.bottom.equalToSuperview().inset(UIConstants.layout.urlBarMargin)

            compressedBarConstraints.append(make.height.equalTo(UIConstants.layout.urlBarBorderHeight).constraint)
            if inBrowsingMode {
                compressedBarConstraints.append(make.trailing.equalTo(safeAreaLayoutGuide.snp.trailing).inset(UIConstants.layout.urlBarMargin).constraint)
            } else {
                compressedBarConstraints.append(make.trailing.equalTo(contextMenuButton.snp.leading).offset(-UIConstants.layout.contextMenuButtonMargin).constraint)
            }

            expandedBarConstraints.append(make.trailing.equalTo(rightBarViewLayoutGuide.snp.trailing).constraint)

            showLeftBarViewConstraints.append(make.leading.equalTo(leftBarViewLayoutGuide.snp.trailing).offset(UIConstants.layout.urlBarIconInset).constraint)
            
            hideLeftBarViewConstraints.append(make.leading.equalTo(shieldIcon.snp.leading).offset(-UIConstants.layout.urlBarIconInset).constraint)
            
            showToolsetConstraints.append(make.leading.equalTo(leftBarViewLayoutGuide.snp.leading).offset(UIConstants.layout.urlBarIconInset).constraint)
        }

        urlBarBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIConstants.layout.urlBarBorderInset)
        }

        addShieldConstraints()

        cancelButton.snp.makeConstraints { make in
            make.leading.trailing.equalTo(leftBarViewLayoutGuide)
            make.top.bottom.equalToSuperview()
        }

        textAndLockContainer.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().priority(999)
            
            showLeftBarViewConstraints.append(make.leading.equalTo(leftBarViewLayoutGuide.snp.trailing).offset(UIConstants.layout.urlBarIconInset).constraint)

            hideLeftBarViewConstraints.append(make.leading.equalToSuperview().offset(UIConstants.layout.urlBarTextInset).constraint)
            
            centeredURLConstraints.append(make.centerX.equalToSuperview().constraint)
            fullWidthURLConstraints.append(make.trailing.equalToSuperview().constraint)
        }

        toolset.stopReloadButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(urlBarBorderView).priority(.required)
            make.width.equalTo(UIConstants.layout.urlBarButtonTargetSize).priority(900)
        }

        urlText.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(shieldIcon.snp.trailing).offset(5)

            showLeftBarViewConstraints.append(make.left.equalToSuperview().constraint)
            
            hidePageActionsConstraints.append(make.trailing.equalToSuperview().constraint)
            showPageActionsConstraints.append(make.trailing.equalTo(toolset.stopReloadButton.snp.leading).constraint)
        }

        progressBar.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.bottom.equalTo(self).offset(UIConstants.layout.progressBarHeight)
            make.height.equalTo(UIConstants.layout.progressBarHeight)
        }

        collapsedTrackingProtectionBadge.snp.makeConstraints { make in
            make.leading.equalTo(safeAreaLayoutGuide).offset(UIConstants.layout.collapsedProtectionBadgeOffset)
            make.width.height.equalTo(10)
            make.bottom.equalToSuperview()
        }

        truncatedUrlText.snp.makeConstraints { make in
            make.centerY.equalTo(self).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(UIConstants.layout.truncatedUrlTextOffset)
        }

        collapsedUrlAndLockWrapper.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.bottom.equalTo(truncatedUrlText)
            make.height.equalTo(UIConstants.layout.collapsedUrlBarHeight)
            make.leading.equalTo(truncatedUrlText)
            make.trailing.equalTo(truncatedUrlText)
        }

        hideLeftBarViewConstraints.forEach { $0.activate() }
        showLeftBarViewConstraints.forEach { $0.deactivate() }
        showToolsetConstraints.forEach { $0.deactivate() }
        expandedBarConstraints.forEach { $0.activate() }
        updateToolsetConstraints()
    }
    
    private func addShieldConstraints() {
        shieldIcon.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(leftBarViewLayoutGuide).inset(isIPadRegularDimensions ? UIConstants.layout.shieldIconIPadInset : UIConstants.layout.shieldIconInset)
            make.width.equalTo(UIConstants.layout.urlButtonSize)
        }
    }
    
    private func updateURLBarLayoutAfterSplitView() {
        
        shieldIcon.snp.removeConstraints()
        addShieldConstraints()
        
        if isIPadRegularDimensions {
            leftBarViewLayoutGuide.snp.remakeConstraints { (make) in
                make.leading.equalTo(toolset.forwardButton.snp.trailing).offset(UIConstants.layout.urlBarToolsetOffset)
            }
        } else {
            leftBarViewLayoutGuide.snp.makeConstraints { make in
                make.leading.equalTo(safeAreaLayoutGuide).offset(UIConstants.layout.urlBarMargin)
            }
            
        }
        
        
        rightBarViewLayoutGuide.snp.makeConstraints { (make) in
            if  isIPadRegularDimensions {
                make.trailing.equalTo(toolset.contextMenuButton.snp.leading).offset(-UIConstants.layout.urlBarIPadToolsetOffset)
            } else {
                make.trailing.greaterThanOrEqualTo(toolset.contextMenuButton.snp.leading).offset(-UIConstants.layout.urlBarToolsetOffset)
            }
        }
    }

    @objc public func activateTextField() {
        urlText.isUserInteractionEnabled = true
        urlText.becomeFirstResponder()
        isEditing = true
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
    
    public func setHighlightWhatsNew(shouldHighlight: Bool) {
        toolset.setHighlightWhatsNew(shouldHighlight: shouldHighlight)
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
        activateTextField()
        urlText.text = clipboardString
    }

    @objc func pasteAndGo(clipboardString: String) {
        isEditing = true
        delegate?.urlBarDidActivate(self)
        delegate?.urlBar(self, didSubmitText: clipboardString)

        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.pasteAndGo)
        GleanMetrics.UrlInteraction.pasteAndGo.record()
    }

    @objc func pasteAndGoFromContextMenu() {
        guard let clipboardString = UIPasteboard.general.string else { return }
        pasteAndGo(clipboardString: clipboardString)
    }
    
    @objc func copyLink() {
        self.url
            .map(\.absoluteString)
            .map { UIPasteboard.general.string = $0 }
    }

    // Adds Menu Item
    func addCustomMenu() {
        var items = [UIMenuItem]()
        
        if urlText.text != nil, urlText.text?.isEmpty == false {
            let copyItem = UIMenuItem(title: UIConstants.strings.copyMenuButton, action: #selector(copyLink))
            items.append(copyItem)
        }
        
        if UIPasteboard.general.hasStrings {
            let lookupMenu = UIMenuItem(title: UIConstants.strings.urlPasteAndGo, action: #selector(pasteAndGoFromContextMenu))
            items.append(lookupMenu)
        }
        
        UIMenuController.shared.menuItems = items
    }
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        addCustomMenu()
        return super.canPerformAction(action, withSender: sender)
    }
    var url: URL? = nil {
        didSet {
            if !urlText.isEditing {
                setTextToURL()
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
    
    var canDelete: Bool = false {
        didSet {
            toolset.canDelete = canDelete
        }
    }

    var isLoading: Bool = false {
        didSet {
            toolset.isLoading = isLoading
        }
    }

    var shouldShowToolset: Bool = false {
        didSet {
            updateViews()
            updateToolsetConstraints()
        }
    }

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

    private func updateUrlIcons() {
        let visible = !isEditing && url != nil
        let duration = UIConstants.layout.urlBarTransitionAnimationDuration / 2

        toolset.stopReloadButton.animateHidden(!visible, duration: duration)

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

        updateUrlIcons()
        displayClearButton(shouldDisplay: false)
        self.layoutIfNeeded()

        let borderColor: UIColor
        let showBackgroundView: Bool

        switch state {
        case .default:
            showLeftBar = false
            compressBar = isIPadRegularDimensions ? false : true
            showBackgroundView = true

            shieldIcon.animateHidden(false, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
            cancelButton.animateHidden(true, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
            
            setTextToURL()
            deactivate()
            borderColor = .foundation
            backgroundColor = .clear
            
        case .browsing:
            showLeftBar = shouldShowToolset ? true : false
            compressBar = isIPadRegularDimensions ? false : true
            showBackgroundView = false

            shieldIcon.animateHidden(false, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
            cancelButton.animateHidden(true, duration: UIConstants.layout.urlBarTransitionAnimationDuration)

            setTextToURL()
            borderColor = .foundation
            backgroundColor = .clear

            editingURLTextConstrains.forEach{$0.deactivate()}
            urlText.snp.makeConstraints{make in
                make.leading.equalTo(shieldIcon.snp.trailing).offset(UIConstants.layout.urlTextOffset)
            }
 
        case .editing:
            showLeftBar = !shouldShowToolset && isIPadRegularDimensions ? false : true
            compressBar = isIPadRegularDimensions ? false : true
            showBackgroundView = true
            
            if isIPadRegularDimensions && inBrowsingMode {
                leftBarViewLayoutGuide.snp.makeConstraints{make in
                    editingURLTextConstrains.append(make.leading.equalTo(urlText).offset(-UIConstants.layout.urlTextOffset).constraint)
                }
                editingURLTextConstrains.forEach{$0.activate()}
                toolset.stopReloadButton.animateHidden(true, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
            }
            if !isIPadRegularDimensions {
                leftBarViewLayoutGuide.snp.makeConstraints { make in
                    make.leading.equalTo(safeAreaLayoutGuide).offset(UIConstants.layout.urlBarMargin)
                }
            }
            
            shieldIcon.animateHidden(true, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
            cancelButton.animateHidden(isIPadRegularDimensions ? true : false, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
            toolset.contextMenuButton.isEnabled = true
            borderColor = .foundation
            backgroundColor = .clear
        }

        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration, animations: {
            self.layoutIfNeeded()
            
            if self.inBrowsingMode && !self.isIPadRegularDimensions {
                self.updateURLBorderConstraints()
            }
            
            self.urlBarBackgroundView.snp.remakeConstraints { make in
                make.edges.equalToSuperview().inset(showBackgroundView ? UIConstants.layout.urlBarBorderInset : 1)
            }

            self.urlBarBorderView.backgroundColor = borderColor
        }, completion: { finished in
            if finished {
                if let isEmpty = self.urlText.text?.isEmpty {
                    self.displayClearButton(shouldDisplay: !isEmpty)
                }
            }
        })
    }
    
    func updateURLBorderConstraints() {
        self.urlBarBorderView.snp.remakeConstraints { make in
            make.height.equalTo(UIConstants.layout.urlBarBorderHeight).priority(.medium)
            make.top.bottom.equalToSuperview().inset(UIConstants.layout.urlBarMargin)
            
            compressedBarConstraints.append(make.height.equalTo(UIConstants.layout.urlBarBorderHeight).constraint)
            if inBrowsingMode {
                compressedBarConstraints.append(make.trailing.equalTo(safeAreaLayoutGuide.snp.trailing).inset(UIConstants.layout.urlBarMargin).constraint)
            } else {
                compressedBarConstraints.append(make.trailing.equalTo(contextMenuButton.snp.leading).offset(-UIConstants.layout.urlBarMargin).constraint)
            }
            
            if isEditing {
                make.leading.equalTo(leftBarViewLayoutGuide.snp.trailing).offset(UIConstants.layout.urlBarIconInset)
            } else {
                make.leading.equalTo(shieldIcon.snp.leading).offset(-UIConstants.layout.urlBarIconInset)
            }
        }
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
            let isiPadLayoutWhileBrowsing = isIPadRegularDimensions && inBrowsingMode
            isHidden =  isiPadLayoutWhileBrowsing ? !shouldShowToolset : true
            showToolset = isiPadLayoutWhileBrowsing ? !isHidden : false
            centerURLBar = false
        }

        toolset.backButton.animateHidden(isHidden, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
        toolset.forwardButton.animateHidden(isHidden, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
        toolset.deleteButton.animateHidden(isHidden, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
        toolset.contextMenuButton.animateHidden(!inBrowsingMode ? false : (isIPadRegularDimensions ? false : isHidden), duration: UIConstants.layout.urlBarTransitionAnimationDuration)

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

    @objc private func displayURLContextMenu(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            delegate?.urlBarDidLongPress(self)
            self.isUserInteractionEnabled = true
            self.becomeFirstResponder()
            UIMenuController.shared.showMenu(from: self, rect: self.bounds)
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

    private func setTextToURL(displayFullUrl: Bool = false) {
        guard let url = url else { return }

        // Strip the username/password to prevent domain spoofing.
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.user = nil
        components?.password = nil
        let fullUrl = components?.url?.absoluteString
        let truncatedURL = components?.host
        let displayText = truncatedURL
        urlText.text = displayFullUrl ? fullUrl : displayText
        truncatedUrlText.text = truncatedURL
    }

    private func activateConstraints(_ activate: Bool, shownConstraints: [Constraint]?, hiddenConstraints: [Constraint]?) {
        (activate ? hiddenConstraints : shownConstraints)?.forEach { $0.deactivate() }
        (activate ? shownConstraints : hiddenConstraints)?.forEach { $0.activate() }
    }
    
    enum CollapsedState: Equatable {
        case extended
        case intermediate(expandAlpha: CGFloat, collapseAlpha: CGFloat)
        case collapsed
    }
    
    var collapsedState: CollapsedState = .extended {
        didSet {
            DispatchQueue.main.async {
                self.updateCollapsedState()
            }
        }
    }
    
    func updateCollapsedState() {
        switch collapsedState {
        case .extended:
            collapseUrlBar(expandAlpha: 1, collapseAlpha: 0)
        case .intermediate(expandAlpha: let expandAlpha, collapseAlpha: let collapseAlpha):
            collapseUrlBar(expandAlpha: expandAlpha, collapseAlpha: collapseAlpha)
        case .collapsed:
            collapseUrlBar(expandAlpha: 0, collapseAlpha: 1)
        }
    }

    private func collapseUrlBar(expandAlpha: CGFloat, collapseAlpha: CGFloat) {
        urlBarBorderView.alpha = expandAlpha
        urlBarBackgroundView.alpha = expandAlpha
        truncatedUrlText.alpha = collapseAlpha
        collapsedUrlAndLockWrapper.alpha = collapseAlpha
        toolset.backButton.alpha = shouldShowToolset ? expandAlpha : 0
        toolset.forwardButton.alpha = shouldShowToolset ? expandAlpha : 0
        toolset.deleteButton.alpha = shouldShowToolset ? expandAlpha : 0
        toolset.contextMenuButton.alpha = expandAlpha

        collapsedTrackingProtectionBadge.alpha = 0
        if isEditing {
            shieldIcon.alpha = collapseAlpha
        } else {
            shieldIcon.alpha = expandAlpha
        }

        self.layoutIfNeeded()
    }

    func updateTrackingProtectionBadge(trackingStatus: TrackingProtectionStatus, shouldDisplayShieldIcon: Bool) {
        shieldIcon.updateState(trackingStatus: trackingStatus, shouldDisplayShieldIcon: shouldDisplayShieldIcon)
        collapsedTrackingProtectionBadge.updateState(trackingStatus: trackingStatus, shouldDisplayShieldIcon: shouldDisplayShieldIcon)
    }
}

extension URLBar: AutocompleteTextFieldDelegate {
    func autocompleteTextFieldShouldBeginEditing(_ autocompleteTextField: AutocompleteTextField) -> Bool {

        setTextToURL(displayFullUrl: true)
        autocompleteTextField.highlightAll()

        if !isEditing {
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
        
        if !text.isEmpty {
            displayClearButton(shouldDisplay: true, animated: true)
        }

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
        GleanMetrics.UrlInteraction.dragStarted.record()
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
            attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: [.foregroundColor: UIColor.secondaryText])
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
        let inset = bounds.insetBy(dx: UIConstants.layout.urlBarWidthInset, dy: UIConstants.layout.urlBarContainerHeightInset)

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
    let trackingProtectionOff = UIImageView(image: .trackingProtectionOff)
    let trackingProtectionOn = UIImageView(image: .trackingProtectionOn)
    let connectionNotSecure = UIImageView(image: .connectionNotSecure)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setupViews()
    }

    func setupViews() {
        trackingProtectionOff.alpha = 0
        connectionNotSecure.alpha = 0
        trackingProtectionOn.contentMode = .scaleAspectFit
        trackingProtectionOff.contentMode = .scaleAspectFit
        connectionNotSecure.contentMode = .scaleAspectFit

        addSubview(trackingProtectionOff)
        addSubview(trackingProtectionOn)
        addSubview(connectionNotSecure)

        trackingProtectionOn.setContentHuggingPriority(.required, for: .horizontal)
        trackingProtectionOn.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.width.equalTo(UIConstants.layout.urlButtonSize)
        }

        trackingProtectionOff.setContentHuggingPriority(.required, for: .horizontal)
        trackingProtectionOff.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.width.equalTo(UIConstants.layout.urlButtonSize)
        }
        
        connectionNotSecure.setContentHuggingPriority(.required, for: .horizontal)
        connectionNotSecure.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.width.equalTo(UIConstants.layout.urlButtonSize)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateState(trackingStatus: TrackingProtectionStatus, shouldDisplayShieldIcon: Bool) {
        guard shouldDisplayShieldIcon else {
            trackingProtectionOn.alpha = 0
            trackingProtectionOff.alpha = 0
            connectionNotSecure.alpha = 1
            return
        }
        switch trackingStatus {
        case .on:
            trackingProtectionOff.alpha = 0
            trackingProtectionOn.alpha = 1
            connectionNotSecure.alpha = 0
        default:
            trackingProtectionOff.alpha = 1
            trackingProtectionOn.alpha = 0
            connectionNotSecure.alpha = 0
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
        addSubview(connectionNotSecure)

        trackingProtectionOn.snp.makeConstraints { make in
            make.leading.centerY.equalTo(self)
            make.width.height.equalTo(UIConstants.layout.trackingProtectionHeight)
        }

        trackingProtectionOff.snp.makeConstraints { make in
            make.leading.centerY.equalTo(self)
            make.width.height.equalTo(UIConstants.layout.trackingProtectionHeight)
        }
        
        connectionNotSecure.snp.makeConstraints { make in
            make.leading.centerY.equalTo(self)
            make.width.height.equalTo(UIConstants.layout.trackingProtectionHeight)
        }
    }

    override func updateState(trackingStatus: TrackingProtectionStatus, shouldDisplayShieldIcon: Bool) {
        guard shouldDisplayShieldIcon else {
            trackingProtectionOn.alpha = 0
            trackingProtectionOff.alpha = 0
            connectionNotSecure.alpha = 1
            return
        }
        switch trackingStatus {
        case .on:
            trackingProtectionOff.alpha = 0
            trackingProtectionOn.alpha = 1
            connectionNotSecure.alpha = 0
        default:
            trackingProtectionOff.alpha = 1
            trackingProtectionOn.alpha = 0
            connectionNotSecure.alpha = 0
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
