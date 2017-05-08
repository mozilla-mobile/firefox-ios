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
    static let ButtonContainerBorderColor = UIColor.black.withAlphaComponent(0.1)
    static let BackgroundColorNormalMode = UIConstants.PanelBackgroundColor
    static let BackgroundColorPrivateMode = UIConstants.PrivateModeAssistantToolbarBackgroundColor
    static let EditDoneButtonRightPadding: CGFloat = -12
    static let ToolbarButtonDeselectedColorNormalMode = UIColor(white: 0.2, alpha: 0.5)
    static let ToolbarButtonDeselectedColorPrivateMode = UIColor(white: 0.9, alpha: 1)
}

protocol HomePanelViewControllerDelegate: class {
    func homePanelViewController(_ homePanelViewController: HomePanelViewController, didSelectURL url: URL, visitType: VisitType)
    func homePanelViewController(_ HomePanelViewController: HomePanelViewController, didSelectPanel panel: Int)
    func homePanelViewControllerDidRequestToSignIn(_ homePanelViewController: HomePanelViewController)
    func homePanelViewControllerDidRequestToCreateAccount(_ homePanelViewController: HomePanelViewController)
    func homePanelViewControllerDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool)
}

@objc
protocol HomePanel: class {
    weak var homePanelDelegate: HomePanelDelegate? { get set }
    @objc optional func endEditing()
}

struct HomePanelUX {
    static let EmptyTabContentOffset = -180
}

@objc
protocol HomePanelDelegate: class {
    func homePanelDidRequestToSignIn(_ homePanel: HomePanel)
    func homePanelDidRequestToCreateAccount(_ homePanel: HomePanel)
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool)
    func homePanel(_ homePanel: HomePanel, didSelectURL url: URL, visitType: VisitType)
    func homePanel(_ homePanel: HomePanel, didSelectURLString url: String, visitType: VisitType)
    @objc optional func homePanelWillEnterEditingMode(_ homePanel: HomePanel)
}

struct HomePanelState {
    var isPrivate: Bool = false
    var selectedIndex: Int = 0
}

enum HomePanelType: Int {
    case topSites = 0
    case bookmarks = 1
    case history = 2
    case readingList = 3

    var localhostURL: URL {
        return URL(string:"#panel=\(self.rawValue)", relativeTo: UIConstants.AboutHomePage as URL)!
    }
}

class HomePanelViewController: UIViewController, UITextFieldDelegate, HomePanelDelegate {
    var profile: Profile!
    var notificationToken: NSObjectProtocol!
    var panels: [HomePanelDescriptor]!
    var url: URL?
    weak var delegate: HomePanelViewControllerDelegate?
    weak var appStateDelegate: AppStateDelegate?

    fileprivate var buttonContainerView: UIView!
    fileprivate var buttonContainerBottomBorderView: UIView!
    fileprivate var controllerContainerView: UIView!
    fileprivate var buttons: [UIButton] = []

    fileprivate var finishEditingButton: UIButton?
    fileprivate var editingPanel: HomePanel?

    var isPrivateMode: Bool = false {
        didSet {
            if oldValue != isPrivateMode {
                self.buttonContainerView.backgroundColor = isPrivateMode ? HomePanelViewControllerUX.BackgroundColorPrivateMode : HomePanelViewControllerUX.BackgroundColorNormalMode
                self.updateButtonTints()
                self.updateAppState()
            }
        }
    }

    var homePanelState: HomePanelState {
        return HomePanelState(isPrivate: isPrivateMode, selectedIndex: selectedPanel?.rawValue ?? 0)
    }

    override func viewDidLoad() {
        view.backgroundColor = HomePanelViewControllerUX.BackgroundColorNormalMode

        let blur: UIVisualEffectView? = DeviceInfo.isBlurSupported() ? UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.light)) : nil

        if let blur = blur {
            view.addSubview(blur)
        }

        buttonContainerView = UIView()
        buttonContainerView.backgroundColor = HomePanelViewControllerUX.BackgroundColorNormalMode
        buttonContainerView.clipsToBounds = true
        buttonContainerView.accessibilityNavigationStyle = .combined
        buttonContainerView.accessibilityLabel = NSLocalizedString("Panel Chooser", comment: "Accessibility label for the Home panel's top toolbar containing list of the home panels (top sites, bookmarsk, history, remote tabs, reading list).")
        view.addSubview(buttonContainerView)

        self.buttonContainerBottomBorderView = UIView()
        buttonContainerView.addSubview(buttonContainerBottomBorderView)
        buttonContainerBottomBorderView.backgroundColor = HomePanelViewControllerUX.ButtonContainerBorderColor

        controllerContainerView = UIView()
        view.addSubview(controllerContainerView)

        blur?.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        buttonContainerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(HomePanelViewControllerUX.ButtonContainerHeight)
        }

        buttonContainerBottomBorderView.snp.makeConstraints { make in
            make.top.equalTo(self.buttonContainerView.snp.bottom).offset(-1)
            make.left.right.bottom.equalTo(self.buttonContainerView)
        }

        controllerContainerView.snp.makeConstraints { make in
            make.top.equalTo(self.buttonContainerView.snp.bottom)
            make.left.right.bottom.equalTo(self.view)
        }

        self.panels = HomePanels().enabledPanels
        updateButtons()

        // Gesture recognizer to dismiss the keyboard in the URLBarView when the buttonContainerView is tapped
        let dismissKeyboardGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(HomePanelViewController.SELhandleDismissKeyboardGestureRecognizer(_:)))
        dismissKeyboardGestureRecognizer.cancelsTouchesInView = false
        buttonContainerView.addGestureRecognizer(dismissKeyboardGestureRecognizer)

        // Invalidate our activity stream data sources whenever we open up the home panels
        self.profile.panelDataObservers.activityStream.invalidate(highlights: false)
    }

    fileprivate func updateAppState() {
        let state = mainStore.updateState(.homePanels(homePanelState: homePanelState))
        self.appStateDelegate?.appDidUpdateState(state)
    }

    func SELhandleDismissKeyboardGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        view.window?.rootViewController?.view.endEditing(true)
    }

    var selectedPanel: HomePanelType? = nil {
        didSet {
            if oldValue == selectedPanel {
                // Prevent flicker, allocations, and disk access: avoid duplicate view controllers.
                return
            }

            if let index = oldValue?.rawValue {
                if index < buttons.count {
                    let currentButton = buttons[index]
                    currentButton.isSelected = false
                    currentButton.isUserInteractionEnabled = true
                }
            }

            hideCurrentPanel()

            if let index = selectedPanel?.rawValue {
                if index < buttons.count {
                    let newButton = buttons[index]
                    newButton.isSelected = true
                    newButton.isUserInteractionEnabled = false
                }

                if index < panels.count {
                    let panel = self.panels[index].makeViewController(profile)
                    let accessibilityLabel = self.panels[index].accessibilityLabel
                    if let panelController = panel as? UINavigationController,
                        let rootPanel = panelController.viewControllers.first {
                        setupHomePanel(rootPanel, accessibilityLabel: accessibilityLabel)
                        self.showPanel(panelController)
                    } else {
                        setupHomePanel(panel, accessibilityLabel: accessibilityLabel)
                        self.showPanel(panel)
                    }
                }
            }
            self.updateButtonTints()
            self.updateAppState()
        }
    }

    func setupHomePanel(_ panel: UIViewController, accessibilityLabel: String) {
        (panel as? HomePanel)?.homePanelDelegate = self
        panel.view.accessibilityNavigationStyle = .combined
        panel.view.accessibilityLabel = accessibilityLabel
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    fileprivate func hideCurrentPanel() {
        if let panel = childViewControllers.first {
            panel.willMove(toParentViewController: nil)
            panel.beginAppearanceTransition(false, animated: false)
            panel.view.removeFromSuperview()
            panel.endAppearanceTransition()
            panel.removeFromParentViewController()
        }
    }

    fileprivate func showPanel(_ panel: UIViewController) {
        addChildViewController(panel)
        panel.beginAppearanceTransition(true, animated: false)
        controllerContainerView.addSubview(panel.view)
        panel.endAppearanceTransition()
        panel.view.snp.makeConstraints { make in
            make.top.equalTo(self.buttonContainerView.snp.bottom)
            make.left.right.bottom.equalTo(self.view)
        }
        panel.didMove(toParentViewController: self)
    }

    func SELtappedButton(_ sender: UIButton!) {
        for (index, button) in buttons.enumerated() {
            if button == sender {
                selectedPanel = HomePanelType(rawValue: index)
                delegate?.homePanelViewController(self, didSelectPanel: index)
                break
            }
        }
    }

    func endEditing(_ sender: UIButton!) {
        toggleEditingMode(false)
        editingPanel?.endEditing?()
        editingPanel = nil
    }

    fileprivate func updateButtons() {
        // Remove any existing buttons if we're rebuilding the toolbar.
        for button in buttons {
            button.removeFromSuperview()
        }
        buttons.removeAll()

        var prev: UIView? = nil
        for panel in panels {
            let button = UIButton()
            buttonContainerView.addSubview(button)
            button.addTarget(self, action: #selector(HomePanelViewController.SELtappedButton(_:)), for: UIControlEvents.touchUpInside)
            if let image = UIImage.templateImageNamed("panelIcon\(panel.imageName)") {
                button.setImage(image, for: UIControlState.normal)
            }
            if let image = UIImage.templateImageNamed("panelIcon\(panel.imageName)Selected") {
                button.setImage(image, for: UIControlState.selected)
            }
            button.accessibilityLabel = panel.accessibilityLabel
            button.accessibilityIdentifier = panel.accessibilityIdentifier
            buttons.append(button)

            button.snp.remakeConstraints { make in
                let left = prev?.snp.right ?? self.view.snp.left
                make.left.equalTo(left)
                make.height.centerY.equalTo(self.buttonContainerView)
                make.width.equalTo(self.buttonContainerView).dividedBy(self.panels.count)
            }

            prev = button
        }
    }
    
    func updateButtonTints() {
        for (index, button) in self.buttons.enumerated() {
            if index == self.selectedPanel?.rawValue {
                button.tintColor = isPrivateMode ? UIConstants.PrivateModePurple : UIConstants.HighlightBlue
            } else {
                button.tintColor = isPrivateMode ? HomePanelViewControllerUX.ToolbarButtonDeselectedColorPrivateMode : HomePanelViewControllerUX.ToolbarButtonDeselectedColorNormalMode
            }
        }
    }

    func homePanel(_ homePanel: HomePanel, didSelectURLString url: String, visitType: VisitType) {
        // If we can't get a real URL out of what should be a URL, we let the user's
        // default search engine give it a shot.
        // Typically we'll be in this state if the user has tapped a bookmarked search template
        // (e.g., "http://foo.com/bar/?query=%s"), and this will get them the same behavior as if
        // they'd copied and pasted into the URL bar.
        // See BrowserViewController.urlBar:didSubmitText:.
        guard let url = URIFixup.getURL(url) ??
                        profile.searchEngines.defaultEngine.searchURLForQuery(url) else {
            Logger.browserLogger.warning("Invalid URL, and couldn't generate a search URL for it.")
            return
        }

        return self.homePanel(homePanel, didSelectURL: url, visitType: visitType)
    }

    func homePanel(_ homePanel: HomePanel, didSelectURL url: URL, visitType: VisitType) {
        delegate?.homePanelViewController(self, didSelectURL: url, visitType: visitType)
        dismiss(animated: true, completion: nil)
    }

    func homePanelDidRequestToCreateAccount(_ homePanel: HomePanel) {
        delegate?.homePanelViewControllerDidRequestToCreateAccount(self)
    }

    func homePanelDidRequestToSignIn(_ homePanel: HomePanel) {
        delegate?.homePanelViewControllerDidRequestToSignIn(self)
    }
    
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        delegate?.homePanelViewControllerDidRequestToOpenInNewTab(url, isPrivate: isPrivate)
    }

    func homePanelWillEnterEditingMode(_ homePanel: HomePanel) {
        editingPanel = homePanel
        toggleEditingMode(true)
    }

    func toggleEditingMode(_ editing: Bool) {
        let translateDown = CGAffineTransform(translationX: 0, y: UIConstants.ToolbarHeight)
        let translateUp = CGAffineTransform(translationX: 0, y: -UIConstants.ToolbarHeight)

        if editing {
            let button = UIButton(type: UIButtonType.system)
            button.setTitle(NSLocalizedString("Done", comment: "Done editing button"), for: UIControlState())
            button.addTarget(self, action: #selector(HomePanelViewController.endEditing(_:)), for: UIControlEvents.touchUpInside)
            button.transform = translateDown
            button.titleLabel?.textAlignment = .right
            button.tintColor = self.isPrivateMode ? UIConstants.PrivateModeActionButtonTintColor : UIConstants.SystemBlueColor
            self.buttonContainerView.addSubview(button)
            button.snp.makeConstraints { make in
                make.right.equalTo(self.buttonContainerView).offset(HomePanelViewControllerUX.EditDoneButtonRightPadding)
                make.centerY.equalTo(self.buttonContainerView)
            }
            self.buttonContainerView.layoutIfNeeded()
            finishEditingButton = button
        }

        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: { () -> Void in
            self.buttons.forEach { $0.transform = editing ? translateUp : CGAffineTransform.identity }
            self.finishEditingButton?.transform = editing ? CGAffineTransform.identity : translateDown
        }, completion: { _ in
            if !editing {
                self.finishEditingButton?.removeFromSuperview()
                self.finishEditingButton = nil
            }
        })
    }
}
