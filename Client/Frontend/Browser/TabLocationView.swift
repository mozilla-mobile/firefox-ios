/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared
import SnapKit
import XCGLogger

private let log = Logger.browserLogger

protocol TabLocationViewDelegate {
    func tabLocationViewDidTapLocation(_ tabLocationView: TabLocationView)
    func tabLocationViewDidLongPressLocation(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapReaderMode(_ tabLocationView: TabLocationView)
    /// - returns: whether the long-press was handled by the delegate; i.e. return `false` when the conditions for even starting handling long-press were not satisfied
    @discardableResult func tabLocationViewDidLongPressReaderMode(_ tabLocationView: TabLocationView) -> Bool
    func tabLocationViewLocationAccessibilityActions(_ tabLocationView: TabLocationView) -> [UIAccessibilityCustomAction]?
}

struct TabLocationViewUX {
    static let HostFontColor = UIColor.black
    static let BaseURLFontColor = UIColor.gray
    static let BaseURLPitch = 0.75
    static let HostPitch = 1.0
    static let LocationContentInset = 8

    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.URLFontColor = UIColor.lightGray
        theme.hostFontColor = UIColor.white
        theme.backgroundColor = UIConstants.PrivateModeLocationBackgroundColor
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.URLFontColor = BaseURLFontColor
        theme.hostFontColor = HostFontColor
        theme.backgroundColor = UIColor.white
        themes[Theme.NormalMode] = theme

        return themes
    }()
}

class TabLocationView: UIView {
    var delegate: TabLocationViewDelegate?
    var longPressRecognizer: UILongPressGestureRecognizer!
    var tapRecognizer: UITapGestureRecognizer!

    dynamic var baseURLFontColor: UIColor = TabLocationViewUX.BaseURLFontColor {
        didSet { updateTextWithURL() }
    }

    dynamic var hostFontColor: UIColor = TabLocationViewUX.HostFontColor {
        didSet { updateTextWithURL() }
    }

    var url: URL? {
        didSet {
            let wasHidden = lockImageView.isHidden
            lockImageView.isHidden = url?.scheme != "https"
            if wasHidden != lockImageView.isHidden {
                UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
            }
            updateTextWithURL()
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
                    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
                    if !readerModeButton.isHidden {
                        // Delay the Reader Mode accessibility announcement briefly to prevent interruptions.
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, Strings.ReaderModeAvailableVoiceOverAnnouncement)
                        }
                    }
                }
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    if newReaderModeState == ReaderModeState.unavailable {
                        self.readerModeButton.alpha = 0.0
                    } else {
                        self.readerModeButton.alpha = 1.0
                    }
                    self.setNeedsUpdateConstraints()
                    self.layoutIfNeeded()
                })
            }
        }
    }

    lazy var placeholder: NSAttributedString = {
        let placeholderText = NSLocalizedString("Search or enter address", comment: "The text shown in the URL bar on about:home")
        return NSAttributedString(string: placeholderText, attributes: [NSForegroundColorAttributeName: UIColor.gray])
    }()

    lazy var urlTextField: UITextField = {
        let urlTextField = DisplayTextField()

        self.longPressRecognizer.delegate = self
        urlTextField.addGestureRecognizer(self.longPressRecognizer)
        self.tapRecognizer.delegate = self
        urlTextField.addGestureRecognizer(self.tapRecognizer)

        // Prevent the field from compressing the toolbar buttons on the 4S in landscape.
        urlTextField.setContentCompressionResistancePriority(250, for: UILayoutConstraintAxis.horizontal)

        urlTextField.attributedPlaceholder = self.placeholder
        urlTextField.accessibilityIdentifier = "url"
        urlTextField.accessibilityActionsSource = self
        urlTextField.font = UIConstants.DefaultChromeFont
        return urlTextField
    }()

    fileprivate lazy var lockImageView: UIImageView = {
        let lockImageView = UIImageView(image: UIImage(named: "lock_verified.png"))
        lockImageView.isHidden = true
        lockImageView.isAccessibilityElement = true
        lockImageView.contentMode = UIViewContentMode.center
        lockImageView.accessibilityLabel = NSLocalizedString("Secure connection", comment: "Accessibility label for the lock icon, which is only present if the connection is secure")
        return lockImageView
    }()

    fileprivate lazy var readerModeButton: ReaderModeButton = {
        let readerModeButton = ReaderModeButton(frame: CGRect.zero)
        readerModeButton.isHidden = true
        readerModeButton.addTarget(self, action: #selector(TabLocationView.SELtapReaderModeButton), for: .touchUpInside)
        readerModeButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(TabLocationView.SELlongPressReaderModeButton(_:))))
        readerModeButton.isAccessibilityElement = true
        readerModeButton.accessibilityLabel = NSLocalizedString("Reader View", comment: "Accessibility label for the Reader View button")
        readerModeButton.accessibilityCustomActions = [UIAccessibilityCustomAction(name: NSLocalizedString("Add to Reading List", comment: "Accessibility label for action adding current page to reading list."), target: self, selector: #selector(TabLocationView.SELreaderModeCustomAction))]
        return readerModeButton
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(TabLocationView.SELlongPressLocation(_:)))
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(TabLocationView.SELtapLocation(_:)))

        addSubview(urlTextField)
        addSubview(lockImageView)
        addSubview(readerModeButton)

        lockImageView.snp.makeConstraints { make in
            make.leading.centerY.equalTo(self)
            make.width.equalTo(self.lockImageView.intrinsicContentSize.width + CGFloat(TabLocationViewUX.LocationContentInset * 2))
        }

        readerModeButton.snp.makeConstraints { make in
            make.trailing.centerY.equalTo(self)
            make.width.equalTo(self.readerModeButton.intrinsicContentSize.width + CGFloat(TabLocationViewUX.LocationContentInset * 2))
        }
    }

    override var accessibilityElements: [Any]? {
        get {
            return [lockImageView, urlTextField, readerModeButton].filter { !$0.isHidden }
        }
        set {
            super.accessibilityElements = newValue
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        urlTextField.snp.remakeConstraints { make in
            make.top.bottom.equalTo(self)

            if lockImageView.isHidden {
                make.leading.equalTo(self).offset(TabLocationViewUX.LocationContentInset)
            } else {
                make.leading.equalTo(self.lockImageView.snp.trailing)
            }

            if readerModeButton.isHidden {
                make.trailing.equalTo(self).offset(-TabLocationViewUX.LocationContentInset)
            } else {
                make.trailing.equalTo(self.readerModeButton.snp.leading)
            }
        }

        super.updateConstraints()
    }

    func SELtapReaderModeButton() {
        delegate?.tabLocationViewDidTapReaderMode(self)
    }

    func SELlongPressReaderModeButton(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.began {
            delegate?.tabLocationViewDidLongPressReaderMode(self)
        }
    }

    func SELlongPressLocation(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.began {
            delegate?.tabLocationViewDidLongPressLocation(self)
        }
    }

    func SELtapLocation(_ recognizer: UITapGestureRecognizer) {
        delegate?.tabLocationViewDidTapLocation(self)
    }

    func SELreaderModeCustomAction() -> Bool {
        return delegate?.tabLocationViewDidLongPressReaderMode(self) ?? false
    }

    fileprivate func updateTextWithURL() {
        if let httplessURL = url?.absoluteDisplayString, let baseDomain = url?.baseDomain {
            // Highlight the base domain of the current URL.
            let attributedString = NSMutableAttributedString(string: httplessURL)
            let nsRange = NSRange(location: 0, length: httplessURL.characters.count)
            attributedString.addAttribute(NSForegroundColorAttributeName, value: baseURLFontColor, range: nsRange)
            attributedString.colorSubstring(baseDomain, withColor: hostFontColor)
            attributedString.addAttribute(UIAccessibilitySpeechAttributePitch, value: NSNumber(value: TabLocationViewUX.BaseURLPitch), range: nsRange)
            attributedString.pitchSubstring(baseDomain, withPitch: TabLocationViewUX.HostPitch)
            urlTextField.attributedText = attributedString
        } else {
            // If we're unable to highlight the domain, just use the URL as is.
            if let host = url?.host, AppConstants.MOZ_PUNYCODE {
                urlTextField.text = url?.absoluteString.replacingOccurrences(of: host, with: host.asciiHostToUTF8())
            } else {
                urlTextField.text = url?.absoluteString
            }
        }
    }
}

extension TabLocationView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // If the longPressRecognizer is active, fail all other recognizers to avoid conflicts.
        return gestureRecognizer == longPressRecognizer
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
    func applyTheme(_ themeName: String) {
        guard let theme = TabLocationViewUX.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }
        baseURLFontColor = theme.URLFontColor!
        hostFontColor = theme.hostFontColor!
        backgroundColor = theme.backgroundColor
    }
}

private class ReaderModeButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setImage(UIImage(named: "reader.png"), for: UIControlState())
        setImage(UIImage(named: "reader_active.png"), for: UIControlState.selected)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var _readerModeState: ReaderModeState = ReaderModeState.unavailable
    
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
}
