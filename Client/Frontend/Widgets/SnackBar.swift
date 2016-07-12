/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import Shared

class SnackBarUX {
    static var MaxWidth: CGFloat = 400
}

/**
 * A specialized version of UIButton for use in SnackBars. These are displayed evenly
 * spaced in the bottom of the bar. The main convenience of these is that you can pass
 * in a callback in the constructor (although these also style themselves appropriately).
 *
 *``SnackButton(title: "OK", { _ in print("OK", terminator: "\n") })``
 */
class SnackButton : UIButton {
    let callback: (bar: SnackBar) -> Void
    private var bar: SnackBar!

    /**
     * An image to show as the background when a button is pressed. This is currently a 1x1 pixel blue color
     */
    lazy var highlightImg: UIImage = {
        let size = CGSize(width: 1, height: 1)
        return UIImage.createWithColor(size, color: UIConstants.HighlightColor)
    }()

    init(title: String, accessibilityIdentifier: String, callback: (bar: SnackBar) -> Void) {
        self.callback = callback

        super.init(frame: CGRect.zero)

        setTitle(title, for: UIControlState())
        titleLabel?.font = DynamicFontHelper.defaultHelper.DefaultMediumFont
        setBackgroundImage(highlightImg, for: .highlighted)
        setTitleColor(UIConstants.HighlightText, for: .highlighted)

        addTarget(self, action: #selector(SnackButton.onClick), for: .touchUpInside)

        self.accessibilityIdentifier = accessibilityIdentifier
    }

    override init(frame: CGRect) {
        self.callback = { bar in }
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func onClick() {
        callback(bar: bar)
    }

}

/**
 * Presents some information to the user. Can optionally include some buttons and an image. Usage:
 *
 * ``let bar = SnackBar(text: "This is some text in the snackbar.",
 *     img: UIImage(named: "bookmark"),
 *     buttons: [
 *         SnackButton(title: "OK", { _ in print("OK", terminator: "\n") }),
 *         SnackButton(title: "Cancel", { _ in print("Cancel", terminator: "\n") }),
 *         SnackButton(title: "Maybe", { _ in print("Maybe", terminator: "\n") })
 *     ]
 * )``
 */
class SnackBar: UIView {
    let imageView: UIImageView
    let textLabel: UILabel
    let contentView: UIView
    let backgroundView: UIView
    let buttonsView: Toolbar
    private var buttons = [SnackButton]()
    // The Constraint for the bottom of this snackbar. We use this to transition it
    var bottom: Constraint?

    convenience init(text: String, img: UIImage?, buttons: [SnackButton]?) {
        var attributes = [String: AnyObject]()
        attributes[NSFontAttributeName] = DynamicFontHelper.defaultHelper.DefaultMediumFont
        attributes[NSBackgroundColorAttributeName] = UIColor.clear()
        let attrText = AttributedString(string: text, attributes: attributes)
        self.init(attrText: attrText, img: img, buttons: buttons)
    }

    init(attrText: AttributedString, img: UIImage?, buttons: [SnackButton]?) {
        imageView = UIImageView()
        textLabel = UILabel()
        contentView = UIView()
        buttonsView = Toolbar()
        backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.extraLight))

        super.init(frame: CGRect.zero)

        imageView.image = img
        textLabel.attributedText = attrText
        if let buttons = buttons {
            for button in buttons {
                addButton(button)
            }
        }
        setup()
    }

    private override init(frame: CGRect) {
        imageView = UIImageView()
        textLabel = UILabel()
        contentView = UIView()
        buttonsView = Toolbar()
        backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.extraLight))

        super.init(frame: frame)
    }

    private func setup() {
        textLabel.backgroundColor = nil

        addSubview(backgroundView)
        addSubview(contentView)
        contentView.addSubview(imageView)
        contentView.addSubview(textLabel)
        addSubview(buttonsView)

        self.backgroundColor = UIColor.clear()
        buttonsView.drawTopBorder = true
        buttonsView.drawBottomBorder = false
        buttonsView.drawSeperators = true

        imageView.contentMode = UIViewContentMode.left

        textLabel.font = DynamicFontHelper.defaultHelper.DefaultMediumFont
        textLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        textLabel.numberOfLines = 0
        textLabel.backgroundColor = UIColor.clear()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let imageWidth: CGFloat
        if let img = imageView.image {
            imageWidth = img.size.width + UIConstants.DefaultPadding * 2
        } else {
            imageWidth = 0
        }
        self.textLabel.preferredMaxLayoutWidth = contentView.frame.width - (imageWidth + UIConstants.DefaultPadding)
        super.layoutSubviews()
    }

    private func drawLine(_ context: CGContext, start: CGPoint, end: CGPoint) {
        context.setStrokeColor(UIConstants.BorderColor.cgColor)
        context.setLineWidth(1)
        context.moveTo(x: start.x, y: start.y)
        context.addLineTo(x: end.x, y: end.y)
        context.strokePath()
    }

    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        drawLine(context!, start: CGPoint(x: 0, y: 1), end: CGPoint(x: frame.size.width, y: 1))
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

        backgroundView.snp_remakeConstraints { make in
            make.bottom.left.right.equalTo(self)
            // Offset it by the width of the top border line so we can see the line from the super view
            make.top.equalTo(self).offset(1)
        }

        contentView.snp_remakeConstraints { make in
            make.top.left.right.equalTo(self).inset(EdgeInsetsMake(UIConstants.DefaultPadding, left: UIConstants.DefaultPadding, bottom: UIConstants.DefaultPadding, right: UIConstants.DefaultPadding))
        }

        if let img = imageView.image {
            imageView.snp_remakeConstraints { make in
                make.left.centerY.equalTo(contentView)
                // To avoid doubling the padding, the textview doesn't have an inset on its left side.
                // Instead, it relies on the imageView to tell it where its left side should be.
                make.width.equalTo(img.size.width + UIConstants.DefaultPadding)
                make.height.equalTo(img.size.height + UIConstants.DefaultPadding)
            }
        } else {
            imageView.snp_remakeConstraints { make in
                make.width.height.equalTo(0)
                make.top.left.equalTo(self)
                make.bottom.lessThanOrEqualTo(contentView.snp_bottom)
            }
        }

        textLabel.snp_remakeConstraints { make in
            make.top.equalTo(contentView)
            make.left.equalTo(self.imageView.snp_right)
            make.trailing.equalTo(contentView)
            make.bottom.lessThanOrEqualTo(contentView.snp_bottom)
        }

        buttonsView.snp_remakeConstraints { make in
            make.top.equalTo(contentView.snp_bottom).offset(UIConstants.DefaultPadding)
            make.bottom.equalTo(self.snp_bottom)
            make.left.right.equalTo(self)
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

    /**
     * Helper for animating the Snackbar showing on screen.
     */
    func show() {
        alpha = 1
        bottom?.updateOffset(0)
    }

    /**
     * Helper for animating the Snackbar leaving the screen.
     */
    func hide() {
        alpha = 0
        var h = frame.height
        if h == 0 {
            h = UIConstants.ToolbarHeight
        }
        bottom?.updateOffset(h)
    }

    private func addButton(_ snackButton: SnackButton) {
        snackButton.bar = self
        buttonsView.addButtons(snackButton)
        buttonsView.setNeedsUpdateConstraints()
    }
}

/**
 * A special version of a snackbar that persists for at least a timeout. After that
 * it will dismiss itself on the next page load where this tab isn't showing. As long as
 * you stay on the current tab though, it will persist until you interact with it.
 */
class TimerSnackBar: SnackBar {
    private var prevURL: URL? = nil
    private var timer: Timer? = nil
    private var timeout: TimeInterval

    init(timeout: TimeInterval = 10, attrText: AttributedString, img: UIImage?, buttons: [SnackButton]?) {
        self.timeout = timeout
        super.init(attrText: attrText, img: img, buttons: buttons)
    }

    override init(frame: CGRect) {
        self.timeout = 0
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func show() {
        self.timer = Timer(timeInterval: timeout, target: self, selector: #selector(TimerSnackBar.SELTimerDone), userInfo: nil, repeats: false)
        RunLoop.current.add(self.timer!, forMode: RunLoopMode.defaultRunLoopMode)
        super.show()
    }

    @objc
    func SELTimerDone() {
        self.timer = nil
    }

    override func shouldPersist(_ tab: Tab) -> Bool {
        if !showing {
            return timer != nil
        }

        return super.shouldPersist(tab)
    }
}
