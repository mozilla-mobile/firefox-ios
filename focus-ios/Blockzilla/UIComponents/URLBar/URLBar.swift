/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Telemetry
import Glean
import Combine

enum Source: String {
   case action, shortcut, suggestion, topsite, widget, none
}

public enum ShieldIconStatus: Equatable {
    case on
    case off
    case connectionNotSecure
}

class URLBar: UIView {
    @Published public var connectionState: ShieldIconStatus = .on
    private var cancellables: Set<AnyCancellable> = []

    private lazy var cancelButton: InsetButton = {
        let button = InsetButton()
        button.isHidden = true
        button.alpha = 0
        button.setImage(.cancel, for: .normal)
        button.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        button.addTarget(self, action: #selector(cancelPressed), for: .touchUpInside)
        button.accessibilityIdentifier = "URLBar.cancelButton"
        return button
    }()

    private lazy var shieldIcon: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .primaryText
        button.setImage(.trackingProtectionOn, for: .normal)
        button.contentMode = .center
        button.accessibilityIdentifier = "URLBar.trackingProtectionIcon"
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()

    public var shieldIconAnchor: UIView { shieldIcon }

    private lazy var urlBarBorderView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondaryButton
        view.layer.cornerRadius = UIConstants.layout.urlBarCornerRadius
        view.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        view.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        return view
    }()

    private lazy var urlBarBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .locationBar
        view.layer.cornerRadius = UIConstants.layout.urlBarCornerRadius
        view.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        view.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .horizontal)
        return view
    }()

    private lazy var truncatedUrlText: UITextView = {
        let textView = UITextView()
        textView.alpha = 0
        textView.isUserInteractionEnabled = false
        textView.font = .footnote12
        textView.tintColor = .primaryText
        textView.textColor = .primaryText
        textView.backgroundColor = UIColor.clear
        textView.contentMode = .bottom
        textView.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .vertical)
        textView.isScrollEnabled = false
        textView.accessibilityIdentifier = "Collapsed.truncatedUrlText"
        return textView
    }()

    private lazy var urlTextField: URLTextField = {
        // UITextField doesn't allow customization of the clear button, so we create
        // our own so we can use it as the rightView.
        let clearButton = UIButton(frame: CGRect(x: 0, y: 0, width: UIConstants.layout.urlBarClearButtonWidth, height: UIConstants.layout.urlBarClearButtonHeight))
        clearButton.isHidden = true
        clearButton.setImage(.clear, for: .normal)
        clearButton.addTarget(self, action: #selector(didPressClear), for: .touchUpInside)

        let textField = URLTextField()
        textField.font = .body15
        textField.tintColor = .primaryText
        textField.textColor = .primaryText
        textField.keyboardType = .webSearch
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.rightView = clearButton
        textField.rightViewMode = .whileEditing
        textField.setContentHuggingPriority(UILayoutPriority(rawValue: UIConstants.layout.urlBarLayoutPriorityRawValue), for: .vertical)
        textField.autocompleteDelegate = self
        textField.accessibilityIdentifier = "URLBar.urlText"
        textField.placeholder = UIConstants.strings.urlTextPlaceholder
        textField.isUserInteractionEnabled = false
        return textField
    }()

    private lazy var textAndLockContainer: UIView = {
        let textAndLockContainer = UIView()

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(didSingleTap(sender:)))
        singleTap.numberOfTapsRequired = 1
        textAndLockContainer.addGestureRecognizer(singleTap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(displayURLContextMenu))
        textAndLockContainer.addGestureRecognizer(longPress)

        return textAndLockContainer
    }()

    private lazy var collapsedUrlAndLockWrapper: UIView = {
        let collapsedUrlAndLockWrapper = UIView()
        return collapsedUrlAndLockWrapper
    }()

    lazy var progressBar: GradientProgressBar = {
        let progressBar = GradientProgressBar(progressViewStyle: .bar)
        progressBar.isHidden = true
        progressBar.alpha = 0
        return progressBar
    }()

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
                _ = urlTextField.resignFirstResponder()
                delegate?.urlBarDidDismiss(self)
            } else if state == .editing {
                delegate?.urlBarDidFocus(self)
            }
        }
    }

    weak var delegate: URLBarDelegate?
    var userInputText: String?
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
    public var textFieldAnchor: UIView { urlTextField }

    private let leftBarViewLayoutGuide = UILayoutGuide()
    private let rightBarViewLayoutGuide = UILayoutGuide()
    private let domainCompletion = DomainCompletion(completionSources: [TopDomainsCompletionSource(), CustomCompletionSource()])

    private let toolset = BrowserToolset()
    var draggableUrlTextView: UIView { return urlTextField }

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

        let dragInteraction = UIDragInteraction(delegate: self)
        urlBarBackgroundView.addInteraction(dragInteraction)

        addSubview(toolset.backButton)
        addSubview(toolset.forwardButton)
        addSubview(toolset.deleteButton)
        addSubview(toolset.contextMenuButton)

        urlBarBackgroundView.addSubview(textAndLockContainer)

        addSubview(cancelButton)
        textAndLockContainer.addSubview(toolset.stopReloadButton)
        addSubview(urlBarBorderView)
        urlBarBorderView.addSubview(urlBarBackgroundView)
        collapsedUrlAndLockWrapper.addSubview(truncatedUrlText)
        addSubview(collapsedUrlAndLockWrapper)
        textAndLockContainer.addSubview(urlTextField)
        addSubview(shieldIcon)
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

            showLeftBarViewConstraints.append(make.leading.lessThanOrEqualTo(leftBarViewLayoutGuide.snp.trailing).offset(UIConstants.layout.urlBarIconInset).constraint)

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
            make.trailing.equalToSuperview()

            showLeftBarViewConstraints.append(make.leading.equalTo(leftBarViewLayoutGuide.snp.trailing).offset(UIConstants.layout.urlBarIconInset).constraint)

            hideLeftBarViewConstraints.append(make.leading.equalToSuperview().offset(UIConstants.layout.urlBarTextInset).constraint)
            centeredURLConstraints.append(make.centerX.equalToSuperview().constraint)
        }

        toolset.stopReloadButton.snp.makeConstraints { make in
            make.trailing.equalTo(urlBarBorderView)
            make.leading.equalTo(urlBarBorderView.snp.trailing).inset(UIConstants.layout.urlBarButtonTargetSize)
            make.center.equalToSuperview()
        }

        urlTextField.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(shieldIcon.snp.trailing).offset(5)

            showLeftBarViewConstraints.append(make.left.equalToSuperview().constraint)

            hidePageActionsConstraints.append(make.trailing.equalToSuperview().constraint)
            showPageActionsConstraints.append(make.trailing.equalTo(urlBarBorderView.snp.trailing).inset(UIConstants.layout.urlBarButtonTargetSize).constraint)
        }

        progressBar.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.bottom.equalTo(self).offset(UIConstants.layout.progressBarHeight)
            make.height.equalTo(UIConstants.layout.progressBarHeight)
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

        shieldIcon
            .publisher(event: .touchUpInside)
            .sink { [unowned self] _ in
                self.delegate?.urlBarDidTapShield(self)
            }
            .store(in: &cancellables)

        $connectionState
            .removeDuplicates()
            .map { trackingProtectionStatus -> UIImage in
                switch trackingProtectionStatus {
                case .on: return .trackingProtectionOn
                case .off: return .trackingProtectionOff
                case .connectionNotSecure: return .connectionNotSecure
                }
            }
            .sink(receiveValue: { [shieldIcon] image in
                UIView.transition(
                    with: shieldIcon,
                    duration: 0.1,
                    options: .transitionCrossDissolve,
                    animations: {
                        shieldIcon.setImage(image, for: .normal)
                    })
            })
            .store(in: &cancellables)
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
        urlTextField.isUserInteractionEnabled = true
        urlTextField.becomeFirstResponder()
        isEditing = true
    }

    private func displayClearButton(shouldDisplay: Bool, animated: Bool = true) {
        // Prevent the rightView's position from being animated
        urlTextField.rightView?.layer.removeAllAnimations()
        urlTextField.rightView?.animateHidden(!shouldDisplay, duration: animated ? UIConstants.layout.urlBarTransitionAnimationDuration : 0)
    }

    public func dismissTextField() {
        urlTextField.isUserInteractionEnabled = false
        urlTextField.endEditing(true)
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
        urlTextField.text = clipboardString
    }

    @objc func pasteAndGo(clipboardString: String) {
        isEditing = true
        delegate?.urlBarDidActivate(self)
        delegate?.urlBar(self, didSubmitText: clipboardString, source: .action)

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

        if urlTextField.text != nil, urlTextField.text?.isEmpty == false {
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
            if !urlTextField.isEditing {
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
        if urlTextField.isUserInteractionEnabled,
            let touch = touches.first {
            let point = touch.location(in: urlBarBorderView)
            if urlBarBorderView.bounds.contains(point) {
                urlTextField.becomeFirstResponder()
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
        urlTextField.text = text
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

            editingURLTextConstrains.forEach { $0.deactivate() }
            urlTextField.snp.makeConstraints { make in
                make.leading.equalTo(shieldIcon.snp.trailing).offset(UIConstants.layout.urlTextOffset)
            }

        case .editing:
            showLeftBar = !shouldShowToolset && isIPadRegularDimensions ? false : true
            compressBar = isIPadRegularDimensions ? false : true
            showBackgroundView = true

            if isIPadRegularDimensions && inBrowsingMode {
                leftBarViewLayoutGuide.snp.makeConstraints { make in
                    editingURLTextConstrains.append(make.leading.equalTo(urlTextField).offset(-UIConstants.layout.urlTextOffset).constraint)
                }
                editingURLTextConstrains.forEach { $0.activate() }
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
                if let isEmpty = self.urlTextField.text?.isEmpty {
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
        urlTextField.text = nil
        userInputText = nil
        displayClearButton(shouldDisplay: false)
        delegate?.urlBar(self, didEnterText: "")
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
        urlTextField.text = nil
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
        urlTextField.text = displayFullUrl ? fullUrl : displayText
        truncatedUrlText.text = truncatedURL
    }

    private func highlightText(_ textField: UITextField) {
        guard textField.text != nil else { return }
        textField.selectAll(nil)
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

        if isEditing {
            shieldIcon.alpha = collapseAlpha
        } else {
            shieldIcon.alpha = expandAlpha
        }

        self.layoutIfNeeded()
    }
}

extension URLBar: AutocompleteTextFieldDelegate {
    func autocompleteTextFieldShouldClear(_ autocompleteTextField: AutocompleteTextField) -> Bool { return false }

    func autocompleteTextFieldDidCancel(_ autocompleteTextField: AutocompleteTextField) { }

    func autocompletePasteAndGo(_ autocompleteTextField: AutocompleteTextField) { }

    func autocompleteTextFieldShouldEndEditing(_ autocompleteTextField: AutocompleteTextField) -> Bool { return true }

    func autocompleteTextFieldShouldBeginEditing(_ autocompleteTextField: AutocompleteTextField) -> Bool {

        DispatchQueue.main.async {
            self.setTextToURL(displayFullUrl: true)
        }

        if !isEditing {
            isEditing = true
            delegate?.urlBarDidActivate(self)
            DispatchQueue.main.async {
                self.highlightText(autocompleteTextField)
            }
        }

        // When text.characters.count == 0, it is the HomeView
        if let text = autocompleteTextField.text, !isEditing, text.count == 0 {
            shouldPresent = true
        }

        return true
    }

    func autocompleteTextFieldShouldReturn(_ autocompleteTextField: AutocompleteTextField) -> Bool {
        // If the new search string is not longer than the previous
        // we don't need to find an autocomplete suggestion.
        if let autocompleteText = autocompleteTextField.text, autocompleteText != userInputText {
            Telemetry.default.recordEvent(TelemetryEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.autofill))
        }
        userInputText = nil

        delegate?.urlBar(self, didSubmitText: autocompleteTextField.text ?? "", source: .action)

        if Settings.getToggle(.enableSearchSuggestions) {
            Telemetry.default.recordEvent(TelemetryEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.searchSuggestionNotSelected))
        }

        return true
    }

    func autocompleteTextField(_ autocompleteTextField: AutocompleteTextField, didEnterText text: String) {
        if let oldValue = userInputText, oldValue.count < text.count {
            let completion = domainCompletion.autocompleteTextFieldCompletionSource(autocompleteTextField, forText: text)
            autocompleteTextField.setAutocompleteSuggestion(completion)
        }

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
