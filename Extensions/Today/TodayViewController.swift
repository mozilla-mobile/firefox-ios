/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import NotificationCenter
import Shared
import SnapKit

private let log = Logger.browserLogger

private let privateBrowsingColor = UIColor(colorString: "CE6EFC")

@objc (TodayViewController)
class TodayViewController: UIViewController, NCWidgetProviding {

    private lazy var newTabLabel: UILabel = {
        return self.createButtonLabel(NSLocalizedString("TodayWidget.NewTabButtonLabel", value: "New Tab", tableName: "Today", comment: "New Tab button label"))
    }()

    private lazy var newPrivateTabLabel: UILabel = {
        return self.createButtonLabel(NSLocalizedString("TodayWidget.NewPrivateTabButtonLabel", value: "New Private Tab", tableName: "Today", comment: "New Private Tab button label"), color: privateBrowsingColor)
    }()

    private lazy var newTabButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(onPressNewTab), forControlEvents: .TouchUpInside)
        button.setImage(UIImage(named: "new_tab_button_normal"), forState: .Normal)
        button.setImage(UIImage(named: "new_tab_button_highlight"), forState: .Highlighted)
        return button
    }()

    private lazy var newPrivateTabButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(onPressNewPrivateTab), forControlEvents: .TouchUpInside)
        button.setImage(UIImage(named: "new_private_tab_button_normal"), forState: .Normal)
        button.setImage(UIImage(named: "new_private_tab_button_highlight"), forState: .Highlighted)
        return button
    }()

    private lazy var openURLFromClipboardView: UIView = {
        let view = UIView()
        let button = UIButton()
        button.setTitle(NSLocalizedString("TodayWidget.GoToCopiedLinkLabel", value: "Go to copied link", tableName: "Today", comment: "Go to link on clipboard"), forState: .Normal)
        button.addTarget(self, action: #selector(onPressOpenClibpoard), forControlEvents: .TouchUpInside)

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let buttonContainer = UIView()
        view.addSubview(buttonContainer)

//        view.backgroundColor = UIColor.blueColor()
//        buttonContainer.backgroundColor = UIColor.redColor()

        buttonContainer.snp_makeConstraints { make in
            make.width.equalTo(view.snp_width).multipliedBy(0.8)
            make.centerX.equalTo(view.snp_centerX)
        }

        // New tab button and label.
        buttonContainer.addSubview(newTabButton)
        newTabButton.snp_makeConstraints { make in
            make.topMargin.equalTo(10)
            make.leading.equalTo(buttonContainer.snp_leading).offset(44)
            make.height.width.equalTo(44)
        }

        buttonContainer.addSubview(newTabLabel)
        alignButton(newTabButton, withLabel: newTabLabel)

        // New tab button and label.
        buttonContainer.addSubview(newPrivateTabButton)
        newPrivateTabButton.snp_makeConstraints { make in
            make.centerY.equalTo(newTabButton.snp_centerY)
            make.size.equalTo(newTabButton.snp_size)
            make.trailing.equalTo(buttonContainer.snp_trailing).offset(-44)
        }

        buttonContainer.addSubview(newPrivateTabLabel)
        alignButton(newPrivateTabButton, withLabel: newPrivateTabLabel, leftOf: newTabLabel)

        buttonContainer.snp_makeConstraints { make in
            make.height.equalTo(newTabButton.snp_height).multipliedBy(2.0)
        }

        view.snp_makeConstraints { make in
            make.height.equalTo(buttonContainer.snp_height).priorityLow()
        }
        view.systemLayoutSizeFittingSize(CGSizeZero)

        updateOpenClipboardButton()
    }

    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, 0, 0)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    private func alignButton(button: UIButton, withLabel label: UILabel, leftOf leftLabel: UILabel? = nil) {
        label.snp_makeConstraints { make in
            make.centerX.equalTo(button.snp_centerX)
            make.centerY.equalTo(button.snp_centerY).offset(39)
            if let leftLabel = leftLabel {
                make.centerX.equalTo(leftLabel.snp_centerX).offset(44).priorityLow()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        updateOpenClipboardButton()

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }

    // MARK: Button and label creation

    private func createButtonLabel(text: String, color: UIColor = UIColor.whiteColor()) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = color
        label.font = UIFont.systemFontOfSize(14.0)
        return label
    }

    // MARK: Button behaviour

    @objc func onPressNewTab(view: UIView) {
        openContainingApp("firefox://")
    }

    @objc func onPressNewPrivateTab(view: UIView) {
        openContainingApp("firefox://?private=true")
    }

    private func openContainingApp(urlString: String) {
        self.extensionContext?.openURL(NSURL(string: urlString)!) { success in
            log.info("Extension opened containing app: \(success)")
        }
    }

    @objc func onPressOpenClibpoard(view: UIView) {
        if let urlString = UIPasteboard.generalPasteboard().string,
            _ = NSURL(string: urlString) {
            openContainingApp(urlString)
        }
    }

    func updateOpenClipboardButton() {
        log.info("Checking clipboard")
        if let string = UIPasteboard.generalPasteboard().string,
            _ = NSURL(string: string) {
                log.info("We have a URL!")
                openURLFromClipboardView.hidden = false
        } else {
            openURLFromClipboardView.hidden = true
        }

    }
}
