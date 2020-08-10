/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import WebKit

enum Section: Int {
    case sites = 0
    case showMore = 1
    case clearAllButton = 2
}

private let NumberOfSections = 3
private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"

class WebsiteDataManagementViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    fileprivate let loadingView = SettingsLoadingView()

    fileprivate var clearButton: ThemedTableViewCell?
    fileprivate var showMoreButton: ThemedTableViewCell?

    var tableView: UITableView!
    var searchController: UISearchController?
    var showMoreButtonEnabled = true
    let theme = BuiltinThemeName(rawValue: ThemeManager.instance.current.name) ?? .normal

    private let searchResultsViewController = WebsiteDataSearchResultsViewController()

    private var siteRecords: [WKWebsiteDataRecord]? {
        didSet {
            if let siteRecords = siteRecords {
                // Keep Search Results View Controller Data Synchronized
                searchResultsViewController.siteRecords = siteRecords
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingsWebsiteDataTitle
        navigationController?.setToolbarHidden(true, animated: false)

        tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorColor = UIColor.theme.tableView.separator
        tableView.backgroundColor = UIColor.theme.tableView.headerBackground
        tableView.isEditing = true
        tableView.allowsSelectionDuringEditing = true
        tableView.register(ThemedTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)

        let footer = ThemedTableSectionHeaderFooterView(frame: CGRect(width: tableView.bounds.width, height: SettingsUX.TableViewHeaderFooterHeight))
        footer.showBorder(for: .top, true)
        tableView.tableFooterView = footer

        view.addSubview(tableView)
        view.addSubview(loadingView)

        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }

        loadingView.snp.makeConstraints { make in
            make.edges.equalTo(tableView)
        }

        getAllWebsiteData()

        // Search Controller setup
        searchResultsViewController.delegate = self

        let searchController = UISearchController(searchResultsController: searchResultsViewController)

        // No need to hide the navigation bar on iPad, on iPhone the additional height is useful.
        searchController.hidesNavigationBarDuringPresentation = UIDevice.current.userInterfaceIdiom != .pad

        searchController.searchResultsUpdater = searchResultsViewController
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = Strings.SettingsFilterSitesSearchLabel
        searchController.searchBar.delegate = self

        if theme == .dark {
            searchController.searchBar.barStyle = .black
        }
        navigationItem.searchController = searchController
        self.searchController = searchController

        definesPresentationContext = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        unfoldSearchbar()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ThemedTableViewCell(style: .default, reuseIdentifier: nil)
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            if let record = siteRecords?[safe: indexPath.row] {
                cell.textLabel?.text = record.displayName
            }
        case .showMore:
            cell.textLabel?.text = Strings.SettingsWebsiteDataShowMoreButton
            cell.textLabel?.textColor = showMoreButtonEnabled ? UIColor.theme.general.highlightBlue : UIColor.gray
            cell.accessibilityTraits = UIAccessibilityTraits.button
            cell.accessibilityIdentifier = "ShowMoreWebsiteData"
            showMoreButton = cell 
        case .clearAllButton:
            cell.textLabel?.text = Strings.SettingsClearAllWebsiteDataButton
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = UIColor.theme.general.destructiveRed
            cell.accessibilityTraits = UIAccessibilityTraits.button
            cell.accessibilityIdentifier = "ClearAllWebsiteData"
            clearButton = cell
        }
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return NumberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Section(rawValue: section)!
        switch section {
        case .sites:
            let numberOfRecords = siteRecords?.count ?? 0

            // Show either 10, 8 or 6 records initially depending on the screen size.
            let height = max(self.view.frame.width, self.view.frame.height)
            let numberOfInitialRecords = height > 667 ? 10 : height > 568 ? 8 : 6
            return showMoreButtonEnabled ? min(numberOfRecords, numberOfInitialRecords) : numberOfRecords
        case .showMore:
            return showMoreButtonEnabled ? 1 : 0
        case .clearAllButton:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            break
        case .showMore:
            showMoreButtonEnabled = false
            tableView.reloadData()
        case .clearAllButton:
            let alert =  UIAlertController.clearWebsiteDataAlert(okayCallback: clearWebsiteData)
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            present(alert, animated: true, completion: nil)
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            return true
        case .showMore, .clearAllButton:
            return false
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == UITableViewCell.EditingStyle.delete, let record = siteRecords?[safe: indexPath.row] else {
            return
        }

        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().removeData(ofTypes: types, for: [record]) {}

        siteRecords?.remove(at: indexPath.row)
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderFooterIdentifier) as? ThemedTableSectionHeaderFooterView
        headerView?.titleLabel.text = section == Section.sites.rawValue ? Strings.SettingsWebsiteDataTitle : nil

        headerView?.showBorder(for: .top, true)
        headerView?.showBorder(for: .bottom, true)

        // top section: no top border (this is a plain table)
        guard let section = Section(rawValue: section) else { return headerView }
        if section == .sites {
            headerView?.showBorder(for: .top, false)

            // no records: no bottom border (would make 2 with the one from the clear button)
            let emptyRecords = siteRecords?.isEmpty ?? true
            if emptyRecords {
                headerView?.showBorder(for: .bottom, false)
            }
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = Section(rawValue: section)!
        switch section {
        case .clearAllButton:
            return 10 // Controls the space between the site list and the button
        case .sites:
            return SettingsUX.TableViewHeaderFooterHeight
        case .showMore:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderFooterIdentifier) as? ThemedTableSectionHeaderFooterView
        footerView?.showBorder(for: .top, true)
        footerView?.showBorder(for: .bottom, true)
        return footerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func getAllWebsiteData() {
        loadingView.isHidden = false

        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: types) { records in
            self.siteRecords = records.sorted { $0.displayName < $1.displayName }

            if let searchResultsViewController = self.searchController?.searchResultsUpdater as? WebsiteDataSearchResultsViewController {
                searchResultsViewController.siteRecords = records
            }

            // Show either 10, 8 or 6 records initially depending on the screen size.
            let height = max(self.view.frame.width, self.view.frame.height)
            let numberOfInitialRecords = height > 667 ? 10 : height > 568 ? 8 : 6
            self.showMoreButtonEnabled = records.count > numberOfInitialRecords

            self.loadingView.isHidden = true
            self.tableView.reloadData()
        }
    }

    func clearWebsiteData(_ action: UIAlertAction) {
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: .distantPast) {}

        siteRecords = []
        showMoreButtonEnabled = false
        tableView.reloadData()
    }
    
    private func unfoldSearchbar() {
        guard let searchBarHeight = navigationItem.searchController?.searchBar.intrinsicContentSize.height else { return }
        tableView.setContentOffset(CGPoint(x: 0, y: -searchBarHeight + tableView.contentOffset.y), animated: true)
    }
}

extension WebsiteDataManagementViewController: WebsiteDataSearchResultsViewControllerDelegate {
    func websiteDataSearchResultsViewController(_ viewController: WebsiteDataSearchResultsViewController, didDeleteRecord record: WKWebsiteDataRecord) {
        siteRecords?.removeAll(where: { $0 == record })
        tableView.reloadData()
    }
}
