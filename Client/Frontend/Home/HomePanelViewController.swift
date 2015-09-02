/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SnapKit
import UIKit
import Storage        // For VisitType.

private struct HomePanelViewControllerUX {
    // Height of the top panel switcher button toolbar.
    static let ButtonContainerHeight: CGFloat = 40
    static let ButtonContainerBorderColor = UIColor.blackColor().colorWithAlphaComponent(0.1)
    static let BackgroundColor = UIConstants.PanelBackgroundColor
    static let EditDoneButtonRightPadding: CGFloat = -12
}

protocol HomePanelViewControllerDelegate: class {
    func homePanelViewController(homePanelViewController: HomePanelViewController, didSelectURL url: NSURL, visitType: VisitType)
    func homePanelViewController(HomePanelViewController: HomePanelViewController, didSelectPanel panel: Int)
    func homePanelViewControllerDidRequestToSignIn(homePanelViewController: HomePanelViewController)
    func homePanelViewControllerDidRequestToCreateAccount(homePanelViewController: HomePanelViewController)
}

@objc
protocol HomePanel: class {
    weak var homePanelDelegate: HomePanelDelegate? { get set }
    optional func endEditing()
}

@objc
protocol HomePanelDelegate: class {
    func homePanelDidRequestToSignIn(homePanel: HomePanel)
    func homePanelDidRequestToCreateAccount(homePanel: HomePanel)
    func homePanel(homePanel: HomePanel, didSelectURL url: NSURL, visitType: VisitType)
    optional func homePanelWillEnterEditingMode(homePanel: HomePanel)
}

class HomePanelViewController: UIViewController {
    var profile: Profile {
        didSet {
            panels = HomePanels.enabledPanelsForProfile(profile)
        }
    }

    var panels: [HomePanelDescriptor] {
        didSet {
            remakeButtons()
            selectAndDisplayPanelAtIndex(selectedIndex)
        }
    }

    var selectedIndex: Int = 0 {
        didSet {
            if oldValue != selectedIndex {
                selectAndDisplayPanelAtIndex(selectedIndex)
            }
        }
    }

    weak var delegate: HomePanelViewControllerDelegate?

    lazy private var buttonContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = HomePanelViewControllerUX.BackgroundColor
        view.clipsToBounds = true
        view.accessibilityNavigationStyle = .Combined
        view.accessibilityLabel = NSLocalizedString("Panel Chooser", comment: "Accessibility label for the Home panel's top toolbar containing list of the home panels (top sites, bookmarsk, history, remote tabs, reading list).")

        let bottomBorderView = UIView()
        bottomBorderView.backgroundColor = HomePanelViewControllerUX.ButtonContainerBorderColor
        view.addSubview(bottomBorderView)

        bottomBorderView.snp_makeConstraints { make in
            make.top.equalTo(view.snp_bottom).offset(-1)
            make.left.right.bottom.equalTo(view)
        }

        return view
    }()

    lazy private var controllerContainerView = UIView()

    private var buttons = [UIButton]()
    private var finishEditingButton: UIButton?
    private var editingPanel: HomePanel?

    init(profile: Profile) {
        self.profile = profile
        self.panels = HomePanels.enabledPanelsForProfile(profile)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view.backgroundColor = HomePanelViewControllerUX.BackgroundColor

        let blur: UIVisualEffectView? = DeviceInfo.isBlurSupported() ? UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light)) : nil

        if let blur = blur {
            view.addSubview(blur)
        }

        view.addSubview(buttonContainerView)
        view.addSubview(controllerContainerView)

        blur?.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        buttonContainerView.snp_makeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(HomePanelViewControllerUX.ButtonContainerHeight)
        }

        controllerContainerView.snp_makeConstraints { make in
            make.top.equalTo(self.buttonContainerView.snp_bottom)
            make.left.right.bottom.equalTo(self.view)
        }

        // Gesture recognizer to dismiss the keyboard in the URLBarView when the buttonContainerView is tapped
        let dismissKeyboardGestureRecognizer = UITapGestureRecognizer(target: self, action: "SELhandleDismissKeyboardGestureRecognizer:")
        dismissKeyboardGestureRecognizer.cancelsTouchesInView = false
        buttonContainerView.addGestureRecognizer(dismissKeyboardGestureRecognizer)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.panels = HomePanels.enabledPanelsForProfile(profile)
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}

// MARK: - Selectors
private extension HomePanelViewController {
    @objc func SELhandleDismissKeyboardGestureRecognizer(gestureRecognizer: UITapGestureRecognizer) {
        view.window?.rootViewController?.view.endEditing(true)
    }

    @objc func SELtappedButton(sender: UIButton!) {
        selectedIndex = sender.tag
        selectAndDisplayPanelAtIndex(selectedIndex)
        delegate?.homePanelViewController(self, didSelectPanel: selectedIndex)
    }

    @objc func endEditing(sender: UIButton!) {
        toggleEditingMode(false)
        editingPanel?.endEditing?()
        editingPanel = nil
    }
}

// MARK: - Helper methods
private extension HomePanelViewController {
    func selectAndDisplayPanelAtIndex(index: Int) {
        // Deselect all the buttons and select the new index
        buttons.forEach { $0.selected = false }
        if index < buttons.count {
            buttons[index].selected = true
        }

        if let currentPanel = childViewControllers.first {
            currentPanel.willMoveToParentViewController(nil)
            currentPanel.view.removeFromSuperview()
            currentPanel.removeFromParentViewController()
        }

        // Build the panel at the given index and display it
        if index < panels.count {
            let panel = self.panels[index].makeViewController(profile: profile)
            (panel as? HomePanel)?.homePanelDelegate = self
            panel.view.accessibilityNavigationStyle = .Combined
            panel.view.accessibilityLabel = self.panels[index].accessibilityLabel

            addChildViewController(panel)
            controllerContainerView.addSubview(panel.view)
            panel.view.snp_makeConstraints { make in
                make.top.equalTo(self.buttonContainerView.snp_bottom)
                make.left.right.bottom.equalTo(self.view)
            }
            panel.didMoveToParentViewController(self)
        }
    }

    func remakeButtons() {
        // Remove any existing buttons if we're rebuilding the toolbar.
        for button in buttons {
            button.removeFromSuperview()
        }
        buttons.removeAll()

        var prev: UIButton?
        for i in 0..<panels.count {
            let panel = panels[i]
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
            button.tag = i
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
}

extension HomePanelViewController: HomePanelDelegate {
    func homePanel(homePanel: HomePanel, didSelectURL url: NSURL, visitType: VisitType) {
        delegate?.homePanelViewController(self, didSelectURL: url, visitType: visitType)
        dismissViewControllerAnimated(true, completion: nil)
    }

    func homePanelDidRequestToCreateAccount(homePanel: HomePanel) {
        delegate?.homePanelViewControllerDidRequestToCreateAccount(self)
    }

    func homePanelDidRequestToSignIn(homePanel: HomePanel) {
        delegate?.homePanelViewControllerDidRequestToSignIn(self)
    }

    func homePanelWillEnterEditingMode(homePanel: HomePanel) {
        editingPanel = homePanel
        toggleEditingMode(true)
    }

    func toggleEditingMode(editing: Bool) {
        let translateDown = CGAffineTransformMakeTranslation(0, UIConstants.ToolbarHeight)

        if editing {
            let button = UIButton(type: UIButtonType.System)
            button.setTitle(NSLocalizedString("Done", comment: "Done editing button"), forState: UIControlState.Normal)
            button.addTarget(self, action: "endEditing:", forControlEvents: UIControlEvents.TouchUpInside)
            button.transform = translateDown
            button.titleLabel?.textAlignment = .Right
            self.buttonContainerView.addSubview(button)
            button.snp_makeConstraints { make in
                make.right.equalTo(self.buttonContainerView).offset(HomePanelViewControllerUX.EditDoneButtonRightPadding)
                make.centerY.equalTo(self.buttonContainerView)
            }
            self.buttonContainerView.layoutIfNeeded()
            finishEditingButton = button
        }

        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [UIViewAnimationOptions.AllowUserInteraction, UIViewAnimationOptions.CurveEaseInOut], animations: { () -> Void in
            self.finishEditingButton?.transform = editing ? CGAffineTransformIdentity : translateDown
        }, completion: { _ in
            if !editing {
                self.finishEditingButton?.removeFromSuperview()
                self.finishEditingButton = nil
            }
        })
    }
}