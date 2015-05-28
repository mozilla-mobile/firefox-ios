/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit


class SnackBarUX {
    static var MaxWidth: CGFloat = 400
}

/**
 * A specialized version of UIButton for use in SnackBars. These are displayed evenly
 * spaced in the bottom of the bar. The main convenience of these is that you can pass
 * in a callback in the constructor (although these also style themselves appropriately).
 *
 *``SnackButton(title: "OK", { _ in println("OK") })``
 */
class SnackButton : UIButton {
    let callback: (bar: SnackBar) -> Void
    private var bar: SnackBar!

    /**
     * An image to show as the background when a button is pressed. This is currently a 1x1 pixel blue color
     */
    lazy var highlightImg: UIImage = {
        let size = CGSize(width: 1, height: 1)
        return UIImage.createWithColor(size, color: AppConstants.HighlightColor)
    }()

    init(title: String, callback: (bar: SnackBar) -> Void) {
        self.callback = callback

        super.init(frame: CGRectZero)

        setTitle(title, forState: .Normal)
        titleLabel?.font = AppConstants.DefaultMediumFont
        setBackgroundImage(highlightImg, forState: .Highlighted)
        setTitleColor(AppConstants.HighlightText, forState: .Highlighted)

        addTarget(self, action: "onClick", forControlEvents: .TouchUpInside)
    }

    override init(frame: CGRect) {
        self.callback = { bar in }
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
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
 *         SnackButton(title: "OK", { _ in println("OK") }),
 *         SnackButton(title: "Cancel", { _ in println("Cancel") }),
 *         SnackButton(title: "Maybe", { _ in println("Maybe") })
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
        var attributes = [NSObject: AnyObject]()
        attributes[NSFontAttributeName] = AppConstants.DefaultMediumFont
        attributes[NSBackgroundColorAttributeName] = UIColor.clearColor()
        let attrText = NSAttributedString(string: text, attributes: attributes)
        self.init(attrText: attrText, img: img, buttons: buttons)
    }

    init(attrText: NSAttributedString, img: UIImage?, buttons: [SnackButton]?) {
        imageView = UIImageView()
        textLabel = UILabel()
        contentView = UIView()
        buttonsView = Toolbar()
        backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))

        super.init(frame: CGRectZero)

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
        backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))

        super.init(frame: frame)
    }

    private func setup() {
        textLabel.backgroundColor = nil

        addSubview(backgroundView)
        addSubview(contentView)
        contentView.addSubview(imageView)
        contentView.addSubview(textLabel)
        addSubview(buttonsView)

        self.backgroundColor = UIColor.clearColor()
        buttonsView.drawTopBorder = true
        buttonsView.drawBottomBorder = true
        buttonsView.drawSeperators = true

        imageView.contentMode = UIViewContentMode.TopLeft

        textLabel.font = AppConstants.DefaultMediumFont
        textLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        textLabel.numberOfLines = 0
        textLabel.backgroundColor = UIColor.clearColor()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let imageWidth: CGFloat
        if let img = imageView.image {
            imageWidth = img.size.width + AppConstants.DefaultPadding * 2
        } else {
            imageWidth = 0
        }
        self.textLabel.preferredMaxLayoutWidth = contentView.frame.width - (imageWidth + AppConstants.DefaultPadding)
        super.layoutSubviews()
    }

    /**
     * Called to check if the snackbar should be removed or not. By default, Snackbars persist forever.
     * Override this class or use a class like CountdownSnackbar if you want things expire
     * :returns: true if the snackbar should be kept alive
     */
    func shouldPersist(browser: Browser) -> Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()

        backgroundView.snp_remakeConstraints { make in
            make.edges.equalTo(self)
        }

        contentView.snp_remakeConstraints { make in
            make.top.left.right.equalTo(self).insets(EdgeInsetsMake(AppConstants.DefaultPadding, AppConstants.DefaultPadding, AppConstants.DefaultPadding, AppConstants.DefaultPadding	))
        }

        if let img = imageView.image {
            imageView.snp_remakeConstraints({ make in
                make.top.left.equalTo(contentView)
                // To avoid doubling the padding, the textview doesn't have an inset on its left side.
                // Instead, it relies on the imageView to tell it where its left side should be.
                make.width.equalTo(img.size.width + AppConstants.DefaultPadding)
                make.height.equalTo(img.size.height + AppConstants.DefaultPadding)
                make.bottom.lessThanOrEqualTo(contentView.snp_bottom)
            })
        } else {
            imageView.snp_remakeConstraints({ make in
                make.width.height.equalTo(0)
                make.top.left.equalTo(self)
                make.bottom.lessThanOrEqualTo(contentView.snp_bottom)
            })
        }

        textLabel.snp_remakeConstraints({ make in
            make.top.equalTo(contentView)
            make.left.equalTo(self.imageView.snp_right)
            make.trailing.equalTo(contentView)
            make.bottom.lessThanOrEqualTo(contentView.snp_bottom)
        })

        buttonsView.snp_remakeConstraints({ make in
            make.top.equalTo(contentView.snp_bottom).offset(AppConstants.DefaultPadding)
            make.bottom.equalTo(self.snp_bottom)
            make.left.right.equalTo(self)
            if self.buttonsView.subviews.count > 0 {
            	make.height.equalTo(AppConstants.ToolbarHeight)
            } else {
                make.height.equalTo(0)
            }
        })
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
            h = AppConstants.ToolbarHeight
        }
        bottom?.updateOffset(h)
    }

    private func addButton(snackButton: SnackButton) {
        snackButton.bar = self
        buttonsView.addButtons(snackButton)
        buttonsView.setNeedsUpdateConstraints()
    }
}

/**
 * A special version of a snackbar that persists for maxCount page loads.
 * Defaults to waiting for 2 loads (i.e. will persist over one page load,
 * which is useful for things like saving passwords.
 */
class CountdownSnackBar: SnackBar {
    private var maxCount: Int? = nil
    private var count = 0
    private var prevURL: NSURL? = nil

    init(maxCount: Int = 2, attrText: NSAttributedString, img: UIImage?, buttons: [SnackButton]?) {
        self.maxCount = maxCount
        super.init(attrText: attrText, img: img, buttons: buttons)
    }

    override init(frame: CGRect) {
        if maxCount == nil {
            maxCount = 2
        }
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func shouldPersist(browser: Browser) -> Bool {
        if browser.url != prevURL {
            prevURL = browser.url
            count++
            return count < maxCount
        }

        return super.shouldPersist(browser)
    }
}
