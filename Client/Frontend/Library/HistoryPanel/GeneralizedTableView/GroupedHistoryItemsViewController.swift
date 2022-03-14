// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/**
This ViewController is meant to show a tableView of history items with NO section headers.
 */

import UIKit
import Storage

class GroupedHistoryItemsViewController: UIViewController, Loggable {
    
    // MARK: - Properties
    
    enum Sections: CaseIterable {
        case main
    }
    
    let profile: Profile
    let viewModel: GroupedHistoryItemsViewModel
    var libraryPanelDelegate: LibraryPanelDelegate? // Set this at the creation site!
    
    lazy private var tableView: UITableView = .build { [weak self] tableView in
        guard let self = self else { return }
        tableView.dataSource = self.diffableDatasource
        tableView.accessibilityIdentifier = "generalized-history-items-table-view"
        tableView.delegate = self
        tableView.register(OneLineTableViewCell.self, forCellReuseIdentifier: OneLineTableViewCell.reuseIdentifier)
        tableView.register(TwoLineImageOverlayCell.self, forCellReuseIdentifier: TwoLineImageOverlayCell.reuseIdentifier)
        tableView.backgroundColor = ThemeManager.shared.currentTheme.colours.layer4
        tableView.separatorColor = ThemeManager.shared.currentTheme.colours.borderDivider
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }
    
    lazy private var diffableDatasource: UITableViewDiffableDataSource<Sections, AnyHashable>! = nil
    
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
        browserLog.debug("GeneralizedHistoryItemsViewController DEinited.")
    }
    
    // MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        configureDatasource()
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
        view.backgroundColor = .systemBackground
        
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
                guard let cell = tableView.dequeueReusableCell(withIdentifier: TwoLineImageOverlayCell.reuseIdentifier, for: indexPath) as? TwoLineImageOverlayCell else {
                    self.browserLog.error("GeneralizedHistoryItems - Could not dequeue a TwoLineImageOverlayCell!")
                    return nil
                }
                
                cell.backgroundColor = ThemeManager.shared.currentTheme.colours.layer2 // need help confirming the color
                cell.titleLabel.text = site.title
                cell.titleLabel.textColor = .label
                cell.titleLabel.isHidden = site.title.isEmpty
                cell.descriptionLabel.text = site.url
                cell.descriptionLabel.isHidden = false
                cell.descriptionLabel.textColor = ThemeManager.shared.currentTheme.colours.textSecondary
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
        
        diffableDatasource.apply(snapshot, animatingDifferences: true)
    }
    
}

extension GroupedHistoryItemsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = diffableDatasource.itemIdentifier(for: indexPath) else { return }
        
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
