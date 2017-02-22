/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import NotificationCenter
import Shared
import SnapKit
import XCGLogger

private let log = Logger.browserLogger

struct TodayStrings {
    static let NewPrivateTabButtonLabel = NSLocalizedString("TodayWidget.NewPrivateTabButtonLabel", tableName: "Today", value: "New Private Tab", comment: "New Private Tab button label")
    static let NewTabButtonLabel = NSLocalizedString("TodayWidget.NewTabButtonLabel", tableName: "Today", value: "New Tab", comment: "New Tab button label")
    static let GoToCopiedLinkLabel = NSLocalizedString("TodayWidget.GoToCopiedLinkLabel", tableName: "Today", value: "Go to copied link", comment: "Go to link on clipboard")
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
    static let iOS9LeftMargin: CGFloat = 40
}

@objc (TodayViewController)
class TodayViewController: UIViewController, NCWidgetProviding {

    fileprivate lazy var newTabButton: ImageButtonWithLabel = {
        let imageButton = ImageButtonWithLabel()
        imageButton.addTarget(self, action: #selector(onPressNewTab), forControlEvents: .touchUpInside)
        imageButton.label.text = TodayStrings.NewTabButtonLabel

        let button = imageButton.button

        button.setImage(UIImage(named: "new_tab_button_normal")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(UIImage(named: "new_tab_button_highlight")?.withRenderingMode(.alwaysTemplate), for: .highlighted)

        let label = imageButton.label
        label.font = UIFont.systemFont(ofSize: TodayUX.imageButtonTextSize)

        imageButton.sizeToFit()
        return imageButton
    }()

    fileprivate lazy var newPrivateTabButton: ImageButtonWithLabel = {
        let imageButton = ImageButtonWithLabel()
        imageButton.addTarget(self, action: #selector(onPressNewPrivateTab), forControlEvents: .touchUpInside)
        imageButton.label.text = TodayStrings.NewPrivateTabButtonLabel

        let button = imageButton.button
        button.setImage(UIImage(named: "new_private_tab_button_normal"), for: .normal)
        button.setImage(UIImage(named: "new_private_tab_button_highlight"), for: .highlighted)

        let label = imageButton.label
        label.tintColor = TodayUX.privateBrowsingColor
        label.textColor = TodayUX.privateBrowsingColor
        label.font = UIFont.systemFont(ofSize: TodayUX.imageButtonTextSize)
        imageButton.sizeToFit()
        return imageButton
    }()

    fileprivate lazy var openCopiedLinkButton: ButtonWithSublabel = {
        let button = ButtonWithSublabel()
        
        button.setTitle(TodayStrings.GoToCopiedLinkLabel, for: .normal)
        button.addTarget(self, action: #selector(onPressOpenClibpoard), for: .touchUpInside)

        // We need to set the background image/color for .Normal, so the whole button is tappable.
        button.setBackgroundColor(UIColor.clear, forState: .normal)
        button.setBackgroundColor(TodayUX.backgroundHightlightColor, forState: .highlighted)

        button.setImage(UIImage(named: "copy_link_icon")?.withRenderingMode(.alwaysTemplate), for: .normal)

        button.label.font = UIFont.systemFont(ofSize: TodayUX.labelTextSize)
        button.subtitleLabel.font = UIFont.systemFont(ofSize: TodayUX.linkTextSize)
        if #available(iOS 10, *) {
            // no custom margin needed
        } else {
            button.imageView?.snp.updateConstraints { make in
                make.left.equalTo(button.snp.left).offset(TodayUX.iOS9LeftMargin)
            }
        }
        return button
    }()

    fileprivate lazy var widgetStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = TodayUX.margin / 2
        stackView.distribution = UIStackViewDistribution.fill
        stackView.layoutMargins = UIEdgeInsets(top: TodayUX.margin, left: TodayUX.margin, bottom: TodayUX.margin, right: TodayUX.margin)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    fileprivate lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.distribution = UIStackViewDistribution.fillEqually
        let edge = self.view.frame.size.width * TodayUX.buttonsHorizontalMarginPercentage
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: edge, bottom: 0, right: edge)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    fileprivate var scheme: String {
        guard let string = Bundle.main.object(forInfoDictionaryKey: "MozInternalURLScheme") as? String else {
            // Something went wrong/weird, but we should fallback to the public one.
            return "firefox"
        }
        return string
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // on iOS10 widgetView will be a UIVisualEffectView and on ios9 it will just be the main self.view
        let widgetView: UIView!
        if #available(iOSApplicationExtension 10.0, *) {
            self.extensionContext?.widgetLargestAvailableDisplayMode = .compact
            let effectView = UIVisualEffectView(effect: UIVibrancyEffect.widgetPrimary())
            self.view.addSubview(effectView)
            effectView.snp.makeConstraints { make in
                make.edges.equalTo(self.view)
            }
            widgetView = effectView.contentView
        } else {
            widgetView = self.view
            self.view.tintColor = UIColor.white
            openCopiedLinkButton.label.textColor = UIColor.white
        }

        buttonStackView.addArrangedSubview(newTabButton)
        buttonStackView.addArrangedSubview(newPrivateTabButton)

        widgetStackView.addArrangedSubview(buttonStackView)
        widgetStackView.addArrangedSubview(openCopiedLinkButton)

        widgetView.addSubview(widgetStackView)
        widgetStackView.snp.makeConstraints { make in
            make.edges.equalTo(widgetView)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCopiedLink()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let edge = size.width * TodayUX.buttonsHorizontalMarginPercentage
        buttonStackView.layoutMargins = UIEdgeInsets(top: 0, left: edge, bottom: 0, right: edge)
    }

    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }

    func updateCopiedLink() {
        if let url = UIPasteboard.general.copiedURL {
            self.openCopiedLinkButton.isHidden = false
            self.openCopiedLinkButton.subtitleLabel.isHidden = SystemUtils.isDeviceLocked()
            self.openCopiedLinkButton.subtitleLabel.text = url.absoluteString
        } else {
            self.openCopiedLinkButton.isHidden = true
        }
    }

    // MARK: Button behaviour
    @objc func onPressNewTab(_ view: UIView) {
        openContainingApp()
    }

    @objc func onPressNewPrivateTab(_ view: UIView) {
        openContainingApp("?private=true")
    }

    fileprivate func openContainingApp(_ urlSuffix: String = "") {
        let urlString = "\(scheme)://\(urlSuffix)"
        self.extensionContext?.open(URL(string: urlString)!) { success in
            log.info("Extension opened containing app: \(success)")
        }
    }

    @objc func onPressOpenClibpoard(_ view: UIView) {
        if let urlString = UIPasteboard.general.string,
            let _ = URL(string: urlString) {
            let encodedString =
                urlString.escape()
            openContainingApp("?url=\(encodedString)")
        }
    }
}

extension UIButton {
    func setBackgroundColor(_ color: UIColor, forState state: UIControlState) {
        let colorView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        colorView.backgroundColor = color

        UIGraphicsBeginImageContext(colorView.bounds.size)
        if let context = UIGraphicsGetCurrentContext() {
            colorView.layer.render(in: context)
        }
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        self.setBackgroundImage(colorImage, for: state)
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

        button.snp.makeConstraints { make in
            make.top.left.centerX.equalTo(self)
        }

        label.snp.makeConstraints { make in
            make.top.equalTo(button.snp.bottom)
            make.leading.trailing.bottom.equalTo(self)
        }

        label.numberOfLines = 1
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        label.textColor = UIColor.white
    }

    func addTarget(_ target: AnyObject?, action: Selector, forControlEvents events: UIControlEvents) {
        button.addTarget(target, action: action, for: events)
    }
}

class ButtonWithSublabel: UIButton {
    lazy var subtitleLabel: UILabel = UILabel()
    lazy var label: UILabel = UILabel()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        performLayout()
    }

    fileprivate func performLayout() {
        let titleLabel = self.label

        self.titleLabel?.removeFromSuperview()
        addSubview(titleLabel)

        let imageView = self.imageView!
        let subtitleLabel = self.subtitleLabel
        subtitleLabel.textColor = UIColor.lightGray
        self.addSubview(subtitleLabel)

        imageView.snp.makeConstraints { make in
            make.centerY.left.equalTo(self)
            make.width.equalTo(TodayUX.copyLinkImageWidth)
        }

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(imageView.snp.right).offset(TodayUX.margin)
            make.trailing.top.equalTo(self)
        }

        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(self)
            make.top.equalTo(titleLabel.snp.bottom)
            make.leading.trailing.equalTo(titleLabel)
        }
    }

    override func setTitle(_ text: String?, for state: UIControlState) {
        self.label.text = text
        super.setTitle(text, for: state)
    }
}
