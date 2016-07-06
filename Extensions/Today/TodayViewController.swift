/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import NotificationCenter
import Shared
import SnapKit

private let log = Logger.browserLogger

struct TodayUX {
    static let privateBrowsingColor = UIColor(colorString: "CE6EFC")
    static let backgroundHightlightColor = UIColor(white: 216.0/255.0, alpha: 44.0/255.0)

    static let linkTextSize: CGFloat = 10.0
    static let labelTextSize: CGFloat = 14.0
    static let imageButtonTextSize: CGFloat = 14.0

    static let copyLinkButtonHeight: CGFloat = 44

    static let verticalWidgetMargin: CGFloat = 10
    static let horizontalWidgetMargin: CGFloat = 10
    static var defaultWidgetTextMargin: CGFloat = 22

    static let buttonSpacerMultipleOfScreen = 0.4
}

@objc (TodayViewController)
class TodayViewController: UIViewController, NCWidgetProviding {

    private lazy var newTabButton: ImageButtonWithLabel = {
        let imageButton = ImageButtonWithLabel()
        imageButton.addTarget(self, action: #selector(onPressNewTab), forControlEvents: .TouchUpInside)
        imageButton.labelText = NSLocalizedString("TodayWidget.NewTabButtonLabel", value: "New Tab", tableName: "Today", comment: "New Tab button label")

        let button = imageButton.button
        button.setImage(UIImage(named: "new_tab_button_normal"), forState: .Normal)
        button.setImage(UIImage(named: "new_tab_button_highlight"), forState: .Highlighted)

        let label = imageButton.label
        label.textColor = UIColor.whiteColor()
        label.font = UIFont.systemFontOfSize(TodayUX.imageButtonTextSize)

        imageButton.sizeToFit()
        return imageButton
    }()

    private lazy var newPrivateTabButton: ImageButtonWithLabel = {
        let imageButton = ImageButtonWithLabel()
        imageButton.addTarget(self, action: #selector(onPressNewPrivateTab), forControlEvents: .TouchUpInside)
        imageButton.labelText = NSLocalizedString("TodayWidget.NewPrivateTabButtonLabel", value: "New Private Tab", tableName: "Today", comment: "New Private Tab button label")

        let button = imageButton.button
        button.setImage(UIImage(named: "new_private_tab_button_normal"), forState: .Normal)
        button.setImage(UIImage(named: "new_private_tab_button_highlight"), forState: .Highlighted)

        let label = imageButton.label
        label.textColor = TodayUX.privateBrowsingColor
        label.font = UIFont.systemFontOfSize(TodayUX.imageButtonTextSize)

        return imageButton
    }()

    private lazy var openCopiedLinkButton: ButtonWithSublabel = {
        let button = ButtonWithSublabel()
        
        button.setTitle(NSLocalizedString("TodayWidget.GoToCopiedLinkLabel", value: "Go to copied link", tableName: "Today", comment: "Go to link on clipboard"), forState: .Normal)
        button.addTarget(self, action: #selector(onPressOpenClibpoard), forControlEvents: .TouchUpInside)

        // We need to set the background image/color for .Normal, so the whole button is tappable.
        button.setBackgroundColor(UIColor.clearColor(), forState: .Normal)
        button.setBackgroundColor(TodayUX.backgroundHightlightColor, forState: .Highlighted)

        button.setImage(UIImage(named: "copy_link_icon"), forState: .Normal)

        button.label.font = UIFont.systemFontOfSize(TodayUX.labelTextSize)
        button.subtitleLabel.font = UIFont.systemFontOfSize(TodayUX.linkTextSize)

        return button
    }()

    private lazy var buttonSpacer: UIView = UIView()
    private var heightConstraint: Constraint?

    private var copiedURL: NSURL? {
        if let string = UIPasteboard.generalPasteboard().string,
            url = NSURL(string: string) where url.isWebPage() {
            return url
        } else {
            return nil
        }
    }

    private var hasCopiedURL: Bool {
        return copiedURL != nil
    }

    private var scheme: String {
        guard let string = NSBundle.mainBundle().objectForInfoDictionaryKey("MozInternalURLScheme") as? String else {
            // Something went wrong/weird, but we should fallback to the public one.
            return "firefox"
        }
        return string
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(buttonSpacer)

        // New tab button and label.
        view.addSubview(newTabButton)
        newTabButton.snp_makeConstraints { make in
            make.top.equalTo(buttonSpacer)
            make.centerX.equalTo(buttonSpacer.snp_left)
        }

        // New private tab button and label.
        view.addSubview(newPrivateTabButton)
        newPrivateTabButton.snp_makeConstraints { make in
            make.centerY.equalTo(newTabButton.snp_centerY)
            make.centerX.equalTo(buttonSpacer.snp_right)
        }

        newTabButton.label.snp_makeConstraints { make in
            make.leading.greaterThanOrEqualTo(view)
        }

        newPrivateTabButton.label.snp_makeConstraints { make in
            make.trailing.lessThanOrEqualTo(view)
            make.left.greaterThanOrEqualTo(newTabButton.label.snp_right).priorityHigh()
        }

        buttonSpacer.snp_makeConstraints { make in
            make.width.equalTo(view.snp_width).multipliedBy(TodayUX.buttonSpacerMultipleOfScreen)
            make.centerX.equalTo(view.snp_centerX)
            make.top.equalTo(view.snp_top).offset(TodayUX.verticalWidgetMargin)
            make.bottom.equalTo(newPrivateTabButton.label.snp_bottom).priorityLow()
        }

        view.addSubview(openCopiedLinkButton)

        openCopiedLinkButton.snp_makeConstraints { make in
            make.top.equalTo(buttonSpacer.snp_bottom).offset(TodayUX.verticalWidgetMargin)
            make.width.equalTo(view.snp_width)
            make.centerX.equalTo(view.snp_centerX)
            make.height.equalTo(TodayUX.copyLinkButtonHeight)
        }

        view.snp_remakeConstraints { make in
            var extraHeight = TodayUX.verticalWidgetMargin
            if hasCopiedURL {
                extraHeight += TodayUX.copyLinkButtonHeight + TodayUX.verticalWidgetMargin
            }
        }
    }

    override func viewDidLayoutSubviews() {
        let preferredWidth: CGFloat = view.frame.size.width / CGFloat(buttonSpacer.subviews.count + 1)
        newPrivateTabButton.label.preferredMaxLayoutWidth = preferredWidth
        newTabButton.label.preferredMaxLayoutWidth = preferredWidth
    }

    func updateCopiedLink() {
        if let url = self.copiedURL {
            self.openCopiedLinkButton.hidden = false
            self.openCopiedLinkButton.subtitleLabel.hidden = SystemUtils.isDeviceLocked()
            self.openCopiedLinkButton.subtitleLabel.text = url.absoluteString
            self.openCopiedLinkButton.remakeConstraints()
        } else {
            self.openCopiedLinkButton.hidden = true
        }
    }

    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        TodayUX.defaultWidgetTextMargin = defaultMarginInsets.left
        return UIEdgeInsetsMake(0, 0, TodayUX.verticalWidgetMargin, 0)
    }

    // MARK: Button behaviour

    @objc func onPressNewTab(view: UIView) {
        openContainingApp()
    }

    @objc func onPressNewPrivateTab(view: UIView) {
        openContainingApp("?private=true")
    }

    private func openContainingApp(urlSuffix: String = "") {
        let urlString = "\(scheme)://\(urlSuffix)"
        self.extensionContext?.openURL(NSURL(string: urlString)!) { success in
            log.info("Extension opened containing app: \(success)")
        }
    }

    @objc func onPressOpenClibpoard(view: UIView) {
        if let urlString = UIPasteboard.generalPasteboard().string,
            _ = NSURL(string: urlString) {
            let encodedString =
                urlString.escape()
            openContainingApp("?url=\(encodedString)")
        }
    }
}

extension UIButton {
    func setBackgroundColor(color: UIColor, forState state: UIControlState) {
        let colorView = UIView(frame: CGRectMake(0, 0, 1, 1))
        colorView.backgroundColor = color

        UIGraphicsBeginImageContext(colorView.bounds.size)
        if let context = UIGraphicsGetCurrentContext() {
            colorView.layer.renderInContext(context)
        }
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        self.setBackgroundImage(colorImage, forState: state)
    }
}

class ImageButtonWithLabel: UIView {

    lazy var button = UIButton()

    lazy var label = UILabel()

    var labelText: String? {
        set {
            label.text = newValue
            label.sizeToFit()
        }
        get {
            return label.text
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: CGRectZero)
        performLayout()
    }

    func performLayout() {
        addSubview(button)
        addSubview(label)

        button.snp_makeConstraints { make in
            make.top.equalTo(self)
            make.left.equalTo(self)
            make.centerX.equalTo(self)
        }

        snp_makeConstraints { make in
            make.width.equalTo(button)
            make.height.equalTo(button)
        }

        label.numberOfLines = 0
        label.lineBreakMode = .ByWordWrapping
        label.textAlignment = .Center

        label.snp_makeConstraints { make in
            make.centerX.equalTo(button.snp_centerX)
            make.top.equalTo(button.snp_bottom).offset(TodayUX.verticalWidgetMargin / 2)
        }
    }

    func addTarget(target: AnyObject?, action: Selector, forControlEvents events: UIControlEvents) {
        button.addTarget(target, action: action, forControlEvents: events)
    }
}

class ButtonWithSublabel: UIButton {
    lazy var subtitleLabel: UILabel = UILabel()

    lazy var label: UILabel = UILabel()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init() {
        self.init(frame: CGRectZero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        performLayout()
    }

    private func performLayout() {
        self.snp_removeConstraints()

        let titleLabel = self.label
        titleLabel.textColor = UIColor.whiteColor()

        self.titleLabel?.removeFromSuperview()
        addSubview(titleLabel)

        let imageView = self.imageView!

        let subtitleLabel = self.subtitleLabel
        subtitleLabel.textColor = UIColor.whiteColor()
        self.addSubview(subtitleLabel)

        imageView.snp_remakeConstraints { make in
            make.centerY.equalTo(self.snp_centerY)
            make.right.equalTo(titleLabel.snp_left).offset(-TodayUX.horizontalWidgetMargin)
        }

        subtitleLabel.lineBreakMode = .ByTruncatingTail
        subtitleLabel.snp_makeConstraints { make in
            make.left.equalTo(titleLabel.snp_left)
            make.top.equalTo(titleLabel.snp_bottom).offset(TodayUX.verticalWidgetMargin / 2)
            make.right.lessThanOrEqualTo(self.snp_right).offset(-TodayUX.horizontalWidgetMargin)
        }

        remakeConstraints()
    }

    func remakeConstraints() {
        self.label.snp_remakeConstraints { make in
            make.top.equalTo(self.snp_top).offset(TodayUX.verticalWidgetMargin / 2)
            make.left.equalTo(self.snp_left).offset(TodayUX.defaultWidgetTextMargin).priorityHigh()
        }
    }

    override func setTitle(text: String?, forState state: UIControlState) {
        self.label.text = text
        super.setTitle(text, forState: state)
    }
}
