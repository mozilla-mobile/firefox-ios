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

class WebsiteDataManagementViewController: ThemedTableViewController, UISearchBarDelegate {
    fileprivate var clearButton: ThemedTableViewCell?
    fileprivate var showMoreButton: ThemedTableViewCell?

    var searchController: UISearchController!
    var showMoreButtonEnabled = true
    let theme = BuiltinThemeName(rawValue: ThemeManager.instance.current.name) ?? .normal

    private var siteRecords: [WKWebsiteDataRecord]?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingsWebsiteDataTitle
        navigationController?.setToolbarHidden(true, animated: false)

        getAllWebsiteData(shouldDisableShowMoreButton: false)

        // Search Controller setup
        let searchResultsViewController = WebsiteDataSearchResultsViewController()
        searchController = UISearchController(searchResultsController: searchResultsViewController)
        searchController.searchResultsUpdater = searchResultsViewController
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = Strings.SettingsFilterSitesSearchLabel
        searchController.searchBar.delegate = self
        if theme == .dark {
            searchController.searchBar.barStyle = .black
        }
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            navigationItem.titleView = searchController?.searchBar
        }
        definesPresentationContext = true

        tableView.isEditing = true
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)
        let footer = UITableViewHeaderFooterView(frame: CGRect(width: tableView.bounds.width, height: SettingsUX.TableViewHeaderFooterHeight))
        tableView.tableFooterView = footer
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
            cell.accessibilityTraits = UIAccessibilityTraitButton
            cell.accessibilityIdentifier = "ShowMoreWebsiteData"
            showMoreButton = cell 
        case .clearAllButton:
            cell.textLabel?.text = Strings.SettingsClearAllWebsiteDataButton
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = UIColor.theme.general.destructiveRed
            cell.accessibilityTraits = UIAccessibilityTraitButton
            cell.accessibilityIdentifier = "ClearAllWebsiteData"
            clearButton = cell
        }
        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return NumberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Section(rawValue: section)!
        switch section {
        case .sites:
            let numberOfRecords = siteRecords?.count ?? 0
            return showMoreButtonEnabled ? min(numberOfRecords, 10) : numberOfRecords
        case .showMore:
            return showMoreButtonEnabled ? 1 : 0
        case .clearAllButton:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            return true
        case .showMore:
            return showMoreButtonEnabled
        case .clearAllButton:
            return true
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            break
        case .showMore:
            getAllWebsiteData(shouldDisableShowMoreButton: true)
        case .clearAllButton:
            let alert =  UIAlertController.clearWebsiteDataAlert(okayCallback: clearWebsiteData)
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            present(alert, animated: true, completion: nil)
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            return true
        case .showMore, .clearAllButton:
            return false
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == UITableViewCellEditingStyle.delete, let record = siteRecords?[safe: indexPath.row] else {
            return
        }

        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().removeData(ofTypes: types, for: [record]) {
            self.siteRecords?.remove(at: indexPath.row)
            self.tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderFooterIdentifier) as? ThemedTableSectionHeaderFooterView
        headerView?.titleLabel.text = section == Section.sites.rawValue ? Strings.SettingsWebsiteDataTitle : nil
        headerView?.showBottomBorder = false
        return headerView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = Section(rawValue: section)!
        switch section {
        case .sites, .clearAllButton:
            return SettingsUX.TableViewHeaderFooterHeight
        case .showMore:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderFooterIdentifier) as? ThemedTableSectionHeaderFooterView
        footerView?.showBottomBorder = false
        return footerView
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        getAllWebsiteData(shouldDisableShowMoreButton: !showMoreButtonEnabled)
    }

    func getAllWebsiteData(shouldDisableShowMoreButton: Bool) {
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: types) { records in
            self.siteRecords = records.sorted { $0.displayName < $1.displayName }

            if let searchResultsViewController = self.searchController.searchResultsUpdater as? WebsiteDataSearchResultsViewController {
                searchResultsViewController.siteRecords = records
            }

            if shouldDisableShowMoreButton || records.count <= 10 {
                self.showMoreButtonEnabled = false
            }

            self.tableView.reloadData()
        }
    }

    func clearWebsiteData(_ action: UIAlertAction) {
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: .distantPast) {
            self.siteRecords = []
            self.showMoreButtonEnabled = false
            self.tableView.reloadData()
        }
    }
}
