// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/**
This ViewController is meant to show a tableView of history items with NO section headers.
 When we have coordinators, where the coordinator provides the VM to the VC, we can
 generalize this.
 */

import UIKit
import Storage

class GroupedHistoryItemsViewController: UIViewController, Loggable {
    
    // MARK: - Properties
    
    typealias a11y = AccessibilityIdentifiers.LibraryPanels.GroupedList
    
    enum Sections: CaseIterable {
        case main
    }
    
    let profile: Profile
    let viewModel: GroupedHistoryItemsViewModel
    var libraryPanelDelegate: LibraryPanelDelegate? // Set this at the creation site!
    
    lazy private var tableView: UITableView = .build { [weak self] tableView in
        guard let self = self else { return }
        tableView.dataSource = self.diffableDatasource
        tableView.accessibilityIdentifier = a11y.tableView
        tableView.delegate = self
        tableView.register(OneLineTableViewCell.self, forCellReuseIdentifier: OneLineTableViewCell.cellIdentifier)
        tableView.register(TwoLineImageOverlayCell.self, forCellReuseIdentifier: TwoLineImageOverlayCell.cellIdentifier)
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }
    
    private var diffableDatasource: UITableViewDiffableDataSource<Sections, AnyHashable>?
    
    // MARK: - Inits
    
    init(profile: Profile, viewModel: GroupedHistoryItemsViewModel) {
        self.profile = profile
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        browserLog.debug("GeneralizedHistoryItemsViewController Deinitialized.")
    }
    
    // MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        configureDatasource()
        setupNotifications()
        applyTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        applySnapshot()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        TelemetryWrapper.recordEvent(category: .action, method: .navigate, object: .navigateToGroupHistory, value: nil, extras: nil)
    }
    
    // MARK: - Misc. helpers
    
    private func setupLayout() {
        view.addSubviews(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    // MARK: - TableView datasource helpers
    
    private func configureDatasource() {
        diffableDatasource = UITableViewDiffableDataSource<Sections, AnyHashable> (tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            
            if let site = item as? Site {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: TwoLineImageOverlayCell.cellIdentifier, for: indexPath) as? TwoLineImageOverlayCell else {
                    self.browserLog.error("GeneralizedHistoryItems - Could not dequeue a TwoLineImageOverlayCell!")
                    return nil
                }
                
                cell.titleLabel.text = site.title
                cell.titleLabel.isHidden = site.title.isEmpty
                cell.descriptionLabel.text = site.url
                cell.descriptionLabel.isHidden = false
                cell.leftImageView.layer.borderColor = ThemeManager.shared.currentTheme.colours.layer4.cgColor
                cell.leftImageView.layer.borderWidth = 0.5
                cell.leftImageView.contentMode = .center
                cell.leftImageView.setImageAndBackground(forIcon: site.icon, website: site.tileURL) { [weak cell] in
                    cell?.leftImageView.image = cell?.leftImageView.image?.createScaled(CGSize(width: 24, height: 24))
                }
                
                return cell
            }
            
            // This shouldn't happen! An empty row!
            return UITableViewCell()
        }
    }
    
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Sections, AnyHashable>()
        
        snapshot.appendSections(Sections.allCases)
        
        snapshot.appendItems(viewModel.asGroup.groupedItems, toSection: .main)
        
        diffableDatasource?.apply(snapshot, animatingDifferences: true)
    }
    
    // MARK: - Misc. helpers
    
    private func setupNotifications() {
        viewModel.notifications.forEach {
            NotificationCenter.default.addObserver(self, selector: #selector(handleNotifications), name: $0, object: nil)
        }
    }
    
    @objc private func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default:
            self.browserLog.error("Recieved unhandled notification! \(notification)")
        }
    }
    
}

extension GroupedHistoryItemsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = diffableDatasource?.itemIdentifier(for: indexPath) else { return }
        
        if let site = item as? Site {
            handleSiteItemTapped(site: site)
        }
        
    }
    
    private func handleSiteItemTapped(site: Site) {
        guard let url = URL(string: site.url) else {
            browserLog.error("Couldn't navigate to site: \(site.url)")
            return
        }
        
        libraryPanelDelegate?.libraryPanel(didSelectURL: url, visitType: .typed)
        
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .selectedHistoryItem,
                                     value: .historyPanelGroupedItem,
                                     extras: nil)
    }
}

extension GroupedHistoryItemsViewController: NotificationThemeable {
    func applyTheme() {
        let theme = BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal
        if theme == .dark {
            tableView.backgroundColor = UIColor.theme.homePanel.panelBackground
        } else {
            tableView.backgroundColor = UIColor.theme.homePanel.panelBackground
        }
        
        view.backgroundColor = .systemBackground
        tableView.separatorColor = ThemeManager.shared.currentTheme.colours.borderDivider
        
        tableView.reloadData()
    }
}
