// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SnapKit
import Shared
import WebKit
import Common

class WebsiteDataSearchResultsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, Themeable {
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol

    private enum Section: Int {
        case sites = 0
        case clearButton = 1

        static let count = 2
    }

    let viewModel: WebsiteDataManagementViewModel
    private var tableView: UITableView!

    private var filteredSiteRecords = [WKWebsiteDataRecord]()
    private var currentSearchText = ""

    init(viewModel: WebsiteDataManagementViewModel,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self

        tableView.isEditing = true
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.register(cellType: ThemedTableViewCell.self)
        tableView.register(ThemedTableSectionHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier)
        view.addSubview(tableView)

        let footer = ThemedTableSectionHeaderFooterView(frame: CGRect(width: tableView.bounds.width,
                                                                      height: SettingsUX.TableViewHeaderFooterHeight))
        footer.applyTheme(theme: themeManager.currentTheme)
        footer.showBorder(for: .top, true)
        tableView.tableFooterView = footer

        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        KeyboardHelper.defaultHelper.addDelegate(self)

        listenForThemeChange(view)
        applyTheme()
    }

    func reloadData() {
        guard tableView != nil else { return }
        // to update filteredSiteRecords before reloading the tableView
        filterContentForSearchText(currentSearchText)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Section(rawValue: section)!
        switch section {
        case .sites: return filteredSiteRecords.count
        case .clearButton: return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ThemedTableViewCell.cellIdentifier, for: indexPath) as! ThemedTableViewCell
        cell.applyTheme(theme: themeManager.currentTheme)
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            if let record = filteredSiteRecords[safe: indexPath.row] {
                cell.textLabel?.text = record.displayName
                cell.textLabel?.textAlignment = .natural
                if viewModel.selectedRecords.contains(record) {
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                } else {
                    tableView.deselectRow(at: indexPath, animated: false)
                }
            }
        case .clearButton:
            cell.textLabel?.text = viewModel.clearButtonTitle
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = themeManager.currentTheme.colors.textWarning
            cell.accessibilityTraits = UIAccessibilityTraits.button
            cell.accessibilityIdentifier = "ClearAllWebsiteData"
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            guard let item = filteredSiteRecords[safe: indexPath.row] else { return }
            viewModel.deselectItem(item)
            break
        default: break
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            return true
        case .clearButton:
            return false
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier) as? ThemedTableSectionHeaderFooterView else { return nil }

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

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
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

    func applyTheme() {
        tableView.separatorColor = themeManager.currentTheme.colors.borderPrimary
        tableView.backgroundColor = themeManager.currentTheme.colors.layer1
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
