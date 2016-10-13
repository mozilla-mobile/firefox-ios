/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import NotificationCenter
import Shared
import SnapKit

private let log = Logger.browserLogger

struct TodayStrings {
    static let NewPrivateTabButtonLabel = NSLocalizedString("TodayWidget.NewPrivateTabButtonLabel", value: "New Private Tab", tableName: "Today", comment: "New Private Tab button label")
    static let NewTabButtonLabel = NSLocalizedString("TodayWidget.NewTabButtonLabel", value: "New Tab", tableName: "Today", comment: "New Tab button label")
    static let GoToCopiedLinkLabel = NSLocalizedString("TodayWidget.GoToCopiedLinkLabel", value: "Go to copied link", tableName: "Today", comment: "Go to link on clipboard")
}

struct TodayUX {
    static let privateBrowsingColor = UIColor(colorString: "CE6EFC")
    static let backgroundHightlightColor = UIColor(white: 216.0/255.0, alpha: 44.0/255.0)
    static let linkTextSize: CGFloat = 10.0
    static let labelTextSize: CGFloat = 14.0
    static let imageButtonTextSize: CGFloat = 14.0
    static let copyLinkImageWidth: CGFloat = 23
    static let margin: CGFloat = 8
    static let buttonsHorizontalMarginPercentage: CGFloat = 0.1
}

@objc (TodayViewController)
class TodayViewController: UIViewController, NCWidgetProviding {

    private lazy var newTabButton: ImageButtonWithLabel = {
        let imageButton = ImageButtonWithLabel()
        imageButton.addTarget(self, action: #selector(onPressNewTab), forControlEvents: .TouchUpInside)
        imageButton.label.text = TodayStrings.NewTabButtonLabel

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
        imageButton.label.text = TodayStrings.NewPrivateTabButtonLabel

        let button = imageButton.button
        button.setImage(UIImage(named: "new_private_tab_button_normal"), forState: .Normal)
        button.setImage(UIImage(named: "new_private_tab_button_highlight"), forState: .Highlighted)

        let label = imageButton.label
        label.textColor = TodayUX.privateBrowsingColor
        label.font = UIFont.systemFontOfSize(TodayUX.imageButtonTextSize)
        imageButton.sizeToFit()
        return imageButton
    }()

    private lazy var openCopiedLinkButton: ButtonWithSublabel = {
        let button = ButtonWithSublabel()
        
        button.setTitle(TodayStrings.GoToCopiedLinkLabel, forState: .Normal)
        button.addTarget(self, action: #selector(onPressOpenClibpoard), forControlEvents: .TouchUpInside)

        // We need to set the background image/color for .Normal, so the whole button is tappable.
        button.setBackgroundColor(UIColor.clearColor(), forState: .Normal)
        button.setBackgroundColor(TodayUX.backgroundHightlightColor, forState: .Highlighted)

        button.setImage(UIImage(named: "copy_link_icon"), forState: .Normal)

        button.label.font = UIFont.systemFontOfSize(TodayUX.labelTextSize)
        button.subtitleLabel.font = UIFont.systemFontOfSize(TodayUX.linkTextSize)

        return button
    }()

    private lazy var widgetStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .Vertical
        stackView.alignment = .Fill
        stackView.spacing = 0
        stackView.distribution = UIStackViewDistribution.Fill
        stackView.layoutMargins = UIEdgeInsets(top: TodayUX.margin, left: TodayUX.margin, bottom: TodayUX.margin, right: TodayUX.margin)
        stackView.layoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .Horizontal
        stackView.alignment = .Fill
        stackView.spacing = 0
        stackView.distribution = UIStackViewDistribution.FillEqually
        let edge = self.view.frame.size.width * TodayUX.buttonsHorizontalMarginPercentage
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: edge, bottom: 0, right: edge)
        stackView.layoutMarginsRelativeArrangement = true
        return stackView
    }()

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

        buttonStackView.addArrangedSubview(newTabButton)
        buttonStackView.addArrangedSubview(newPrivateTabButton)

        widgetStackView.addArrangedSubview(buttonStackView)
        widgetStackView.addArrangedSubview(openCopiedLinkButton)

        view.addSubview(widgetStackView)

        widgetStackView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateCopiedLink()
    }


    func updateCopiedLink() {
        if let url = self.copiedURL {
            self.openCopiedLinkButton.hidden = false
            self.openCopiedLinkButton.subtitleLabel.hidden = SystemUtils.isDeviceLocked()
            self.openCopiedLinkButton.subtitleLabel.text = url.absoluteString
        } else {
            self.openCopiedLinkButton.hidden = true
        }
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        performLayout()
    }

    func performLayout() {
        addSubview(button)
        addSubview(label)

        button.snp_makeConstraints { make in
            make.top.left.centerX.equalTo(self)
        }

        label.snp_makeConstraints { make in
            make.top.equalTo(button.snp_bottom)
            make.leading.trailing.bottom.equalTo(self)
        }

        label.numberOfLines = 1
        label.lineBreakMode = .ByWordWrapping
        label.textAlignment = .Center
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
        let titleLabel = self.label
        titleLabel.textColor = UIColor.whiteColor()

        self.titleLabel?.removeFromSuperview()
        addSubview(titleLabel)

        let imageView = self.imageView!
        let subtitleLabel = self.subtitleLabel
        subtitleLabel.textColor = UIColor.lightGrayColor()
        self.addSubview(subtitleLabel)

        imageView.snp_makeConstraints { make in
            make.centerY.left.equalTo(self)
            make.width.equalTo(TodayUX.copyLinkImageWidth)
        }

        titleLabel.snp_makeConstraints { make in
            make.left.equalTo(imageView.snp_right).offset(TodayUX.margin)
            make.trailing.top.equalTo(self)
        }

        subtitleLabel.lineBreakMode = .ByTruncatingTail
        subtitleLabel.snp_makeConstraints { make in
            make.bottom.equalTo(self)
            make.top.equalTo(titleLabel.snp_bottom)
            make.leading.trailing.equalTo(titleLabel)
        }
    }

    override func setTitle(text: String?, forState state: UIControlState) {
        self.label.text = text
        super.setTitle(text, forState: state)
    }
}
