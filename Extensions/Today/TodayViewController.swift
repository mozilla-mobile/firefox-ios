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
    static let NewPrivateTabButtonLabel = NSLocalizedString("TodayWidget.NewPrivateTabButtonLabel", tableName: "Today", value: "Private Search", comment: "New Private Tab button label")
    static let NewTabButtonLabel = NSLocalizedString("TodayWidget.NewTabButtonLabel", tableName: "Today", value: "New Search", comment: "New Tab button label")
    static let GoToCopiedLinkLabel = NSLocalizedString("TodayWidget.GoToCopiedLinkLabel", tableName: "Today", value: "Go to copied link", comment: "Go to link on clipboard")
}

private struct TodayUX {
    static let privateBrowsingColor = UIColor(rgb: 0xcf68ff)
    static let backgroundHightlightColor = UIColor(white: 216.0/255.0, alpha: 44.0/255.0)
    static let linkTextSize: CGFloat = 10.0
    static let labelTextSize: CGFloat = 14.0
    static let imageButtonTextSize: CGFloat = 14.0
    static let copyLinkImageWidth: CGFloat = 23
    static let margin: CGFloat = 8
    static let buttonsHorizontalMarginPercentage: CGFloat = 0.1
    static let privateSearchButtonColorBrightPurple = UIColor(red: 117.0/255.0, green: 41.0/255.0, blue: 167.0/255.0, alpha: 1.0)
    static let privateSearchButtonColorDarkPurple = UIColor(red: 73.0/255.0, green: 46.0/255.0, blue: 133.0/255.0, alpha: 1.0)
    static let privateSearchButtonColorFaintDarkPurple = UIColor(red: 56.0/255.0, green: 51.0/255.0, blue: 114.0/255.0, alpha: 1.0)
}

@objc (TodayViewController)
class TodayViewController: UIViewController, NCWidgetProviding {

    var copiedURL: URL?

    fileprivate lazy var newTabButton: ImageButtonWithLabel = {
        let imageButton = ImageButtonWithLabel()
        imageButton.addTarget(self, action: #selector(onPressNewTab), forControlEvents: .touchUpInside)
        imageButton.label.text = TodayStrings.NewTabButtonLabel

        let button = imageButton.button
        button.frame = CGRect(width: 60.0, height: 60.0)
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = button.frame.size.width/2
        button.clipsToBounds = true
        button.setImage(UIImage(named: "search"), for: .normal)
        let label = imageButton.label
        label.tintColor = UIColor(named: "widgetLabelColors")
        label.textColor = UIColor(named: "widgetLabelColors")
        label.font = UIFont.systemFont(ofSize: TodayUX.imageButtonTextSize)

        imageButton.sizeToFit()
        return imageButton
    }()

    fileprivate lazy var newPrivateTabButton: ImageButtonWithLabel = {
        let imageButton = ImageButtonWithLabel()
        imageButton.addTarget(self, action: #selector(onPressNewPrivateTab), forControlEvents: .touchUpInside)
        imageButton.label.text = TodayStrings.NewPrivateTabButtonLabel
        let button = imageButton.button
        button.frame = CGRect(width: 60.0, height: 60.0)
        button.performGradient(colorOne: TodayUX.privateSearchButtonColorFaintDarkPurple, colorTwo: TodayUX.privateSearchButtonColorDarkPurple, colorThree: TodayUX.privateSearchButtonColorBrightPurple)
        button.layer.cornerRadius = button.frame.size.width/2
        button.clipsToBounds = true
        button.setImage(UIImage(named: "quick_action_new_private_tab")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.white

        let label = imageButton.label
        label.tintColor = UIColor(named: "widgetLabelColors")
        label.textColor = UIColor(named: "widgetLabelColors")
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
        return button
    }()

    fileprivate lazy var widgetStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = TodayUX.margin / 2
        stackView.distribution = UIStackView.Distribution.fill
        stackView.layoutMargins = UIEdgeInsets(top: TodayUX.margin, left: TodayUX.margin, bottom: TodayUX.margin, right: TodayUX.margin)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    fileprivate lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 30
        stackView.distribution = UIStackView.Distribution.fillEqually
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

        let widgetView: UIView!
        self.extensionContext?.widgetLargestAvailableDisplayMode = .compact
        let effectView: UIVisualEffectView
        if #available(iOS 13, *) {
            effectView = UIVisualEffectView(effect: UIVibrancyEffect.widgetEffect(forVibrancyStyle: .label))
        } else {
            effectView = UIVisualEffectView(effect: UIVibrancyEffect.widgetPrimary())
        }
        self.view.addSubview(effectView)
        effectView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        widgetView = effectView.contentView
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
        return .zero
    }

    func updateCopiedLink() {
        UIPasteboard.general.asyncURL().uponQueue(.main) { res in
            if let copiedURL: URL? = res.successValue,
                let url = copiedURL {
                self.openCopiedLinkButton.isHidden = false
                self.openCopiedLinkButton.subtitleLabel.isHidden = SystemUtils.isDeviceLocked()
                self.openCopiedLinkButton.subtitleLabel.text = url.absoluteDisplayString
                self.copiedURL = url
            } else {
                self.openCopiedLinkButton.isHidden = true
                self.copiedURL = nil
            }
        }
    }

    // MARK: Button behaviour
    @objc func onPressNewTab(_ view: UIView) {
        openContainingApp("?private=false")
    }

    @objc func onPressNewPrivateTab(_ view: UIView) {
        openContainingApp("?private=true")
    }

    fileprivate func openContainingApp(_ urlSuffix: String = "") {
        let urlString = "\(scheme)://open-url\(urlSuffix)"
        self.extensionContext?.open(URL(string: urlString)!) { success in
            log.info("Extension opened containing app: \(success)")
        }
    }

    @objc func onPressOpenClibpoard(_ view: UIView) {
        if let url = copiedURL,
            let encodedString = url.absoluteString.escape() {
            openContainingApp("?url=\(encodedString)")
        }
    }
}

extension UIButton {
    func setBackgroundColor(_ color: UIColor, forState state: UIControl.State) {
        let colorView = UIView(frame: CGRect(width: 1, height: 1))
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

extension UIButton {
    func performGradient(colorOne: UIColor, colorTwo: UIColor, colorThree: UIColor) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.frame
        gradientLayer.colors = [colorOne.cgColor, colorTwo.cgColor, colorThree.cgColor]
        gradientLayer.startPoint = CGPoint(x: 1.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.cornerRadius = self.frame.size.width/2
        layer.masksToBounds = true
        layer.insertSublayer(gradientLayer, below: self.imageView?.layer)
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
            make.centerX.equalTo(self)
            make.top.equalTo(self.safeAreaLayoutGuide)
            make.right.greaterThanOrEqualTo(self.safeAreaLayoutGuide).offset(30)
            make.left.greaterThanOrEqualTo(self.safeAreaLayoutGuide).inset(30)
            make.height.width.equalTo(60)
        }

        label.snp.makeConstraints { make in
            make.top.equalTo(button.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalTo(self)
        }

        label.numberOfLines = 1
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
    }

    func addTarget(_ target: AnyObject?, action: Selector, forControlEvents events: UIControl.Event) {
        button.addTarget(target, action: action, for: events)
    }
}

class ButtonWithSublabel: UIButton {
    lazy var subtitleLabel = UILabel()
    lazy var label = UILabel()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init() {
        self.init(frame: .zero)
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

    override func setTitle(_ text: String?, for state: UIControl.State) {
        self.label.text = text
        super.setTitle(text, for: state)
    }
}
