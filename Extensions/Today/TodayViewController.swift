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
class TodayViewController: UIViewController, NCWidgetProviding {

    let viewModel = TodayWidgetViewModel()
    let model = TodayModel()

    fileprivate lazy var newTabButton: ImageButtonWithLabel = {
        let imageButton = ImageButtonWithLabel()
        imageButton.addTarget(self, action: #selector(onPressNewTab), forControlEvents: .touchUpInside)
        imageButton.label.text = String.NewTabButtonLabel
        let button = imageButton.button
        button.setImage(UIImage(named: "search-button")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.accessibilityLabel = String.NewTabButtonLabel
        button.accessibilityTraits = .button
        let label = imageButton.label
        label.textColor = TodayUX.labelColor
        label.tintColor = TodayUX.labelColor
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(TodayUX.imageButtonTextSize))
        imageButton.sizeToFit()
        return imageButton
    }()

    fileprivate lazy var newPrivateTabButton: ImageButtonWithLabel = {
        let imageButton = ImageButtonWithLabel()
        imageButton.addTarget(self, action: #selector(onPressNewPrivateTab), forControlEvents: .touchUpInside)
        imageButton.label.text = String.NewPrivateTabButtonLabel
        let button = imageButton.button
        button.setImage(UIImage(named: "private-search")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.accessibilityLabel = String.NewPrivateTabButtonLabel
        button.accessibilityTraits = .button
        let label = imageButton.label
        label.textColor = TodayUX.labelColor
        label.tintColor = TodayUX.labelColor
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(TodayUX.imageButtonTextSize))
        imageButton.sizeToFit()
        return imageButton
    }()

    fileprivate lazy var openCopiedLinkButton: ImageButtonWithLabel = {
        let imageButton = ImageButtonWithLabel()
        imageButton.addTarget(self, action: #selector(onPressOpenCopiedLink), forControlEvents: .touchUpInside)
        imageButton.label.text = String.GoToCopiedLinkLabel
        let button = imageButton.button
        button.setImage(UIImage(named: "go-to-copied-link")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.accessibilityLabel = String.GoToCopiedLinkLabel
        button.accessibilityTraits = .button
        let label = imageButton.label
        label.textColor = TodayUX.labelColor
        label.tintColor = TodayUX.labelColor
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(TodayUX.imageButtonTextSize))
        imageButton.sizeToFit()
        return imageButton
    }()

    fileprivate lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = TodayUX.buttonStackViewSpacing
        stackView.distribution = UIStackView.Distribution.fillEqually
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        let widgetView: UIView!
        self.extensionContext?.widgetLargestAvailableDisplayMode = .compact

        let effectView: UIVisualEffectView

        if #available(iOS 13, *) {
            effectView = UIVisualEffectView(effect: UIVibrancyEffect.widgetEffect(forVibrancyStyle: .label))
        } else {
            effectView = UIVisualEffectView(effect: .none)
        }

        self.view.addSubview(effectView)
        effectView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        widgetView = effectView.contentView
        buttonStackView.addArrangedSubview(newTabButton)
        buttonStackView.addArrangedSubview(newPrivateTabButton)
        buttonStackView.addArrangedSubview(openCopiedLinkButton)
        widgetView.addSubview(buttonStackView)
        buttonStackView.snp.makeConstraints { make in
            make.edges.equalTo(widgetView)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let edge = size.width * TodayUX.buttonsHorizontalMarginPercentage
        buttonStackView.layoutMargins = UIEdgeInsets(top: 0, left: edge, bottom: 0, right: edge)
    }

    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return .zero
    }

    // MARK: Button behaviour
    @objc func onPressNewTab(_ view: UIView) {
        openContainingApp("?private=false",query: "url")
    }

    @objc func onPressNewPrivateTab(_ view: UIView) {
        openContainingApp("?private=true",query: "url")
    }

    //TODO: Move it to Viewmodel
    fileprivate func openContainingApp(_ urlSuffix: String = "", query : String) {
        let urlString = "\(model.scheme)://open-\(query)\(urlSuffix)"
        self.extensionContext?.open(URL(string: urlString)!) { success in
            log.info("Extension opened containing app: \(success)")
        }
    }

    @objc func onPressOpenCopiedLink(_ view: UIView) {
        viewModel.updateCopiedLink()
        if let url = TodayModel.copiedURL,
            let encodedString = url.absoluteString.escape() {
            openContainingApp("?url=\(encodedString)",query: "url")
        } else {
            guard let copiedText = TodayModel.searchedText else {
                return
            }
            openContainingApp("?text=\(copiedText)",query: "text")
        }
    }
}
