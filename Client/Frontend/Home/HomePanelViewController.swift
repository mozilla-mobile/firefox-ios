/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SnapKit
import UIKit
import Storage

private struct HomePanelViewControllerUX {
    // Height of the top panel switcher button toolbar.
    static let ButtonContainerHeight: CGFloat = 40
    static let ButtonContainerBorderColor = UIColor.black.withAlphaComponent(0.1)
    static let BackgroundColorPrivateMode = UIConstants.PrivateModeAssistantToolbarBackgroundColor
    static let ToolbarButtonDeselectedColorNormalMode = UIColor(white: 0.2, alpha: 0.5)
    static let ToolbarButtonDeselectedColorPrivateMode = UIColor(white: 0.9, alpha: 1)
    static let ButtonHighlightLineHeight: CGFloat = 2
    static let ButtonSelectionAnimationDuration = 0.2
}

protocol HomePanelViewControllerDelegate: class {
    func homePanelViewController(_ homePanelViewController: HomePanelViewController, didSelectURL url: URL, visitType: VisitType)
    func homePanelViewController(_ HomePanelViewController: HomePanelViewController, didSelectPanel panel: Int)
    func homePanelViewControllerDidRequestToSignIn(_ homePanelViewController: HomePanelViewController)
    func homePanelViewControllerDidRequestToCreateAccount(_ homePanelViewController: HomePanelViewController)
    func homePanelViewControllerDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool)
}

protocol HomePanel: class {
    weak var homePanelDelegate: HomePanelDelegate? { get set }
}

struct HomePanelUX {
    static let EmptyTabContentOffset = -180
}

protocol HomePanelDelegate: class {
    func homePanelDidRequestToSignIn(_ homePanel: HomePanel)
    func homePanelDidRequestToCreateAccount(_ homePanel: HomePanel)
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool)
    func homePanel(_ homePanel: HomePanel, didSelectURL url: URL, visitType: VisitType)
    func homePanel(_ homePanel: HomePanel, didSelectURLString url: String, visitType: VisitType)
}

struct HomePanelState {
    var selectedIndex: Int = 0
}

enum HomePanelType: Int {
    case topSites = 0
    case bookmarks = 1
    case history = 2
    case readingList = 3

    var localhostURL: URL {
        return URL(string: "#panel=\(self.rawValue)", relativeTo: UIConstants.AboutHomePage as URL)!
    }
}

class HomePanelViewController: UIViewController, UITextFieldDelegate, HomePanelDelegate {
    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.backgroundColor = UIConstants.AppBackgroundColor
        theme.buttonTintColor = UIColor(rgb: 0x7e7e7f)
        theme.highlightButtonColor = UIConstants.HighlightBlue
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.backgroundColor = UIConstants.AppBackgroundColor
        theme.buttonTintColor = UIColor(rgb: 0x7e7e7f)
        theme.highlightButtonColor = UIConstants.HighlightBlue
        themes[Theme.NormalMode] = theme
        
        return themes
    }()
    
    var profile: Profile!
    var notificationToken: NSObjectProtocol!
    var panels: [HomePanelDescriptor]!
    var url: URL?
    weak var delegate: HomePanelViewControllerDelegate?

    fileprivate var buttonContainerView = UIStackView()
    fileprivate var buttonContainerBottomBorderView: UIView!
    fileprivate var controllerContainerView: UIView!
    fileprivate var buttons: [UIButton] = []
    fileprivate var highlightLine = UIView() //The line underneath a panel button that shows which one is selected

    fileprivate var buttonTintColor: UIColor?
    fileprivate var buttonSelectedTintColor: UIColor?

    var homePanelState: HomePanelState {
        return HomePanelState(selectedIndex: selectedPanel?.rawValue ?? 0)
    }

    override func viewDidLoad() {
        view.backgroundColor = UIConstants.AppBackgroundColor
        
        buttonContainerView.axis = .horizontal
        buttonContainerView.alignment = .fill
        buttonContainerView.distribution = .fillEqually
        buttonContainerView.spacing = 14
        buttonContainerView.clipsToBounds = true
        buttonContainerView.accessibilityNavigationStyle = .combined
        buttonContainerView.accessibilityLabel = NSLocalizedString("Panel Chooser", comment: "Accessibility label for the Home panel's top toolbar containing list of the home panels (top sites, bookmarsk, history, remote tabs, reading list).")
        view.addSubview(buttonContainerView)
        buttonContainerView.addSubview(highlightLine)
        
        self.buttonContainerBottomBorderView = UIView()
        self.view.addSubview(buttonContainerBottomBorderView)
        buttonContainerBottomBorderView.backgroundColor = HomePanelViewControllerUX.ButtonContainerBorderColor

        controllerContainerView = UIView()
        view.addSubview(controllerContainerView)

        buttonContainerView.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.leading.trailing.equalTo(self.view).inset(14)
            make.height.equalTo(HomePanelViewControllerUX.ButtonContainerHeight)
        }

        buttonContainerBottomBorderView.snp.makeConstraints { make in
            make.top.equalTo(self.buttonContainerView.snp.bottom).offset(-1)
            make.bottom.equalTo(self.buttonContainerView)
            make.leading.trailing.equalToSuperview()
        }

        controllerContainerView.snp.makeConstraints { make in
            make.top.equalTo(self.buttonContainerView.snp.bottom)
            make.left.right.bottom.equalTo(self.view)
        }

        self.panels = HomePanels().enabledPanels
        updateButtons()

        // Gesture recognizer to dismiss the keyboard in the URLBarView when the buttonContainerView is tapped
        let dismissKeyboardGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(HomePanelViewController.dismissKeyboard(_:)))
        dismissKeyboardGestureRecognizer.cancelsTouchesInView = false
        buttonContainerView.addGestureRecognizer(dismissKeyboardGestureRecognizer)
    }

    func dismissKeyboard(_ gestureRecognizer: UITapGestureRecognizer) {
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

    func tappedButton(_ sender: UIButton!) {
        for (index, button) in buttons.enumerated() where button == sender {
            selectedPanel = HomePanelType(rawValue: index)
            delegate?.homePanelViewController(self, didSelectPanel: index)
            break
        }
    }

    fileprivate func updateButtons() {
        for panel in panels {
            let button = UIButton()
            button.addTarget(self, action: #selector(HomePanelViewController.tappedButton(_:)), for: .touchUpInside)
            if let image = UIImage.templateImageNamed("panelIcon\(panel.imageName)") {
                button.setImage(image, for: UIControlState.normal)
            }
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 0)
            button.accessibilityLabel = panel.accessibilityLabel
            button.accessibilityIdentifier = panel.accessibilityIdentifier
            buttons.append(button)
            self.buttonContainerView.addArrangedSubview(button)
        }
    }
    
    func updateButtonTints() {
        var selectedbutton: UIView?
        for (index, button) in self.buttons.enumerated() {
            if index == self.selectedPanel?.rawValue {
                button.tintColor = self.buttonSelectedTintColor
                selectedbutton = button
            } else {
                button.tintColor = self.buttonTintColor
            }
        }
        guard let button = selectedbutton else {
            return
        }

        // Calling this before makes sure that only the highlightline animates and not the homepanels
        self.view.setNeedsUpdateConstraints()
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: HomePanelViewControllerUX.ButtonSelectionAnimationDuration, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.0, options: [], animations: { _ in
            self.highlightLine.snp.remakeConstraints { make in
                make.leading.equalTo(button.snp.leading)
                make.trailing.equalTo(button.snp.trailing)
                make.bottom.equalToSuperview()
                make.height.equalTo(HomePanelViewControllerUX.ButtonHighlightLineHeight)
            }
            self.view.setNeedsUpdateConstraints()
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    func homePanel(_ homePanel: HomePanel, didSelectURLString url: String, visitType: VisitType) {
        // If we can't get a real URL out of what should be a URL, we let the user's
        // default search engine give it a shot.
        // Typically we'll be in this state if the user has tapped a bookmarked search template
        // (e.g., "http://foo.com/bar/?query=%s"), and this will get them the same behavior as if
        // they'd copied and pasted into the URL bar.
        // See BrowserViewController.urlBar:didSubmitText:.
        guard let url = URIFixup.getURL(url) ?? profile.searchEngines.defaultEngine.searchURLForQuery(url) else {
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
}

// MARK: UIAppearance
extension HomePanelViewController: Themeable {
    func applyTheme(_ themeName: String) {
        guard let theme = HomePanelViewController.Themes[themeName] else {
            fatalError("Theme not found")
        }
        
        highlightLine.backgroundColor = theme.highlightButtonColor
        buttonContainerView.backgroundColor = theme.backgroundColor
        self.view.backgroundColor = theme.backgroundColor
        buttonTintColor = theme.buttonTintColor
        buttonSelectedTintColor = theme.highlightButtonColor
        updateButtonTints()
    }
}

protocol HomePanelContextMenu {
    func getSiteDetails(for indexPath: IndexPath) -> Site?
    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonActionSheetItem]?
    func presentContextMenu(for indexPath: IndexPath)
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?)
}

extension HomePanelContextMenu {
    func presentContextMenu(for indexPath: IndexPath) {
        guard let site = getSiteDetails(for: indexPath) else { return }

        presentContextMenu(for: site, with: indexPath, completionHandler: {
            return self.contextMenu(for: site, with: indexPath)
        })
    }

    func contextMenu(for site: Site, with indexPath: IndexPath) -> PhotonActionSheet? {
        guard let actions = self.getContextMenuActions(for: site, with: indexPath) else { return nil }

        let contextMenu = PhotonActionSheet(site: site, actions: actions)
        contextMenu.modalPresentationStyle = .overFullScreen
        contextMenu.modalTransitionStyle = .crossDissolve

        return contextMenu
    }

    func getDefaultContextMenuActions(for site: Site, homePanelDelegate: HomePanelDelegate?) -> [PhotonActionSheetItem]? {
        guard let siteURL = URL(string: site.url) else { return nil }

        let openInNewTabAction = PhotonActionSheetItem(title: Strings.OpenInNewTabContextMenuTitle, iconString: "quick_action_new_tab") { action in
            homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
        }

        let openInNewPrivateTabAction = PhotonActionSheetItem(title: Strings.OpenInNewPrivateTabContextMenuTitle, iconString: "quick_action_new_private_tab") { action in
            homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }

        return [openInNewTabAction, openInNewPrivateTabAction]
    }
}
