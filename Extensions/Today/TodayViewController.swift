// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

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

    fileprivate func setupButtons(buttonLabel: String, buttonImageName: String) -> ImageButtonWithLabel {
        let imageButton = ImageButtonWithLabel()
        imageButton.label.text = buttonLabel
        let button = imageButton.button
        button.setImage(UIImage(named: buttonImageName)?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.accessibilityLabel = buttonLabel
        button.accessibilityTraits = .button
        let label = imageButton.label
        label.textColor = TodayUX.labelColor
        label.tintColor = TodayUX.labelColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        return imageButton
    }

    fileprivate lazy var newTabButton: ImageButtonWithLabel = {
        let button = setupButtons(buttonLabel: String.NewTabButtonLabel, buttonImageName: "search-button")
        button.addTarget(self, action: #selector(onPressNewTab), forControlEvents: .touchUpInside)
        return button
    }()

    fileprivate lazy var newPrivateTabButton: ImageButtonWithLabel = {
        let button = setupButtons(buttonLabel: String.NewPrivateTabButtonLabel, buttonImageName: "private-search")
        button.addTarget(self, action: #selector(onPressNewPrivateTab), forControlEvents: .touchUpInside)
        return button
    }()

    fileprivate lazy var openCopiedLinkButton: ImageButtonWithLabel = {
        let button = setupButtons(buttonLabel: String.GoToCopiedLinkLabelV2, buttonImageName: "go-to-copied-link")
        button.addTarget(self, action: #selector(onPressOpenCopiedLink), forControlEvents: .touchUpInside)
        return button
    }()

    // MARK: Feature for V29
    // Close Private tab button in today widget, when clicked, it clears all private browsing tabs from the widget. delayed untill next release V29
    fileprivate lazy var closePrivateTabsButton: ImageButtonWithLabel = {
        let button = setupButtons(buttonLabel: String.ClosePrivateTabsLabelV2, buttonImageName: "close-private-tabs")
        button.addTarget(self, action: #selector(onPressClosePrivateTabs), forControlEvents: .touchUpInside)
        return button
    }()

    fileprivate lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.spacing = TodayUX.buttonStackViewSpacing
        stackView.distribution = UIStackView.Distribution.fillEqually
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        let widgetView: UIView!
        self.extensionContext?.widgetLargestAvailableDisplayMode = .compact
        viewModel.setViewDelegate(todayViewDelegate: self)
        NotificationCenter.default.addObserver(self, selector: #selector(preferredContentSizeChanged(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)

        let effectView = UIVisualEffectView(effect: UIVibrancyEffect.widgetEffect(forVibrancyStyle: .label))

        self.view.addSubview(effectView)
        effectView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        widgetView = effectView.contentView
        buttonStackView.addArrangedSubview(newTabButton)
        buttonStackView.addArrangedSubview(newPrivateTabButton)
        buttonStackView.addArrangedSubview(closePrivateTabsButton)
        widgetView.addSubview(buttonStackView)
        buttonStackView.snp.makeConstraints { make in
            make.top.equalTo(widgetView)
            make.left.equalTo(widgetView).offset(5)
            make.right.equalTo(widgetView).offset(-5)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UIPasteboard.general.hasStrings {
            buttonStackView.addArrangedSubview(openCopiedLinkButton)
        } else {
            buttonStackView.removeArrangedSubview(openCopiedLinkButton)
        }
        adjustFonts()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let edge = size.width * TodayUX.buttonsHorizontalMarginPercentage
        buttonStackView.layoutMargins = UIEdgeInsets(top: 0, left: edge, bottom: 0, right: edge)
    }

    @objc func preferredContentSizeChanged(_ notification: Notification) {
        adjustFonts()
    }

    func adjustFonts() {
        let size = traitCollection.preferredContentSizeCategory
        switch size {
        case let size where size >= .accessibilityMedium:
            resize(size: 25)
        case let size where size <= .extraExtraExtraLarge && size > .extraLarge:
            resize(size: 15)
        case let size where size >= .large && size <= .extraLarge:
            resize(size: 14)
        case let size where size == .medium:
            resize(size: 12)
        case let size where size >= .extraSmall && size <= .small:
            resize(size: 8)
        default:
            resize(size: UIFont.systemFontSize)
        }
    }

    func resize(size: CGFloat) {
        newTabButton.label.font = newTabButton.label.font.withSize(size)
        newPrivateTabButton.label.font = newPrivateTabButton.label.font.withSize(size)
        openCopiedLinkButton.label.font = openCopiedLinkButton.label.font.withSize(size)
        closePrivateTabsButton.label.font = closePrivateTabsButton.label.font.withSize(size)
    }

    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return .zero
    }

    // MARK: Button behaviour
    @objc func onPressNewTab(_ view: UIView) {
        openContainingApp("?private=false", query: "open-url")
    }

    @objc func onPressNewPrivateTab(_ view: UIView) {
        openContainingApp("?private=true", query: "open-url")
    }

    @objc func onPressOpenCopiedLink(_ view: UIView) {
        viewModel.updateCopiedLink()
    }

    @objc func onPressClosePrivateTabs() {
        openContainingApp(query: "close-private-tabs")
    }

    func openContainingApp(_ urlSuffix: String = "", query: String) {
        let urlString = "\(model.scheme)://\(query)\(urlSuffix)"
        self.extensionContext?.open(URL(string: urlString)!) { success in
            log.info("Extension opened containing app: \(success)")
        }
    }
}
