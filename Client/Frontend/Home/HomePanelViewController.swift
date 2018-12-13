/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import SnapKit
import UIKit
import Storage

private struct HomePanelViewControllerUX {
    // Height of the top panel switcher button toolbar.
    static let ButtonContainerHeight: CGFloat = 40
}

protocol HomePanel: AnyObject, Themeable {
    var homePanelDelegate: HomePanelDelegate? { get set }
}

struct HomePanelUX {
    static let EmptyTabContentOffset = -180
}

protocol HomePanelDelegate: AnyObject {
    func homePanelDidRequestToSignIn()
    func homePanelDidRequestToCreateAccount()
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool)
    func homePanel(didSelectURL url: URL, visitType: VisitType)
    func homePanel(didSelectURLString url: String, visitType: VisitType)
}

enum HomePanelType: Int {
    case topSites = 0
    case bookmarks = 1
    case history = 2
    case readingList = 3
    case downloads = 4

    var internalUrl: URL {
        let aboutUrl: URL! = URL(string:"\(InternalURL.baseUrl)/\(AboutHomeHandler.path)")
        return URL(string: "#panel=\(self.rawValue)", relativeTo: aboutUrl)!
    }
}

enum LibraryPanelType: Int {
    case bookmarks = 0
    case history = 1
    case readingList = 2
    case downloads = 3

    var localhostURL: URL {
        return URL(string: "#panel=\(self.rawValue)", relativeTo: UIConstants.AboutHomePage as URL)!
    }
}

class HomePanelViewController: UIViewController, UITextFieldDelegate, HomePanelDelegate {
    var profile: Profile!
    var panels: [HomePanelDescriptor] = HomePanels().enabledPanels
    var url: URL?
    weak var delegate: HomePanelDelegate?

    fileprivate lazy var buttonContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 14
        stackView.clipsToBounds = true
        stackView.accessibilityNavigationStyle = .combined
        stackView.accessibilityLabel = NSLocalizedString("Panel Chooser", comment: "Accessibility label for the Home panel's top toolbar containing list of the home panels (top sites, bookmarks, history, remote tabs, reading list).")
        return stackView
    }()

    fileprivate var controllerContainerView = UIView()
    fileprivate var buttons: [UIButton] = []

    fileprivate var buttonTintColor: UIColor?
    fileprivate var buttonSelectedTintColor: UIColor?

    override func viewDidLoad() {
        view.backgroundColor = UIColor.theme.browser.background
        self.edgesForExtendedLayout = []

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar"),
            style: .done,
            target: self, action: #selector(done))

        view.addSubview(buttonContainerView)
        view.addSubview(controllerContainerView)

        buttonContainerView.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.safeArea.bottom)
            make.leading.trailing.equalTo(self.view).inset(14)
            make.height.equalTo(HomePanelViewControllerUX.ButtonContainerHeight)
        }

        controllerContainerView.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(self.view)
            make.bottom.equalTo(buttonContainerView.snp.top)
        }

        updateButtons()
        applyTheme()
        if selectedPanel == nil {
            selectedPanel = .bookmarks
        }
    }

    @objc func done() {
        self.dismiss(animated: true, completion: nil)
    }

    var selectedPanel: LibraryPanelType? = nil {
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
                    self.navigationItem.title = self.panels[index].accessibilityLabel
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
        return .lightContent
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
            make.edges.equalToSuperview()
        }
        panel.didMove(toParentViewController: self)
    }

    @objc func tappedButton(_ sender: UIButton!) {
        for (index, button) in buttons.enumerated() where button == sender {
            selectedPanel = LibraryPanelType(rawValue: index)
            if selectedPanel == .bookmarks {
                UnifiedTelemetry.recordEvent(category: .action, method: .view, object: .bookmarksPanel, value: .homePanelTabButton)
            } else if selectedPanel == .downloads {
                UnifiedTelemetry.recordEvent(category: .action, method: .view, object: .downloadsPanel, value: .homePanelTabButton)
            }
            break
        }
    }

    fileprivate func updateButtons() {
        for panel in panels {
            let button = UIButton()
            button.addTarget(self, action: #selector(tappedButton), for: .touchUpInside)
            if let image = UIImage.templateImageNamed("panelIcon\(panel.imageName)") {
                button.setImage(image, for: .normal)
            }
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 0)
            button.accessibilityLabel = panel.accessibilityLabel
            button.accessibilityIdentifier = panel.accessibilityIdentifier
            buttons.append(button)
            self.buttonContainerView.addArrangedSubview(button)
        }
    }

    func updateButtonTints() {
        for (index, button) in self.buttons.enumerated() {
            if index == self.selectedPanel?.rawValue {
                button.tintColor = self.buttonSelectedTintColor
            } else {
                button.tintColor = self.buttonTintColor
            }
        }
    }

    func homePanel(_ homePanel: HomePanel, didSelectURLString url: String, visitType: VisitType) {

    }

    func homePanelDidRequestToSignIn() {
        self.dismiss(animated: false, completion: nil)
        delegate?.homePanelDidRequestToSignIn()
    }

    func homePanelDidRequestToCreateAccount() {
        self.dismiss(animated: false, completion: nil)
        delegate?.homePanelDidRequestToCreateAccount()
    }

    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        delegate?.homePanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate)
    }

    func homePanel(didSelectURL url: URL, visitType: VisitType) {
        delegate?.homePanel(didSelectURL: url, visitType: visitType)
        dismiss(animated: true, completion: nil)
    }

    func homePanel(didSelectURLString url: String, visitType: VisitType) {
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
        return self.homePanel(didSelectURL: url, visitType: visitType)
    }
}

// MARK: UIAppearance
extension HomePanelViewController: Themeable {
    func applyTheme() {
        func apply(_ vc: UIViewController) -> Bool {
            guard let vc = vc as? Themeable else { return false }
            vc.applyTheme()
            return true
        }

        childViewControllers.forEach {
            if !apply($0) {
                // BookmarksPanel is nested in a UINavigationController, go one layer deeper
                $0.childViewControllers.forEach { _ = apply($0) }
            }
        }

        buttonContainerView.backgroundColor = UIColor.theme.homePanel.toolbarBackground
        view.backgroundColor = UIColor.theme.homePanel.toolbarBackground
        buttonTintColor = UIColor.theme.homePanel.toolbarTint
        buttonSelectedTintColor = UIColor.theme.homePanel.toolbarHighlight
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

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

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
