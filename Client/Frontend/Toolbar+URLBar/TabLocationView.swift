// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

protocol TabLocationViewDelegate: AnyObject {
    func tabLocationViewDidTapLocation(_ tabLocationView: TabLocationView)
    func tabLocationViewDidLongPressLocation(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapReaderMode(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapReload(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapShield(_ tabLocationView: TabLocationView)
    func tabLocationViewDidBeginDragInteraction(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapShare(_ tabLocationView: TabLocationView, button: UIButton)

    /// - returns: whether the long-press was handled by the delegate; i.e. return `false` when the conditions for even starting handling long-press were not satisfied
    @discardableResult
    func tabLocationViewDidLongPressReaderMode(_ tabLocationView: TabLocationView) -> Bool
    func tabLocationViewDidLongPressReload(_ tabLocationView: TabLocationView)
    func tabLocationViewLocationAccessibilityActions(_ tabLocationView: TabLocationView) -> [UIAccessibilityCustomAction]?
}

class TabLocationView: UIView, FeatureFlaggable {
    // MARK: UX
    struct UX {
        static let hostFontColor = UIColor.black
        static let spacing: CGFloat = 8
        static let statusIconSize: CGFloat = 18
        static let buttonSize: CGFloat = 40
        static let urlBarPadding = 4
    }

    // MARK: Variables
    weak var delegate: TabLocationViewDelegate?
    var longPressRecognizer: UILongPressGestureRecognizer!
    var tapRecognizer: UITapGestureRecognizer!
    var contentView: UIStackView!

    private let themeManager: ThemeManager
    private let menuBadge = BadgeWithBackdrop(imageName: ImageIdentifiers.menuBadge, backdropCircleSize: 32)

   lazy var baseURLFontColor: UIColor = themeManager.currentTheme.colors.textPrimary {
        didSet { updateTextWithURL() }
    }

    var url: URL? {
        didSet {
            updateTextWithURL()
            trackingProtectionButton.isHidden = !isValidHttpUrlProtocol
            shareButton.isHidden = !(shouldEnableShareButtonFeature && isValidHttpUrlProtocol)
            setNeedsUpdateConstraints()
        }
    }

    var shouldEnableShareButtonFeature: Bool {
        guard featureFlags.isFeatureEnabled(.shareToolbarChanges, checking: .buildOnly) else {
            return false
        }
        return true
    }

    var readerModeState: ReaderModeState {
        get {
            return readerModeButton.readerModeState
        }
        set (newReaderModeState) {
            guard newReaderModeState != self.readerModeButton.readerModeState else { return }
            setReaderModeState(newReaderModeState)
        }
    }

    lazy var placeholder: NSAttributedString = {
        return NSAttributedString(string: .TabLocationURLPlaceholder, attributes: [NSAttributedString.Key.foregroundColor: themeManager.currentTheme.colors.textSecondary])
    }()

    lazy var urlTextField: URLTextField = .build { urlTextField in
        // Prevent the field from compressing the toolbar buttons on the 4S in landscape.
        urlTextField.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 250), for: .horizontal)
        urlTextField.attributedPlaceholder = self.placeholder
        urlTextField.accessibilityIdentifier = "url"
        urlTextField.accessibilityActionsSource = self
        urlTextField.font = UIConstants.DefaultChromeFont
        urlTextField.backgroundColor = .clear
        urlTextField.accessibilityLabel = .TabLocationAddressBarAccessibilityLabel
        urlTextField.font = UIFont.preferredFont(forTextStyle: .body)
        urlTextField.adjustsFontForContentSizeCategory = true

        // Remove the default drop interaction from the URL text field so that our
        // custom drop interaction on the BVC can accept dropped URLs.
        if let dropInteraction = urlTextField.textDropInteraction {
            urlTextField.removeInteraction(dropInteraction)
        }
    }

    lazy var trackingProtectionButton: LockButton = .build { trackingProtectionButton in
        trackingProtectionButton.addTarget(self, action: #selector(self.didPressTPShieldButton(_:)), for: .touchUpInside)
        trackingProtectionButton.clipsToBounds = false
        trackingProtectionButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.trackingProtection
    }

    lazy var shareButton: ShareButton = .build { shareButton in
        shareButton.addTarget(self, action: #selector(self.didPressShareButton(_:)), for: .touchUpInside)
        shareButton.clipsToBounds = false
        shareButton.tintColor = self.themeManager.currentTheme.colors.iconSecondary
        shareButton.contentHorizontalAlignment = .center
        shareButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.shareButton
    }

    private lazy var readerModeButton: ReaderModeButton = .build { readerModeButton in
        readerModeButton.addTarget(self, action: #selector(self.tapReaderModeButton), for: .touchUpInside)
        readerModeButton.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self,
                                         action: #selector(self.longPressReaderModeButton)))
        readerModeButton.isAccessibilityElement = true
        readerModeButton.isHidden = true
        readerModeButton.accessibilityLabel = .TabLocationReaderModeAccessibilityLabel
        readerModeButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.readerModeButton
        readerModeButton.accessibilityCustomActions = [
            UIAccessibilityCustomAction(
                name: .TabLocationReaderModeAddToReadingListAccessibilityLabel,
                target: self,
                selector: #selector(self.readerModeCustomAction))]
    }

    lazy var reloadButton: StatefulButton = {
        let reloadButton = StatefulButton(frame: .zero, state: .disabled)
        reloadButton.addTarget(self, action: #selector(tapReloadButton), for: .touchUpInside)
        reloadButton.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(longPressReloadButton)))
        reloadButton.tintColor = themeManager.currentTheme.colors.iconPrimary
        reloadButton.imageView?.contentMode = .scaleAspectFit
        reloadButton.contentHorizontalAlignment = .center
        reloadButton.accessibilityLabel = .TabLocationReloadAccessibilityLabel
        reloadButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.reloadButton
        reloadButton.isAccessibilityElement = true
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        return reloadButton
    }()

    override init(frame: CGRect) {
        self.themeManager = AppContainer.shared.resolve()
        super.init(frame: frame)
        register(self, forTabEvents: .didGainFocus, .didToggleDesktopMode, .didChangeContentBlocking)
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressLocation))
        longPressRecognizer.delegate = self

        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapLocation))
        tapRecognizer.delegate = self

        addGestureRecognizer(longPressRecognizer)
        addGestureRecognizer(tapRecognizer)

        let space1px = UIView.build()
        space1px.widthAnchor.constraint(equalToConstant: 1).isActive = true

        let subviews = [trackingProtectionButton, space1px, urlTextField, readerModeButton, shareButton, reloadButton]
        contentView = UIStackView(arrangedSubviews: subviews)
        contentView.distribution = .fill
        contentView.alignment = .center
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        contentView.edges(equalTo: self)

        NSLayoutConstraint.activate([
            trackingProtectionButton.widthAnchor.constraint(equalToConstant: UX.buttonSize),
            trackingProtectionButton.heightAnchor.constraint(equalToConstant: UX.buttonSize),
            readerModeButton.widthAnchor.constraint(equalToConstant: UX.buttonSize),
            readerModeButton.heightAnchor.constraint(equalToConstant: UX.buttonSize),
            shareButton.heightAnchor.constraint(equalToConstant: UX.buttonSize),
            shareButton.widthAnchor.constraint(equalToConstant: UX.buttonSize),
            reloadButton.widthAnchor.constraint(equalToConstant: UX.buttonSize),
            reloadButton.heightAnchor.constraint(equalToConstant: UX.buttonSize),
        ])

        // Setup UIDragInteraction to handle dragging the location
        // bar for dropping its URL into other apps.
        let dragInteraction = UIDragInteraction(delegate: self)
        dragInteraction.allowsSimultaneousRecognitionDuringLift = true
        self.addInteraction(dragInteraction)

        menuBadge.add(toParent: contentView)
        menuBadge.show(false)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Accessibility

    private lazy var _accessibilityElements = [urlTextField, readerModeButton, readerModeButton, reloadButton, trackingProtectionButton, shareButton]

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

    // MARK: - User actions

    @objc
    func tapReaderModeButton() {
        delegate?.tabLocationViewDidTapReaderMode(self)
    }

    @objc
    func tapReloadButton() {
        delegate?.tabLocationViewDidTapReload(self)
    }

    @objc
    func longPressReaderModeButton(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            delegate?.tabLocationViewDidLongPressReaderMode(self)
        }
    }

    @objc
    func longPressReloadButton(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            delegate?.tabLocationViewDidLongPressReload(self)
        }
    }

    @objc
    func longPressLocation(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .began {
            delegate?.tabLocationViewDidLongPressLocation(self)
        }
    }

    @objc
    func tapLocation(_ recognizer: UITapGestureRecognizer) {
        delegate?.tabLocationViewDidTapLocation(self)
    }

    @objc
    func didPressTPShieldButton(_ button: UIButton) {
        delegate?.tabLocationViewDidTapShield(self)
    }

    @objc
    func didPressShareButton(_ button: UIButton) {
        delegate?.tabLocationViewDidTapShare(self, button: shareButton)
    }

    @objc
    func readerModeCustomAction() -> Bool {
        return delegate?.tabLocationViewDidLongPressReaderMode(self) ?? false
    }

    private func updateTextWithURL() {
        if let host = url?.host, AppConstants.punyCode {
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

// MARK: - Private
private extension TabLocationView {
    var isValidHttpUrlProtocol: Bool {
        ["https", "http"].contains(url?.scheme ?? "")
    }

    func setReaderModeState(_ newReaderModeState: ReaderModeState) {
        let wasHidden = readerModeButton.isHidden
        self.readerModeButton.readerModeState = newReaderModeState
        readerModeButton.isHidden = (newReaderModeState == ReaderModeState.unavailable)
        if wasHidden != readerModeButton.isHidden {
            UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: nil)
            if !readerModeButton.isHidden {
                // Delay the Reader Mode accessibility announcement briefly to prevent interruptions.
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: String.ReaderModeAvailableVoiceOverAnnouncement)
                }
            }
        }
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.readerModeButton.alpha = newReaderModeState == .unavailable ? 0 : 1
        })
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

extension TabLocationView: UIDragInteractionDelegate {
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        // Ensure we actually have a URL in the location bar and that the URL is not local.
        guard let url = self.url,
              !InternalURL.isValid(url: url),
              let itemProvider = NSItemProvider(contentsOf: url)
        else { return [] }

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

// MARK: ThemeApplicable
extension TabLocationView: ThemeApplicable {
    func applyTheme(theme: Theme) {
        urlTextField.textColor = theme.colors.textPrimary
        baseURLFontColor = theme.colors.textPrimary
        readerModeButton.applyTheme(theme: theme)
        trackingProtectionButton.applyTheme(theme: theme)
        shareButton.applyTheme(theme: theme)
        reloadButton.applyTheme(theme: theme)
        menuBadge.badge.tintBackground(color: theme.colors.layer3)
    }
}

extension TabLocationView: TabEventHandler {
    func tabDidChangeContentBlocking(_ tab: Tab) {
        updateBlockerStatus(forTab: tab)
    }

    private func updateBlockerStatus(forTab tab: Tab) {
        guard let blocker = tab.contentBlocker else { return }

        ensureMainThread { [self] in
            trackingProtectionButton.alpha = 1.0

            var lockImage: UIImage?
            let imageID = themeManager.currentTheme.type.getThemedImageName(name: "lock_blocked")
            if !(tab.webView?.hasOnlySecureContent ?? false) {
                lockImage = UIImage(imageLiteralResourceName: imageID)
            } else if let tintColor = trackingProtectionButton.tintColor {
                lockImage = UIImage(imageLiteralResourceName: ImageIdentifiers.lockVerifed)
                    .withTintColor(tintColor, renderingMode: .alwaysTemplate)
            }

            switch blocker.status {
            case .blocking, .noBlockedURLs:
                trackingProtectionButton.setImage(lockImage, for: .normal)
            case .safelisted:
                if let smallDotImage = UIImage(systemName: "circle.fill")?.withTintColor(themeManager.currentTheme.colors.iconAccentBlue) {
                    trackingProtectionButton.setImage(lockImage?.overlayWith(image: smallDotImage), for: .normal)
                }
            case .disabled:
                trackingProtectionButton.setImage(lockImage, for: .normal)
            }
        }
    }

    func tabDidGainFocus(_ tab: Tab) {
        updateBlockerStatus(forTab: tab)
    }
}
