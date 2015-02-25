/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Snap
import UIKit

private let BackgroundColor = UIColor(red: 45.0 / 255, green: 52.0 / 255, blue: 66.0 / 255, alpha: 1)
private let NormalIconColor = UIColor.lightGrayColor()
private let SelectedIconColor = UIColor(red: 62.0 / 255, green: 136.0 / 255, blue: 255.0 / 255, alpha: 1)
private let ContainerHeight = 40

protocol HomePanelViewControllerDelegate: class {
    func homePanelViewController(homePanelViewController: HomePanelViewController, didSelectURL url: NSURL)
}

@objc
protocol HomePanel: class {
    weak var homePanelDelegate: HomePanelDelegate? { get set }
}

@objc
protocol HomePanelDelegate: class {
    func homePanel(homePanel: HomePanel, didSelectURL url: NSURL)
}

class HomePanelViewController: UIViewController, UITextFieldDelegate, HomePanelDelegate {
    var profile: Profile!
    var notificationToken: NSObjectProtocol!
    var panels: [ToolbarItem]!
    var url: NSURL?
    weak var delegate: HomePanelViewControllerDelegate?

    private var buttonContainerView: UIView!
    private var controllerContainerView: UIView!
    private var buttons: [UIButton] = []

    override func viewDidLoad() {
        view.backgroundColor = BackgroundColor

        buttonContainerView = UIView()
        buttonContainerView.backgroundColor = BackgroundColor
        view.addSubview(buttonContainerView)

        controllerContainerView = UIView()
        view.addSubview(controllerContainerView)

        buttonContainerView.snp_makeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(ContainerHeight)
        }

        controllerContainerView.snp_makeConstraints { make in
            make.top.equalTo(self.buttonContainerView.snp_bottom)
            make.left.right.bottom.equalTo(self.view)
        }

        self.panels = Panels(profile: self.profile).enabledItems
        updateButtons()
        selectedButtonIndex = 0
    }

    override func viewWillAppear(animated: Bool) {
        notificationToken = NSNotificationCenter.defaultCenter().addObserverForName(PanelsNotificationName, object: nil, queue: nil) { [unowned self] notif in
            self.panels = Panels(profile: self.profile).enabledItems
            self.updateButtons()
        }
    }

    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(notificationToken)
    }

    var selectedButtonIndex: Int = 0 {
        didSet {
            let currentButton = buttons[oldValue]
            currentButton.selected = false

            let newButton = buttons[selectedButtonIndex]
            newButton.selected = true

            hideCurrentPanel()
            var panel = self.panels[selectedButtonIndex].generator(profile: self.profile)
            self.showPanel(panel)

            // TODO: Temporary workaround until all panels implement the HomePanel protocol.
            if let v = panel as? HomePanel {
                v.homePanelDelegate = self
            }
        }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    private func hideCurrentPanel() {
        if let panel = childViewControllers.first? as? UIViewController {
            panel.view.removeFromSuperview()
            panel.removeFromParentViewController()
        }
    }

    private func showPanel(panel: UIViewController) {
        controllerContainerView.addSubview(panel.view)
        panel.view.snp_makeConstraints { make in
            make.top.equalTo(self.buttonContainerView.snp_bottom)
            make.left.right.bottom.equalTo(self.view)
        }

        addChildViewController(panel)
    }

    func SELtappedButton(sender: UIButton!) {
        for (index, button) in enumerate(buttons) {
            if (button == sender) {
                selectedButtonIndex = index
                break
            }
        }
    }

    private func updateButtons() {
        // Remove any existing buttons if we're rebuilding the toolbar.
        for button in buttons {
            button.removeFromSuperview()
        }
        buttons.removeAll()

        var prev: UIView? = nil
        for panel in panels {
            let button = UIButton()
            buttonContainerView.addSubview(button)
            button.addTarget(self, action: "SELtappedButton:", forControlEvents: UIControlEvents.TouchUpInside)
            let image = UIImage(named: "nav-\(panel.imageName).png")!
            button.setImage(getOverlayedImage(image, withColor: NormalIconColor), forState: UIControlState.Normal)
            button.setImage(getOverlayedImage(image, withColor: SelectedIconColor), forState: UIControlState.Selected)
            buttons.append(button)

            button.snp_remakeConstraints { make in
                let left = prev?.snp_right ?? self.view.snp_left
                make.left.equalTo(left)
                make.height.centerY.equalTo(self.buttonContainerView)
                make.width.equalTo(self.buttonContainerView).dividedBy(self.panels.count)
            }

            prev = button
        }
    }

    private func getOverlayedImage(image: UIImage, withColor color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        let context = UIGraphicsGetCurrentContext()
        color.setFill()
        CGContextTranslateCTM(context, 0, image.size.height)
        CGContextScaleCTM(context, 1.0, -1.0)
        CGContextClipToMask(context, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage)
        CGContextFillRect(context, CGRectMake(0, 0, image.size.width, image.size.height))
        let overlayedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return overlayedImage
    }

    func homePanel(homePanel: HomePanel, didSelectURL url: NSURL) {
        delegate?.homePanelViewController(self, didSelectURL: url)
        dismissViewControllerAnimated(true, completion: nil)
    }
}
