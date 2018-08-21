/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import WebKit

enum Section: Int {
    case sites = 0, showMore, button
}
private let NumberOfSections = 3
private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"

class WebsiteDataManagementViewController: ThemedTableViewController, UISearchBarDelegate {
    fileprivate var clearButton, showMoreButton: ThemedTableViewCell?
    var searchResults: UITableViewController!
    var searchController: UISearchController!
    var showMoreButtonEnabled = true
    let theme = BuiltinThemeName(rawValue: ThemeManager.instance.current.name) ?? .normal
    private var siteRecords = [siteData]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingsWebsiteDataTitle
        self.navigationController?.setToolbarHidden(true, animated: false)
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        getAllWebsiteData(shouldDisableShowMoreButton: false, shouldUpdateSearchResults: true)

        //Search Controller setup
        let searchResults = websiteSearchResultsViewController()
        searchController = UISearchController(searchResultsController: searchResults)
        searchController.searchResultsUpdater = searchResults
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

        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)
        let footer = UITableViewHeaderFooterView(frame: CGRect(width: tableView.bounds.width, height: SettingsUX.TableViewHeaderFooterHeight))
        tableView.tableFooterView = footer
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ThemedTableViewCell(style: .default, reuseIdentifier: nil)
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            let site = siteRecords[indexPath.item]
            cell.textLabel?.text = site.nameOfSite
        case .showMore:
            cell.textLabel?.text = Strings.SettingsWebsiteDataShowMoreButton
            cell.textLabel?.textColor = showMoreButtonEnabled ? UIColor.theme.general.highlightBlue : UIColor.gray
            cell.accessibilityTraits = UIAccessibilityTraitButton
            cell.accessibilityIdentifier = "ShowMoreWebsiteData"
            showMoreButton = cell 
        case .button:
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
            return siteRecords.count
        case .showMore, .button:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            if self.tableView.isEditing {
                return true
            }
        case .showMore:
            if showMoreButtonEnabled {
                return true
            }
        case .button:
            return true
        }
        return false
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            break
        case .showMore:
            getAllWebsiteData()
        case .button:
            UnifiedTelemetry.recordEvent(category: .action, method: .tap, object: .clearWebsiteDataButton)
            let alert =  UIAlertController.clearWebsiteDataAlert(okayCallback: clearwebsitedata)
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            self.present(alert, animated: true, completion: nil)
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            return true
        case .showMore, .button:
            return false
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            dataStore.removeData(ofTypes: dataTypes, for: [siteRecords[indexPath.item].dataOfSite], completionHandler: { return })
            siteRecords.remove(at: indexPath.item)
            tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderFooterIdentifier) as? ThemedTableSectionHeaderFooterView
        var sectionTitle: String?

        let section = Section(rawValue: section)!
        switch section {
        case .sites:
            sectionTitle = Strings.SettingsWebsiteDataTitle
        case .showMore, .button:
            sectionTitle = nil
        }
        headerView?.titleLabel.text = sectionTitle
        headerView?.showBottomBorder = false
        return headerView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = Section(rawValue: section)!
        switch section {
        case .sites, .button:
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
        getAllWebsiteData()
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        UnifiedTelemetry.recordEvent(category: .action, method: .tap, object: .searchWebsiteData)
    }

    func getAllWebsiteData(shouldDisableShowMoreButton : Bool = true, shouldUpdateSearchResults : Bool = false) {
        self.siteRecords.removeAll()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { (records) in
        for record in records {
        self.siteRecords.append(siteData(dataOfSite: record, nameOfSite: record.displayName))
        }
        self.siteRecords.sort { $0.nameOfSite < $1.nameOfSite }
        if shouldUpdateSearchResults {
            if let searchResults = self.searchController.searchResultsUpdater  as? websiteSearchResultsViewController {
                searchResults.siteRecords = self.siteRecords
            }
        }
        if shouldDisableShowMoreButton || self.siteRecords.count < 10 {
            self.showMoreButtonEnabled = false
        } else {
            self.siteRecords.removeLast(self.siteRecords.count - 10)
        }
        self.tableView.reloadData()
        }
    }

    func clearwebsitedata(_ action: UIAlertAction) {
        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: .distantPast, completionHandler: { return })
        siteRecords.removeAll()
        showMoreButtonEnabled = false
        tableView.reloadData()
    }

}
