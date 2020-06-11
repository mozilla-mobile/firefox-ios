/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import NotificationCenter
import Shared
import SnapKit
import XCGLogger

private let log = Logger.browserLogger

@objc (TodayViewController)
class TodayViewController: UIViewController, NCWidgetProviding, TodayWidgetAppearanceDelegate {

    let viewModel = TodayWidgetViewModel()
    let model = TodayModel()

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

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.setViewDelegate(todayViewDelegate: self)
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
        viewModel.updateCopiedLink()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let edge = size.width * TodayUX.buttonsHorizontalMarginPercentage
        buttonStackView.layoutMargins = UIEdgeInsets(top: 0, left: edge, bottom: 0, right: edge)
    }

    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return .zero
    }

    func updateCopiedLinkInView(clipboardURL: URL?) {
        if let url = clipboardURL{
            self.openCopiedLinkButton.isHidden = false
            self.openCopiedLinkButton.subtitleLabel.isHidden = SystemUtils.isDeviceLocked()
            self.openCopiedLinkButton.subtitleLabel.text = url.absoluteDisplayString
        } else{
            self.openCopiedLinkButton.isHidden = true
            self.openCopiedLinkButton.subtitleLabel.isHidden = SystemUtils.isDeviceLocked()
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
        let urlString = "\(model.scheme)://open-url\(urlSuffix)"
        self.extensionContext?.open(URL(string: urlString)!) { success in
            log.info("Extension opened containing app: \(success)")
        }
    }

    @objc func onPressOpenClibpoard(_ view: UIView) {
        if let url = TodayModel.copiedURL,
            let encodedString = url.absoluteString.escape() {
            openContainingApp("?url=\(encodedString)")
        }
    }
}
