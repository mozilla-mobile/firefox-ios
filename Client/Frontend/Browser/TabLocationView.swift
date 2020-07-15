/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import SnapKit
import XCGLogger

private let log = Logger.browserLogger

protocol TabLocationViewDelegate {
    func tabLocationViewDidTapLocation(_ tabLocationView: TabLocationView)
    func tabLocationViewDidLongPressLocation(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapReaderMode(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapShield(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapPageOptions(_ tabLocationView: TabLocationView, from button: UIButton)
    func tabLocationViewDidLongPressPageOptions(_ tabLocationVIew: TabLocationView)
    func tabLocationViewDidBeginDragInteraction(_ tabLocationView: TabLocationView)

    /// - returns: whether the long-press was handled by the delegate; i.e. return `false` when the conditions for even starting handling long-press were not satisfied
    @discardableResult func tabLocationViewDidLongPressReaderMode(_ tabLocationView: TabLocationView) -> Bool
    func tabLocationViewLocationAccessibilityActions(_ tabLocationView: TabLocationView) -> [UIAccessibilityCustomAction]?
}

private struct TabLocationViewUX {
    static let HostFontColor = UIColor.black
    static let BaseURLFontColor = UIColor.Photon.Grey50
    static let Spacing: CGFloat = 8
    static let StatusIconSize: CGFloat = 18
    static let TPIconSize: CGFloat = 44
    static let ReaderModeButtonWidth: CGFloat = 34
    static let ButtonSize: CGFloat = 44
    static let URLBarPadding = 4
}

class TabLocationView: UIView {
    var delegate: TabLocationViewDelegate?
    var longPressRecognizer: UILongPressGestureRecognizer!
    var tapRecognizer: UITapGestureRecognizer!
    var contentView: UIStackView!

    fileprivate let menuBadge = BadgeWithBackdrop(imageName: "menuBadge", backdropCircleSize: 32)

    @objc dynamic var baseURLFontColor: UIColor = TabLocationViewUX.BaseURLFontColor {
        didSet { updateTextWithURL() }
    }

    func showLockIcon(forSecureContent isSecure: Bool) {
        lockImageView.isHidden = !isSecure
    }

    var url: URL? {
        didSet {
            updateTextWithURL()
            pageOptionsButton.isHidden = (url == nil)

            trackingProtectionButton.isHidden = !["https", "http"].contains(url?.scheme ?? "")
            setNeedsUpdateConstraints()
        }
    }

    var readerModeState: ReaderModeState {
        get {
            return readerModeButton.readerModeState
        }
        set (newReaderModeState) {
            if newReaderModeState != self.readerModeButton.readerModeState {
                let wasHidden = readerModeButton.isHidden
                self.readerModeButton.readerModeState = newReaderModeState
                readerModeButton.isHidden = (newReaderModeState == ReaderModeState.unavailable)
                if wasHidden != readerModeButton.isHidden {
                    UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: nil)
                    if !readerModeButton.isHidden {
                        // Delay the Reader Mode accessibility announcement briefly to prevent interruptions.
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: Strings.ReaderModeAvailableVoiceOverAnnouncement)
                        }
                    }
                }
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    self.readerModeButton.alpha = newReaderModeState == .unavailable ? 0 : 1
                })
            }
        }
    }

    lazy var placeholder: NSAttributedString = {
        let placeholderText = NSLocalizedString("Search or enter address", comment: "The text shown in the URL bar on about:home")
        return NSAttributedString(string: placeholderText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.Photon.Grey50])
    }()

    lazy var urlTextField: UITextField = {
        let urlTextField = DisplayTextField()

        // Prevent the field from compressing the toolbar buttons on the 4S in landscape.
        urlTextField.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 250), for: .horizontal)
        urlTextField.attributedPlaceholder = self.placeholder
        urlTextField.accessibilityIdentifier = "url"
        urlTextField.accessibilityActionsSource = self
        urlTextField.font = UIConstants.DefaultChromeFont
        urlTextField.backgroundColor = .clear
        urlTextField.accessibilityLabel = "Address Bar"

        // Remove the default drop interaction from the URL text field so that our
        // custom drop interaction on the BVC can accept dropped URLs.
        if let dropInteraction = urlTextField.textDropInteraction {
            urlTextField.removeInteraction(dropInteraction)
        }

        return urlTextField
    }()

    fileprivate lazy var lockImageView: UIImageView = {
        let lockImageView = UIImageView(image: UIImage.templateImageNamed("lock_verified"))
        lockImageView.isAccessibilityElement = true
        lockImageView.contentMode = .center
        lockImageView.accessibilityLabel = NSLocalizedString("Secure connection", comment: "Accessibility label for the lock icon, which is only present if the connection is secure")
        return lockImageView
    }()

    class TrackingProtectionButton: UIButton {
        // Disable showing the button if the feature is off in the prefs
        override var isHidden: Bool {
            didSet {
                separatorLine?.isHidden = isHidden
                guard !isHidden, let appDelegate = UIApplication.shared.delegate as? AppDelegate, let profile = appDelegate.profile else { return }
                if !FirefoxTabContentBlocker.isTrackingProtectionEnabled(prefs: profile.prefs) {
                    isHidden = true
                }
            }
        }

        var separatorLine: UIView?
    }

    lazy var trackingProtectionButton: TrackingProtectionButton = {
        let trackingProtectionButton = TrackingProtectionButton()
        trackingProtectionButton.setImage(UIImage.templateImageNamed("tracking-protection"), for: .normal)
        trackingProtectionButton.addTarget(self, action: #selector(didPressTPShieldButton(_:)), for: .touchUpInside)
        trackingProtectionButton.tintColor = UIColor.Photon.Grey50
        trackingProtectionButton.imageView?.contentMode = .scaleAspectFill
        trackingProtectionButton.accessibilityIdentifier = "TabLocationView.trackingProtectionButton"
        return trackingProtectionButton
    }()

    fileprivate lazy var readerModeButton: ReaderModeButton = {
        let readerModeButton = ReaderModeButton(frame: .zero)
        readerModeButton.addTarget(self, action: #selector(tapReaderModeButton), for: .touchUpInside)
        readerModeButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressReaderModeButton)))
        readerModeButton.isAccessibilityElement = true
        readerModeButton.isHidden = true
        readerModeButton.imageView?.contentMode = .scaleAspectFit
        readerModeButton.contentHorizontalAlignment = .left
        readerModeButton.accessibilityLabel = NSLocalizedString("Reader View", comment: "Accessibility label for the Reader View button")
        readerModeButton.accessibilityIdentifier = "TabLocationView.readerModeButton"
        readerModeButton.accessibilityCustomActions = [UIAccessibilityCustomAction(name: NSLocalizedString("Add to Reading List", comment: "Accessibility label for action adding current page to reading list."), target: self, selector: #selector(readerModeCustomAction))]
        return readerModeButton
    }()

    lazy var pageOptionsButton: ToolbarButton = {
        let pageOptionsButton = ToolbarButton(frame: .zero)
        pageOptionsButton.setImage(UIImage.templateImageNamed("menu-More-Options"), for: .normal)
        pageOptionsButton.addTarget(self, action: #selector(didPressPageOptionsButton), for: .touchUpInside)
        pageOptionsButton.isAccessibilityElement = true
        pageOptionsButton.isHidden = true
        pageOptionsButton.imageView?.contentMode = .left
        pageOptionsButton.accessibilityLabel = NSLocalizedString("Page Options Menu", comment: "Accessibility label for the Page Options menu button")
        pageOptionsButton.accessibilityIdentifier = "TabLocationView.pageOptionsButton"
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressPageOptionsButton))
        pageOptionsButton.addGestureRecognizer(longPressGesture)
        return pageOptionsButton
    }()

    private func makeSeparator() -> UIView {
        let line = UIView()
        line.layer.cornerRadius = 2
        return line
    }

    // A vertical separator next to the page options button.
    lazy var separatorLineForPageOptions: UIView = makeSeparator()

    lazy var separatorLineForTP: UIView = makeSeparator()

    override init(frame: CGRect) {
        super.init(frame: frame)

        register(self, forTabEvents: .didGainFocus, .didToggleDesktopMode, .didChangeContentBlocking)

        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressLocation))
        longPressRecognizer.delegate = self

        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapLocation))
        tapRecognizer.delegate = self

        addGestureRecognizer(longPressRecognizer)
        addGestureRecognizer(tapRecognizer)

        let space10px = UIView()
        space10px.snp.makeConstraints { make in
            make.width.equalTo(10)
        }

        // Link these so they hide/show in-sync.
        trackingProtectionButton.separatorLine = separatorLineForTP

        pageOptionsButton.separatorLine = separatorLineForPageOptions

        let subviews = [trackingProtectionButton, separatorLineForTP, space10px, lockImageView, urlTextField, readerModeButton, separatorLineForPageOptions, pageOptionsButton]
        contentView = UIStackView(arrangedSubviews: subviews)
        contentView.distribution = .fill
        contentView.alignment = .center
        addSubview(contentView)

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        lockImageView.snp.makeConstraints { make in
            make.width.equalTo(TabLocationViewUX.StatusIconSize)
            make.height.equalTo(TabLocationViewUX.ButtonSize)
        }
        trackingProtectionButton.snp.makeConstraints { make in
            make.width.equalTo(TabLocationViewUX.TPIconSize)
            make.height.equalTo(TabLocationViewUX.ButtonSize)
        }
        separatorLineForTP.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(26)
        }

        pageOptionsButton.snp.makeConstraints { make in
            make.size.equalTo(TabLocationViewUX.ButtonSize)
        }
        separatorLineForPageOptions.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(26)
        }
        readerModeButton.snp.makeConstraints { make in
            make.width.equalTo(TabLocationViewUX.ReaderModeButtonWidth)
            make.height.equalTo(TabLocationViewUX.ButtonSize)
        }

        // Setup UIDragInteraction to handle dragging the location
        // bar for dropping its URL into other apps.
        let dragInteraction = UIDragInteraction(delegate: self)
        dragInteraction.allowsSimultaneousRecognitionDuringLift = true
        self.addInteraction(dragInteraction)

        menuBadge.add(toParent: contentView)
        menuBadge.layout(onButton: pageOptionsButton)
        menuBadge.show(false)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var _accessibilityElements = [urlTextField, readerModeButton, pageOptionsButton, trackingProtectionButton]

    override var accessibilityElements: [Any]? {
        get {
            return _accessibilityElements.filter { !$0.isHidden }
        }
        set {
            super.accessibilityElements = newValue
        }
    }

    func overrideAccessibility(enabled: Bool) {
        _accessibilityElements.forEach {
            $0.isAccessibilityElement = enabled
        }
    }

    @objc func tapReaderModeButton() {
        delegate?.tabLocationViewDidTapReaderMode(self)
    }

    @objc func longPressReaderModeButton(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            delegate?.tabLocationViewDidLongPressReaderMode(self)
        }
    }

    @objc func didPressPageOptionsButton(_ button: UIButton) {
        delegate?.tabLocationViewDidTapPageOptions(self, from: button)
    }

    @objc func didLongPressPageOptionsButton(_ recognizer: UILongPressGestureRecognizer) {
        delegate?.tabLocationViewDidLongPressPageOptions(self)
    }

    @objc func longPressLocation(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .began {
            delegate?.tabLocationViewDidLongPressLocation(self)
        }
    }

    @objc func tapLocation(_ recognizer: UITapGestureRecognizer) {
        delegate?.tabLocationViewDidTapLocation(self)
    }

    @objc func didPressTPShieldButton(_ button: UIButton) {
        delegate?.tabLocationViewDidTapShield(self)
    }

    @objc func readerModeCustomAction() -> Bool {
        return delegate?.tabLocationViewDidLongPressReaderMode(self) ?? false
    }

    fileprivate func updateTextWithURL() {
        if let host = url?.host, AppConstants.MOZ_PUNYCODE {
            urlTextField.text = url?.absoluteString.replacingOccurrences(of: host, with: host.asciiHostToUTF8())
        } else {
            urlTextField.text = url?.absoluteString
        }
        // remove https:// (the scheme) from the url when displaying
        if let scheme = url?.scheme, let range = url?.absoluteString.range(of: "\(scheme)://") {
            urlTextField.text = url?.absoluteString.replacingCharacters(in: range, with: "")
        }
    }
}

extension TabLocationView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // When long pressing a button make sure the textfield's long press gesture is not triggered
        return !(otherGestureRecognizer.view is UIButton)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // If the longPressRecognizer is active, fail the tap recognizer to avoid conflicts.
        return gestureRecognizer == longPressRecognizer && otherGestureRecognizer == tapRecognizer
    }
}

@available(iOS 11.0, *)
extension TabLocationView: UIDragInteractionDelegate {
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        // Ensure we actually have a URL in the location bar and that the URL is not local.
        guard let url = self.url, !InternalURL.isValid(url: url), let itemProvider = NSItemProvider(contentsOf: url) else {
            return []
        }

        TelemetryWrapper.recordEvent(category: .action, method: .drag, object: .locationBar)

        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }

    func dragInteraction(_ interaction: UIDragInteraction, sessionWillBegin session: UIDragSession) {
        delegate?.tabLocationViewDidBeginDragInteraction(self)
    }
}

extension TabLocationView: AccessibilityActionsSource {
    func accessibilityCustomActionsForView(_ view: UIView) -> [UIAccessibilityCustomAction]? {
        if view === urlTextField {
            return delegate?.tabLocationViewLocationAccessibilityActions(self)
        }
        return nil
    }
}

extension TabLocationView: Themeable {
    func applyTheme() {
        backgroundColor = UIColor.theme.textField.background
        urlTextField.textColor = UIColor.theme.textField.textAndTint
        readerModeButton.selectedTintColor = UIColor.theme.urlbar.readerModeButtonSelected
        readerModeButton.unselectedTintColor = UIColor.theme.urlbar.readerModeButtonUnselected
        
        pageOptionsButton.selectedTintColor = UIColor.theme.urlbar.pageOptionsSelected
        pageOptionsButton.unselectedTintColor = UIColor.theme.urlbar.pageOptionsUnselected
        pageOptionsButton.tintColor = pageOptionsButton.unselectedTintColor
        separatorLineForPageOptions.backgroundColor = UIColor.Photon.Grey40
        separatorLineForTP.backgroundColor = separatorLineForPageOptions.backgroundColor

        lockImageView.tintColor = pageOptionsButton.tintColor

        let color = ThemeManager.instance.currentName == .dark ? UIColor(white: 0.3, alpha: 0.6): UIColor.theme.textField.background
        menuBadge.badge.tintBackground(color: color)
    }
}

extension TabLocationView: TabEventHandler {
    func tabDidChangeContentBlocking(_ tab: Tab) {
        updateBlockerStatus(forTab: tab)
    }

    private func updateBlockerStatus(forTab tab: Tab) {
        assertIsMainThread("UI changes must be on the main thread")
        guard let blocker = tab.contentBlocker else { return }
        trackingProtectionButton.alpha = 1.0
        switch blocker.status {
        case .blocking:
            let blockImageName = ThemeManager.instance.currentName == .dark ? "tracking-protection-active-block-dark" : "tracking-protection-active-block"
            trackingProtectionButton.setImage(UIImage(imageLiteralResourceName: blockImageName), for: .normal)
        case .noBlockedURLs:
            trackingProtectionButton.setImage(UIImage.templateImageNamed("tracking-protection"), for: .normal)
            trackingProtectionButton.alpha = 0.5
        case .safelisted:
            trackingProtectionButton.setImage(UIImage.templateImageNamed("tracking-protection-off"), for: .normal)
        case .disabled:
            trackingProtectionButton.isHidden = true
        }
    }

    func tabDidGainFocus(_ tab: Tab) {
        updateBlockerStatus(forTab: tab)
        menuBadge.show(tab.changedUserAgent)
    }

    func tabDidToggleDesktopMode(_ tab: Tab) {
        menuBadge.show(tab.changedUserAgent)
    }
}

class ReaderModeButton: UIButton {
    var selectedTintColor: UIColor?
    var unselectedTintColor: UIColor?
    override init(frame: CGRect) {
        super.init(frame: frame)
        adjustsImageWhenHighlighted = false
        setImage(UIImage.templateImageNamed("reader"), for: .normal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            self.tintColor = (isHighlighted || isSelected) ? selectedTintColor : unselectedTintColor
        }
    }

    override open var isHighlighted: Bool {
        didSet {
            self.tintColor = (isHighlighted || isSelected) ? selectedTintColor : unselectedTintColor
        }
    }

    override var tintColor: UIColor! {
        didSet {
            self.imageView?.tintColor = self.tintColor
        }
    }

    var _readerModeState = ReaderModeState.unavailable

    var readerModeState: ReaderModeState {
        get {
            return _readerModeState
        }
        set (newReaderModeState) {
            _readerModeState = newReaderModeState
            switch _readerModeState {
            case .available:
                self.isEnabled = true
                self.isSelected = false
            case .unavailable:
                self.isEnabled = false
                self.isSelected = false
            case .active:
                self.isEnabled = true
                self.isSelected = true
            }
        }
    }
}

private class DisplayTextField: UITextField {
    weak var accessibilityActionsSource: AccessibilityActionsSource?

    override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            return accessibilityActionsSource?.accessibilityCustomActionsForView(self)
        }
        set {
            super.accessibilityCustomActions = newValue
        }
    }

    fileprivate override var canBecomeFirstResponder: Bool {
        return false
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: TabLocationViewUX.Spacing, dy: 0)
    }
}
