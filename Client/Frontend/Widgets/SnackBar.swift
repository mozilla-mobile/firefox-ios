/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit


/**
A specialized version of UIButton for use in SnackBars. These are displayed evenly spaced in the bottom of the bar. The main convenience of these is that you can pass in a callback in the constructor (although these also style themselves appropriately).

``SnackButton(title: "OK", { _ in println("OK") })``
*/
class SnackButton : UIButton {
    let callback: (bar: SnackBar) -> Void
    private var bar: SnackBar!

    /**
    An image to show as the background when a button is pressed. This is currently a 1x1 pixel blue color
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
Presents some information to the user. Can optionally include some buttons and an image. Usage:

``let bar = SnackBar(text: "This is some text in the snackbar.",
     img: UIImage(named: "bookmark"),
     buttons: [
         SnackButton(title: "OK", { _ in println("OK") }),
         SnackButton(title: "Cancel", { _ in println("Cancel") }),
         SnackButton(title: "Maybe", { _ in println("Maybe") })]
 )``
*/

class SnackBar: UIView {
    let imageView: UIImageView
    let textView: UITextView
    let backgroundView: UIView
    let buttonsView: Toolbar
    let progress: UIProgressView

    // A list of buttons shown on the view
    private let buttons: [SnackButton]
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
        textView = UITextView()
        buttonsView = Toolbar()
        backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
        progress = UIProgressView()
        self.buttons = buttons ?? [SnackButton]()

        super.init(frame: CGRectZero)

        imageView.image = img
        textView.attributedText = attrText
        if let buttons = buttons {
            for button in buttons {
                addButton(button)
            }
        }
        setup()
    }

    private override init(frame: CGRect) {
        imageView = UIImageView()
        textView = UITextView()
        buttonsView = Toolbar()
        backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
        progress = UIProgressView()
        self.buttons = [SnackButton]()

        super.init(frame: frame)
    }

    private func setup() {
        textView.backgroundColor = nil

        insertSubview(backgroundView, atIndex: 0)
        addSubview(imageView)
        addSubview(textView)
        addSubview(buttonsView)
        addSubview(progress)

        progress.hidden = true

        self.backgroundColor = UIColor.clearColor()
        if buttons.count > 1 {
            buttonsView.drawTopBorder = true
            buttonsView.drawBottomBorder = true
            buttonsView.drawSeperators = true
        } else {
            buttonsView.drawLeftBorder = true
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setProgress(progress: Float, animated: Bool) {
        if progress < 1.0 {
            self.progress.hidden = false
        } else {
            self.progress.hidden = true
        }
        self.progress.setProgress(progress, animated: animated)
    }

    /**
    Called to check if the snackbar should be removed or not. By default, Snackbars persist forever. Override this class or use a class like CountdownSnackbar if you want things expire
    :returns: true if the snackbar should be kept alive
    */
    func shouldPersist(browser: Browser) -> Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()

        // The background will cover the entire view
        backgroundView.snp_remakeConstraints { make in
            make.edges.equalTo(self)
            return
        }

        // Show an optional image to the left
        if let img = imageView.image {
            imageView.snp_remakeConstraints({ make in
                make.width.equalTo(img.size.width)
                make.height.equalTo(img.size.height)
                make.top.left.equalTo(self).offset(AppConstants.DefaultPadding)
            })
        } else {
            // If there is no image, we still place this but make it zero width
            // (so that other views can position themselves relative to it).
            imageView.snp_remakeConstraints({ make in
                make.width.equalTo(0)
                make.height.equalTo(0)
                make.top.left.equalTo(self).offset(AppConstants.DefaultPadding)
            })
        }

        let labelSize: CGSize
        // If there's only one button, we show it to the right of the text
        if buttons.count == 1 {
            let buttonSize = buttons[0].titleLabel?.sizeThatFits(CGSizeMake(self.frame.width, CGFloat(MAXFLOAT))).width ?? 0
            buttonsView.snp_remakeConstraints({ make in
                make.top.equalTo(self.snp_top)
                make.right.equalTo(self.snp_right)
                make.height.equalTo(self.snp_height)
                make.width.equalTo(buttonSize + 2 * AppConstants.DefaultPadding)
            })

            // Stretch the label betweeen the image and button
            labelSize = self.textView.sizeThatFits(CGSizeMake(self.frame.width - buttonSize - 2*AppConstants.DefaultPadding, CGFloat(MAXFLOAT)))
            textView.textAlignment = NSTextAlignment.Justified
            textView.snp_remakeConstraints({ make in
                make.top.equalTo(self.imageView.snp_top).offset(-5)
                make.left.equalTo(self.imageView.snp_right)

                make.height.equalTo(labelSize.height)
                make.right.equalTo(buttonsView.snp_left)
            })

            // Show a progress bar along the bottom
            progress.snp_remakeConstraints({ make in
                make.leading.trailing.equalTo(self)
                make.bottom.equalTo(self.snp_bottom)
            })
        } else {
            // If there's more than one, we show it below the text and icon
            buttonsView.snp_remakeConstraints({ make in
                make.bottom.equalTo(self)
                make.left.right.equalTo(self)
                if self.buttonsView.subviews.count > 0 {
                    make.height.equalTo(AppConstants.ToolbarHeight)
                } else {
                    make.height.equalTo(0)
                }
            })

            // Stretch the label all the way to the edge of the view
            labelSize = self.textView.sizeThatFits(CGSizeMake(self.frame.width, CGFloat(MAXFLOAT)))
            textView.textContainerInset = UIEdgeInsetsZero
            textView.snp_remakeConstraints({ make in
                make.top.equalTo(self.imageView.snp_top)
                make.left.equalTo(self.imageView.snp_right)

                make.height.equalTo(labelSize.height)
                make.right.equalTo(self.snp_right)
            })

            // Show a progress bar above the button
            progress.snp_remakeConstraints({ make in
                make.leading.trailing.equalTo(self)
                make.bottom.equalTo(self.buttonsView.snp_top)
            })
        }

        self.snp_makeConstraints({ make in
            var h = labelSize.height
            if let img = self.imageView.image {
                h = max(img.size.height, labelSize.height)
            }

            if (self.buttonsView.subviews.count > 1) {
                make.height.equalTo(2 * AppConstants.DefaultPadding + h + AppConstants.ToolbarHeight)
            } else {
                make.height.equalTo(2 * AppConstants.DefaultPadding + h)
            }
        })
    }

    /**
    Helper for animating the Snackbar showing on screen
    */
    func show() {
        alpha = 1
        bottom?.updateOffset(0)
    }

    /**
    Helper for animating the Snackbar leaving the screen
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
A special version of a snackbar that persists for maxCount page loads. Defaults to waiting for 2 loads (i.e. will persist over one page load, which is useful for things like saving passwords.
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
