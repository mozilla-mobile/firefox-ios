/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import SnapKit
import UIKit
import Storage

private struct LibraryViewControllerUX {
    // Height of the top panel switcher button toolbar.
    static let ButtonContainerHeight: CGFloat = 50
}

class LibraryViewController: UIViewController {
    let profile: Profile
    let panelDescriptors: [LibraryPanelDescriptor]

    weak var delegate: LibraryPanelDelegate?

    fileprivate lazy var buttonContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 14
        stackView.clipsToBounds = true
        stackView.accessibilityNavigationStyle = .combined
        stackView.accessibilityLabel = NSLocalizedString("Panel Chooser", comment: "Accessibility label for the Library panel's bottom toolbar containing a list of the home panels (top sites, bookmarks, history, remote tabs, reading list).")
        return stackView
    }()

    fileprivate var controllerContainerView = UIView()
    fileprivate var buttons: [LibraryPanelButton] = []

    fileprivate var buttonTintColor: UIColor?
    fileprivate var buttonSelectedTintColor: UIColor?

    init(profile: Profile) {
        self.profile = profile

        self.panelDescriptors = LibraryPanels(profile: profile).enabledPanels

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.theme.browser.background
        self.edgesForExtendedLayout = []

        view.addSubview(buttonContainerView)
        view.addSubview(controllerContainerView)

        buttonContainerView.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.safeArea.bottom)
            make.leading.trailing.equalTo(self.view).inset(14)
            make.height.equalTo(LibraryViewControllerUX.ButtonContainerHeight)
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
                }
            }

            hideCurrentPanel()

            if let index = selectedPanel?.rawValue {
                if index < buttons.count {
                    let newButton = buttons[index]
                    newButton.isSelected = true
                }

                if index < panelDescriptors.count {
                    let panel = self.panelDescriptors[index].viewController
                    let navigationController = self.panelDescriptors[index].navigationController
                    let accessibilityLabel = self.panelDescriptors[index].accessibilityLabel
                    setupLibraryPanel(panel, accessibilityLabel: accessibilityLabel)
                    self.showPanel(navigationController)
                }
            }
            self.updateButtonTints()
        }
    }

    func setupLibraryPanel(_ panel: UIViewController, accessibilityLabel: String) {
        (panel as? LibraryPanel)?.libraryPanelDelegate = self
        panel.view.accessibilityNavigationStyle = .combined
        panel.view.accessibilityLabel = accessibilityLabel
        panel.title = accessibilityLabel
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    fileprivate func hideCurrentPanel() {
        if let panel = children.first {
            panel.willMove(toParent: nil)
            panel.beginAppearanceTransition(false, animated: false)
            panel.view.removeFromSuperview()
            panel.endAppearanceTransition()
            panel.removeFromParent()
        }
    }

    fileprivate func showPanel(_ panel: UIViewController) {
        addChild(panel)
        panel.beginAppearanceTransition(true, animated: false)
        controllerContainerView.addSubview(panel.view)
        panel.endAppearanceTransition()
        panel.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        panel.didMove(toParent: self)
    }

    @objc func tappedButton(_ sender: UIButton!) {
        for (index, button) in buttons.enumerated() where button == sender {
            let newSelectedPanel = LibraryPanelType(rawValue: index)

            // If we're already on the selected panel and the user has
            // tapped for a second time, pop it to the root view controller.
            if newSelectedPanel == selectedPanel {
                let panel = self.panelDescriptors[safe: index]?.navigationController
                panel?.popToRootViewController(animated: true)
            }

            selectedPanel = newSelectedPanel
            if selectedPanel == .bookmarks {
                UnifiedTelemetry.recordEvent(category: .action, method: .view, object: .bookmarksPanel, value: .homePanelTabButton)
            } else if selectedPanel == .downloads {
                UnifiedTelemetry.recordEvent(category: .action, method: .view, object: .downloadsPanel, value: .homePanelTabButton)
            }
            break
        }
    }

    fileprivate func updateButtons() {
        for panel in panelDescriptors {
            let button = LibraryPanelButton()
            button.addTarget(self, action: #selector(tappedButton), for: .touchUpInside)
            if let image = UIImage.templateImageNamed("panelIcon\(panel.imageName)") {
                button.setImage(image, for: .normal)
            }

            button.nameLabel.text = panel.accessibilityLabel
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
                button.nameLabel.textColor = self.buttonSelectedTintColor
            } else {
                button.tintColor = self.buttonTintColor
                button.nameLabel.textColor = self.buttonTintColor
            }
        }
    }
}

extension LibraryViewController: LibraryPanelDelegate {
    func libraryPanelDidRequestToSignIn() {
        self.dismiss(animated: false, completion: nil)
        delegate?.libraryPanelDidRequestToSignIn()
    }

    func libraryPanelDidRequestToCreateAccount() {
        self.dismiss(animated: false, completion: nil)
        delegate?.libraryPanelDidRequestToCreateAccount()
    }

    func libraryPanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        delegate?.libraryPanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate)
    }

    func libraryPanel(didSelectURL url: URL, visitType: VisitType) {
        delegate?.libraryPanel(didSelectURL: url, visitType: visitType)
        dismiss(animated: true, completion: nil)
    }

    func libraryPanel(didSelectURLString url: String, visitType: VisitType) {
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
        return self.libraryPanel(didSelectURL: url, visitType: visitType)
    }
}

class LibraryPanelButton: UIButton {
    var nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
        }
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.7
        nameLabel.numberOfLines = 2
        nameLabel.font = DynamicFontHelper.defaultHelper.SmallSizeRegularWeightAS
        nameLabel.textAlignment = .center
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: UIAppearance
extension LibraryViewController: Themeable {
    func applyTheme() {
        func apply(_ vc: UIViewController) -> Bool {
            guard let vc = vc as? Themeable else { return false }
            vc.applyTheme()
            return true
        }

        children.forEach {
            if !apply($0) {
                // LibraryPanels are nested in a UINavigationController, so go one layer deeper.
                $0.children.forEach { _ = apply($0) }
            }
        }

        buttonContainerView.backgroundColor = UIColor.theme.homePanel.toolbarBackground
        view.backgroundColor = UIColor.theme.homePanel.toolbarBackground
        buttonTintColor = UIColor.theme.homePanel.toolbarTint
        buttonSelectedTintColor = UIColor.theme.homePanel.toolbarHighlight
        updateButtonTints()
    }
}

protocol LibraryPanelContextMenu {
    func getSiteDetails(for indexPath: IndexPath) -> Site?
    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonActionSheetItem]?
    func presentContextMenu(for indexPath: IndexPath)
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?)
}

extension LibraryPanelContextMenu {
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

    func getDefaultContextMenuActions(for site: Site, libraryPanelDelegate: LibraryPanelDelegate?) -> [PhotonActionSheetItem]? {
        guard let siteURL = URL(string: site.url) else { return nil }

        let openInNewTabAction = PhotonActionSheetItem(title: Strings.OpenInNewTabContextMenuTitle, iconString: "quick_action_new_tab") { action in
            libraryPanelDelegate?.libraryPanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
        }

        let openInNewPrivateTabAction = PhotonActionSheetItem(title: Strings.OpenInNewPrivateTabContextMenuTitle, iconString: "quick_action_new_private_tab") { action in
            libraryPanelDelegate?.libraryPanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }

        return [openInNewTabAction, openInNewPrivateTabAction]
    }
}
