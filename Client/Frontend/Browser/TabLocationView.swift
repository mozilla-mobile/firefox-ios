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
    func tabLocationViewDidTapPageOptions(_ tabLocationView: TabLocationView, from button: UIButton)
    func tabLocationViewDidLongPressPageOptions(_ tabLocationVIew: TabLocationView)
    
    /// - returns: whether the long-press was handled by the delegate; i.e. return `false` when the conditions for even starting handling long-press were not satisfied
    @discardableResult func tabLocationViewDidLongPressReaderMode(_ tabLocationView: TabLocationView) -> Bool
    func tabLocationViewLocationAccessibilityActions(_ tabLocationView: TabLocationView) -> [UIAccessibilityCustomAction]?
}

private struct TabLocationViewUX {
    static let HostFontColor = UIColor.black
    static let BaseURLFontColor = UIColor.gray
    static let LocationContentInset = 8
    static let URLBarPadding = 4
}

class TabLocationView: UIView {
    var delegate: TabLocationViewDelegate?
    var longPressRecognizer: UILongPressGestureRecognizer!
    var tapRecognizer: UITapGestureRecognizer!

    dynamic var baseURLFontColor: UIColor = TabLocationViewUX.BaseURLFontColor {
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
            pageOptionsButton.isHidden = (url == nil)
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
                separatorLine.isHidden = readerModeButton.isHidden
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
        urlTextField.setContentCompressionResistancePriority(250, for: .horizontal)
        urlTextField.attributedPlaceholder = self.placeholder
        urlTextField.accessibilityIdentifier = "url"
        urlTextField.accessibilityActionsSource = self
        urlTextField.font = UIConstants.DefaultChromeFont
        urlTextField.backgroundColor = .clear

        // Remove the default drop interaction from the URL text field so that our
        // custom drop interaction on the BVC can accept dropped URLs.
        if #available(iOS 11, *) {
            if let dropInteraction = urlTextField.textDropInteraction {
                urlTextField.removeInteraction(dropInteraction)
            }
        }

        return urlTextField
    }()

    fileprivate lazy var lockImageView: UIImageView = {
        let lockImageView = UIImageView(image: UIImage.templateImageNamed("lock_verified"))
        lockImageView.isHidden = true
        lockImageView.tintColor = UIColor.Defaults.LockGreen
        lockImageView.isAccessibilityElement = true
        lockImageView.contentMode = .center
        lockImageView.accessibilityLabel = NSLocalizedString("Secure connection", comment: "Accessibility label for the lock icon, which is only present if the connection is secure")
        return lockImageView
    }()

    fileprivate lazy var readerModeButton: ReaderModeButton = {
        let readerModeButton = ReaderModeButton(frame: .zero)
        readerModeButton.isHidden = true
        readerModeButton.addTarget(self, action: #selector(SELtapReaderModeButton), for: .touchUpInside)
        readerModeButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(SELlongPressReaderModeButton)))
        readerModeButton.isAccessibilityElement = true
        readerModeButton.imageView?.contentMode = .scaleAspectFit
        readerModeButton.accessibilityLabel = NSLocalizedString("Reader View", comment: "Accessibility label for the Reader View button")
        readerModeButton.accessibilityIdentifier = "TabLocationView.readerModeButton"
        readerModeButton.accessibilityCustomActions = [UIAccessibilityCustomAction(name: NSLocalizedString("Add to Reading List", comment: "Accessibility label for action adding current page to reading list."), target: self, selector: #selector(SELreaderModeCustomAction))]
        return readerModeButton
    }()
    
    lazy var pageOptionsButton: ToolbarButton = {
        let pageOptionsButton = ToolbarButton(frame: .zero)
        pageOptionsButton.setImage(UIImage.templateImageNamed("menu-More-Options"), for: .normal)
        pageOptionsButton.isHidden = true
        pageOptionsButton.addTarget(self, action: #selector(SELDidPressPageOptionsButton), for: .touchUpInside)
        pageOptionsButton.isAccessibilityElement = true
        pageOptionsButton.imageView?.contentMode = .center
        pageOptionsButton.accessibilityLabel = NSLocalizedString("Page Options Menu", comment: "Accessibility label for the Page Options menu button")
        pageOptionsButton.accessibilityIdentifier = "TabLocationView.pageOptionsButton"
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(SELDidLongPressPageOptionsButton))
        pageOptionsButton.addGestureRecognizer(longPressGesture)
        return pageOptionsButton
    }()
    
    lazy var separatorLine: UIView = {
        let line = UIView()
        line.layer.cornerRadius = 2
        line.isHidden = true
        return line
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(SELlongPressLocation))
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(SELtapLocation))

        addSubview(urlTextField)
        addSubview(lockImageView)
        addSubview(readerModeButton)
        addSubview(pageOptionsButton)
        addSubview(separatorLine)

        lockImageView.snp.makeConstraints { make in
            make.size.equalTo(24)
            make.centerY.equalTo(self)
            make.leading.equalTo(self).offset(9)
        }

        pageOptionsButton.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.trailing.equalTo(self)
            make.width.equalTo(44)
            make.height.equalTo(self)
        }
        
        separatorLine.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(26)
            make.trailing.equalTo(pageOptionsButton.snp.leading)
            make.centerY.equalTo(self)
        }
        
        readerModeButton.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.trailing.equalTo(separatorLine.snp.leading).offset(-9)
            make.size.equalTo(24)
        }
    }

    override var accessibilityElements: [Any]? {
        get {
            return [lockImageView, urlTextField, readerModeButton, pageOptionsButton].filter { !$0.isHidden }
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
                make.leading.equalTo(self.lockImageView.snp.trailing).offset(TabLocationViewUX.URLBarPadding)
            }

            if readerModeButton.isHidden {
                make.trailing.equalTo(self.pageOptionsButton.snp.leading).offset(-TabLocationViewUX.URLBarPadding)
            } else {
                make.trailing.equalTo(self.readerModeButton.snp.leading).offset(-TabLocationViewUX.URLBarPadding)
            }
        }

        super.updateConstraints()
    }

    func SELtapReaderModeButton() {
        delegate?.tabLocationViewDidTapReaderMode(self)
    }

    func SELlongPressReaderModeButton(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            delegate?.tabLocationViewDidLongPressReaderMode(self)
        }
    }
    
    func SELDidPressPageOptionsButton(_ button: UIButton) {
        delegate?.tabLocationViewDidTapPageOptions(self, from: button)
    }
    
    func SELDidLongPressPageOptionsButton(_ recognizer: UILongPressGestureRecognizer) {
        delegate?.tabLocationViewDidLongPressPageOptions(self)
    }

    func SELlongPressLocation(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .began {
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
    func applyTheme(_ theme: Theme) {
        backgroundColor = UIColor.TextField.Background.colorFor(theme)
        urlTextField.textColor = UIColor.Browser.Tint.colorFor(theme)
        readerModeButton.selectedTintColor = UIColor.TextField.ReaderModeButtonSelected.colorFor(theme)
        readerModeButton.unselectedTintColor = UIColor.TextField.ReaderModeButtonUnselected.colorFor(theme)
        
        pageOptionsButton.selectedTintColor = UIColor.TextField.PageOptionsSelected.colorFor(theme)
        pageOptionsButton.unselectedTintColor = UIColor.TextField.PageOptionsUnselected.colorFor(theme)
        pageOptionsButton.tintColor = pageOptionsButton.unselectedTintColor
        separatorLine.backgroundColor = UIColor.TextField.Separator.colorFor(theme)
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
