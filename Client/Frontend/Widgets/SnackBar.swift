/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import Shared

class SnackBarUX {
    static var MaxWidth: CGFloat = 400
    static let BorderWidth: CGFloat = 0.5
    static let HighlightColor = UIColor(red: 205/255, green: 223/255, blue: 243/255, alpha: 0.9)
    static let HighlightText = UIColor(red: 42/255, green: 121/255, blue: 213/255, alpha: 1.0)
}

/**
 * A specialized version of UIButton for use in SnackBars. These are displayed evenly
 * spaced in the bottom of the bar. The main convenience of these is that you can pass
 * in a callback in the constructor (although these also style themselves appropriately).
 */
typealias SnackBarCallback = (_ bar: SnackBar) -> Void
class SnackButton: UIButton {
    let callback: SnackBarCallback?
    fileprivate var bar: SnackBar!

    override open var isHighlighted: Bool {
        didSet {
            self.backgroundColor = isHighlighted ? SnackBarUX.HighlightColor : .clear
        }
    }

    init(title: String, accessibilityIdentifier: String, callback: @escaping SnackBarCallback) {
        self.callback = callback

        super.init(frame: .zero)

        setTitle(title, for: .normal)
        titleLabel?.font = DynamicFontHelper.defaultHelper.DefaultMediumFont
        setTitleColor(SnackBarUX.HighlightText, for: .highlighted)
        setTitleColor(SettingsUX.TableViewRowTextColor, for: .normal)
        addTarget(self, action: #selector(onClick), for: .touchUpInside)
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func onClick() {
        callback?(bar)
    }

    func drawSeparator() {
        let separator = UIView()
        separator.backgroundColor = UIConstants.BorderColor
        self.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.equalTo(self)
            make.width.equalTo(SnackBarUX.BorderWidth)
            make.top.bottom.equalTo(self)
        }
    }

}

class SnackBar: UIView {
    let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        // These are requried to make sure that the image is _never_ smaller or larger than its actual size
        imageView.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        imageView.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        return imageView
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = DynamicFontHelper.defaultHelper.DefaultMediumFont
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        label.backgroundColor = nil
        label.numberOfLines = 0
        label.textColor = SettingsUX.TableViewRowTextColor
        label.backgroundColor = UIColor.clear
        return label
    }()

    private lazy var buttonsView: UIStackView = {
        let stack = UIStackView()
        stack.distribution = .fillEqually
        return stack
    }()

    private lazy var titleView: UIStackView = {
        let stack = UIStackView()
        stack.spacing = UIConstants.DefaultPadding
        stack.distribution = .fill
        stack.axis = .horizontal
        stack.alignment = .center
        return stack
    }()

    // The Constraint for the bottom of this snackbar. We use this to transition it
    var bottom: Constraint?

    init(text: String, img: UIImage?) {
        super.init(frame: .zero)

        imageView.image = img ?? UIImage(named: "defaultFavicon")
        textLabel.text = text
        setup()
    }

    fileprivate func setup() {
        addSubview(backgroundView)
        titleView.addArrangedSubview(imageView)
        titleView.addArrangedSubview(textLabel)

        let separator = UIView()
        separator.backgroundColor = UIConstants.BorderColor

        addSubview(titleView)
        addSubview(separator)
        addSubview(buttonsView)

        separator.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.height.equalTo(SnackBarUX.BorderWidth)
            make.top.equalTo(buttonsView.snp.top).offset(-1)
        }

        backgroundView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(self)
            // Offset it by the width of the top border line so we can see the line from the super view
            make.top.equalTo(self).offset(1)
        }

        titleView.snp.makeConstraints { make in
            make.top.equalTo(self).offset(UIConstants.DefaultPadding)
            make.centerX.equalTo(self).priority(500)
            make.width.lessThanOrEqualTo(self).inset(UIConstants.DefaultPadding * 2).priority(1000)
        }

        backgroundColor = UIColor.clear
        self.layer.borderWidth = SnackBarUX.BorderWidth
        self.layer.borderColor = UIConstants.BorderColor.cgColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     * Called to check if the snackbar should be removed or not. By default, Snackbars persist forever.
     * Override this class or use a class like CountdownSnackbar if you want things expire
     * - returns: true if the snackbar should be kept alive
     */
    func shouldPersist(_ tab: Tab) -> Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()

        buttonsView.snp.remakeConstraints { make in
            make.top.equalTo(titleView.snp.bottom).offset(UIConstants.DefaultPadding)
            make.bottom.equalTo(self.snp.bottom)
            make.leading.trailing.equalTo(self)
            if self.buttonsView.subviews.count > 0 {
                make.height.equalTo(UIConstants.SnackbarButtonHeight)
            } else {
                make.height.equalTo(0)
            }
        }
    }

    var showing: Bool {
        return alpha != 0 && self.superview != nil
    }

    func show() {
        alpha = 1
        bottom?.update(offset: 0)
    }

    func addButton(_ snackButton: SnackButton) {
        snackButton.bar = self
        buttonsView.addArrangedSubview(snackButton)

        // Only show the separator on the left of the button if it is not the first view
        if buttonsView.arrangedSubviews.count != 1 {
            snackButton.drawSeparator()
        }
    }
}

/**
 * A special version of a snackbar that persists for at least a timeout. After that
 * it will dismiss itself on the next page load where this tab isn't showing. As long as
 * you stay on the current tab though, it will persist until you interact with it.
 */
class TimerSnackBar: SnackBar {
    fileprivate var timer: Timer?
    fileprivate var timeout: TimeInterval

    init(timeout: TimeInterval = 10, text: String, img: UIImage?) {
        self.timeout = timeout
        super.init(text: text, img: img)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func showAppStoreConfirmationBar(forTab tab: Tab, appStoreURL: URL) {
        let bar = TimerSnackBar(text: Strings.ExternalLinkAppStoreConfirmationTitle, img: UIImage(named: "defaultFavicon"))
        let openAppStore = SnackButton(title: Strings.OKString, accessibilityIdentifier: "ConfirmOpenInAppStore") { bar in
            tab.removeSnackbar(bar)
            UIApplication.shared.openURL(appStoreURL)
        }
        let cancelButton = SnackButton(title: Strings.CancelString, accessibilityIdentifier: "CancelOpenInAppStore") { bar in
            tab.removeSnackbar(bar)
        }
        bar.addButton(openAppStore)
        bar.addButton(cancelButton)
        tab.addSnackbar(bar)
    }
    
    override func show() {
        self.timer = Timer(timeInterval: timeout, target: self, selector: #selector(timerDone), userInfo: nil, repeats: false)
        RunLoop.current.add(self.timer!, forMode: RunLoopMode.defaultRunLoopMode)
        super.show()
    }

    @objc func timerDone() {
        self.timer = nil
    }

    override func shouldPersist(_ tab: Tab) -> Bool {
        if !showing {
            return timer != nil
        }
        return super.shouldPersist(tab)
    }
}
