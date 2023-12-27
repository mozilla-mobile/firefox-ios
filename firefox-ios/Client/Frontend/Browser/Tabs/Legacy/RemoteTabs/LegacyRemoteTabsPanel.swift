// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage
import Common

protocol RemotePanelDelegateProvider: AnyObject {
    var remotePanelDelegate: RemotePanelDelegate? { get }
}

protocol RemotePanelDelegate: AnyObject {
    func remotePanelDidRequestToSignIn()
    func remotePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool)
    func remotePanel(didSelectURL url: URL, visitType: VisitType)
}

// MARK: - RemoteTabsPanel
class LegacyRemoteTabsPanel: UIViewController,
                             Themeable,
                             RemoteTabsClientAndTabsDataSourceDelegate,
                             RemotePanelDelegateProvider {
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    var remotePanelDelegate: RemotePanelDelegate?
    var profile: Profile
    var tableViewController: LegacyRemoteTabsTableViewController

    init(profile: Profile,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.profile = profile
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.tableViewController = LegacyRemoteTabsTableViewController(profile: profile)

        super.init(nibName: nil, bundle: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(notificationReceived),
                                       name: .FirefoxAccountChanged,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(notificationReceived),
                                       name: .ProfileDidFinishSyncing,
                                       object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableViewController.remoteTabsPanel = self

        listenForThemeChange(view)
        setupLayout()
        applyTheme()
    }

    private func setupLayout() {
        tableViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(tableViewController)
        view.addSubview(tableViewController.view)
        tableViewController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            tableViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            tableViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func applyTheme() {
        view.backgroundColor = themeManager.currentTheme.colors.layer4
        tableViewController.tableView.backgroundColor =  themeManager.currentTheme.colors.layer3
        tableViewController.tableView.separatorColor = themeManager.currentTheme.colors.borderPrimary
        tableViewController.tableView.reloadData()
        tableViewController.refreshTabs()
    }

    func forceRefreshTabs() {
        tableViewController.refreshTabs(updateCache: true)
    }

    @objc
    func notificationReceived(_ notification: Notification) {
        switch notification.name {
        case .FirefoxAccountChanged, .ProfileDidFinishSyncing:
            DispatchQueue.main.async {
                self.tableViewController.refreshTabs()
            }
            break
        default:
            // no need to do anything at all
            break
        }
    }

    func remoteTabsClientAndTabsDataSourceDidSelectURL(_ url: URL, visitType: VisitType) {
        // Pass event along to our delegate
        remotePanelDelegate?.remotePanel(didSelectURL: url, visitType: VisitType.typed)
    }
}
