/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import UIKit

private struct HomePanelViewControllerUX {
    // Height of the top panel switcher button toolbar.
    static let ButtonContainerHeight: CGFloat = 40
    static let ButtonContainerBorderColor = UIColor.blackColor().colorWithAlphaComponent(0.1)
    static let BackgroundColor = AppConstants.PanelBackgroundColor
}

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
    var panels: [HomePanelDescriptor]!
    var url: NSURL?
    weak var delegate: HomePanelViewControllerDelegate?

    private var buttonContainerView: UIView!
    private var buttonContainerBottomBorderView: UIView!
    private var controllerContainerView: UIView!
    private var buttons: [UIButton] = []

    override func viewDidLoad() {
        view.backgroundColor = HomePanelViewControllerUX.BackgroundColor

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light))
        view.addSubview(blur)

        buttonContainerView = UIView()
        buttonContainerView.backgroundColor = HomePanelViewControllerUX.BackgroundColor
        view.addSubview(buttonContainerView)

        self.buttonContainerBottomBorderView = UIView()
        buttonContainerView.addSubview(buttonContainerBottomBorderView)
        buttonContainerBottomBorderView.backgroundColor = HomePanelViewControllerUX.ButtonContainerBorderColor

        controllerContainerView = UIView()
        view.addSubview(controllerContainerView)

        blur.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        buttonContainerView.snp_makeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(HomePanelViewControllerUX.ButtonContainerHeight)
        }

        buttonContainerBottomBorderView.snp_makeConstraints { make in
            make.top.equalTo(self.buttonContainerView.snp_bottom).offset(-1)
            make.left.right.bottom.equalTo(self.buttonContainerView)
        }

        controllerContainerView.snp_makeConstraints { make in
            make.top.equalTo(self.buttonContainerView.snp_bottom)
            make.left.right.bottom.equalTo(self.view)
        }

        self.panels = HomePanels().enabledPanels
        updateButtons()
        selectedButtonIndex = 0

        // Gesture recognizer to dismiss the keyboard in the URLBarView when the buttonContainerView is tapped
        let dismissKeyboardGestureRecognizer = UITapGestureRecognizer(target: self, action: "SELhandleDismissKeyboardGestureRecognizer:")
        dismissKeyboardGestureRecognizer.cancelsTouchesInView = false
        buttonContainerView.addGestureRecognizer(dismissKeyboardGestureRecognizer)
    }

    func SELhandleDismissKeyboardGestureRecognizer(gestureRecognizer: UITapGestureRecognizer) {
        view.window?.rootViewController?.view.endEditing(true)
    }

    var selectedButtonIndex: Int? = nil {
        didSet {
            if oldValue == selectedButtonIndex {
                // Prevent flicker, allocations, and disk access: avoid duplicate view controllers.
                return
            }

            if let index = oldValue {
                let currentButton = buttons[index]
                currentButton.selected = false
            }

            hideCurrentPanel()

            if let index = selectedButtonIndex {
                let newButton = buttons[index]
                newButton.selected = true

                let panel = self.panels[index].makeViewController(profile: profile)
                (panel as! HomePanel).homePanelDelegate = self
                self.showPanel(panel)
            }
        }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    private func hideCurrentPanel() {
        if let panel = childViewControllers.first as? UIViewController {
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
            if let image = UIImage(named: "panelIcon\(panel.imageName)") {
                button.setImage(image, forState: UIControlState.Normal)
            }
            if let image = UIImage(named: "panelIcon\(panel.imageName)Selected") {
                button.setImage(image, forState: UIControlState.Selected)
            }
            button.accessibilityLabel = panel.accessibilityLabel
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

    func homePanel(homePanel: HomePanel, didSelectURL url: NSURL) {
        delegate?.homePanelViewController(self, didSelectURL: url)
        dismissViewControllerAnimated(true, completion: nil)
    }
}
