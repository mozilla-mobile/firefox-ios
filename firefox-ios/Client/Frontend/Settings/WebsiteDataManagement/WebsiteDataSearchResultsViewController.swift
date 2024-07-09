// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import WebKit
import Common

class WebsiteDataSearchResultsViewController: ThemedTableViewController {
    private enum Section: Int {
        case sites = 0
        case clearButton = 1

        static let count = 2
    }

    let viewModel: WebsiteDataManagementViewModel

    private var filteredSiteRecords = [WKWebsiteDataRecord]()
    private var currentSearchText = ""

    init(viewModel: WebsiteDataManagementViewModel,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.viewModel = viewModel
        super.init(windowUUID: windowUUID, themeManager: themeManager, notificationCenter: notificationCenter)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.isEditing = true
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.register(ThemedTableSectionHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier)

        let footer = ThemedTableSectionHeaderFooterView(frame: CGRect(width: tableView.bounds.width,
                                                                      height: SettingsUX.TableViewHeaderFooterHeight))
        footer.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        footer.showBorder(for: .top, true)
        tableView.tableFooterView = footer

        KeyboardHelper.defaultHelper.addDelegate(self)
    }

    override func dequeueCellFor(indexPath: IndexPath) -> ThemedTableViewCell {
        guard let section = Section(rawValue: indexPath.section), section == .clearButton else {
            return super.dequeueCellFor(indexPath: indexPath)
        }

        if let cell = tableView.dequeueReusableCell(
            withIdentifier: ThemedCenteredTableViewCell.cellIdentifier,
            for: indexPath) as? ThemedCenteredTableViewCell {
            return cell
        }
        return ThemedTableViewCell()
    }

    func reloadData() {
        guard tableView != nil else { return }
        // to update filteredSiteRecords before reloading the tableView
        filterContentForSearchText(currentSearchText)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Section(rawValue: section)!
        switch section {
        case .sites: return filteredSiteRecords.count
        case .clearButton: return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueCellFor(indexPath: indexPath)
        cell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        guard let section = Section(rawValue: indexPath.section) else {
            return ThemedTableViewCell()
        }
        switch section {
        case .sites:
            if let record = filteredSiteRecords[safe: indexPath.row] {
                cell.textLabel?.text = record.displayName
                if viewModel.selectedRecords.contains(record) {
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                } else {
                    tableView.deselectRow(at: indexPath, animated: false)
                }
            }
            return cell
        case .clearButton:
            guard let cell = cell as? ThemedCenteredTableViewCell else { return ThemedCenteredTableViewCell() }

            cell.setTitle(to: viewModel.clearButtonTitle)
            cell.setAccessibilities(
                traits: .button,
                identifier: AccessibilityIdentifiers.Settings.ClearData.clearAllWebsiteData)
            cell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            guard let item = filteredSiteRecords[safe: indexPath.row] else { return }
            viewModel.selectItem(item)
            break
        case .clearButton:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            let alert = viewModel.createAlertToRemove()
            present(alert, animated: true, completion: nil)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            guard let item = filteredSiteRecords[safe: indexPath.row] else { return }
            viewModel.deselectItem(item)
            break
        default: break
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            return true
        case .clearButton:
            return false
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier
        ) as? ThemedTableSectionHeaderFooterView else { return nil }

        headerView.titleLabel.text = section == Section.sites.rawValue ? .SettingsWebsiteDataTitle : nil

        headerView.showBorder(for: .top, true)
        headerView.showBorder(for: .bottom, true)

        // top section: no top border (this is a plain table)
        guard let section = Section(rawValue: section) else { return headerView }
        if section == .sites {
            headerView.showBorder(for: .top, false)

            // no records: no bottom border (would make 2 with the one from the clear button)
            let emptyRecords = viewModel.siteRecords.isEmpty
            if emptyRecords {
                headerView.showBorder(for: .bottom, false)
            }
        }
        return headerView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = Section(rawValue: section)!
        switch section {
        case .clearButton: return 10 // Controls the space between the site list and the button
        case .sites: return UITableView.automaticDimension
        }
    }

    func filterContentForSearchText(_ searchText: String) {
        filteredSiteRecords = viewModel.siteRecords.filter({ siteRecord in
            return siteRecord.displayName.lowercased().contains(searchText.lowercased())
        })

        tableView.reloadData()
    }
}

extension WebsiteDataSearchResultsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        currentSearchText = searchController.searchBar.text ?? ""
        filterContentForSearchText(currentSearchText)
    }
}

extension WebsiteDataSearchResultsViewController: KeyboardHelperDelegate {
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        let coveredHeight = state.intersectionHeightForView(view)
        tableView.contentInset.bottom = coveredHeight
        tableView.verticalScrollIndicatorInsets.bottom = coveredHeight
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        tableView.contentInset.bottom = 0
    }
}
