/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Shared

private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"

class websiteSearchResultsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let flexible = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
    let editButton: UIBarButtonItem = UIBarButtonItem(title: Strings.SettingsEditWebsiteSearchButton, style: .plain, target: self, action: #selector(didPressEdit))
    let doneButton: UIBarButtonItem = UIBarButtonItem(title: Strings.SettingsDoneWebsiteSearchButton, style: .done, target: self, action: #selector(didPressDone))
    let deleteButton: UIBarButtonItem = UIBarButtonItem(title: Strings.SettingsDeleteWebsiteSearchButton, style: .plain, target: self, action: #selector(didPressDelete))
    let tableView = UITableView()
    private var toolBar: UIToolbar!
    
    private var filteredSiteRecords = [siteData]()
    var siteRecords = [siteData]()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.allowsMultipleSelectionDuringEditing = true

        //toolbar
        let border = CGRect(x: 0, y: 10.0, width: self.view.bounds.size.width, height: 44.0)
        toolBar = UIToolbar(frame: border)
        toolBar.items = [flexible, editButton]
        toolBar.barTintColor = UIColor.theme.tableView.headerBackground
        view.addSubview(toolBar)
        updateConstraints()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ThemedTableViewCell.self, forCellReuseIdentifier: "Cell")

        tableView.register(ThemedTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)
        tableView.separatorColor = UIColor.theme.tableView.separator
        tableView.backgroundColor = UIColor.theme.tableView.headerBackground
        let footer = ThemedTableSectionHeaderFooterView(frame: CGRect(width: tableView.bounds.width, height: SettingsUX.TableViewHeaderFooterHeight))
        footer.showBottomBorder = false
        tableView.tableFooterView = footer
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredSiteRecords.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let site = filteredSiteRecords[indexPath.item]
        cell.textLabel?.text = site.nameOfSite
        return cell
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if self.tableView.isEditing {
            return true
        }
        return false
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            dataStore.removeData(ofTypes: dataTypes, for: [filteredSiteRecords[indexPath.item].dataOfSite], completionHandler: { return })
            filteredSiteRecords.remove(at: indexPath.item)
            tableView.reloadData()
            
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderFooterIdentifier) as? ThemedTableSectionHeaderFooterView
        var sectionTitle: String?
        sectionTitle = Strings.SettingsWebsiteDataTitle
        headerView?.titleLabel.text = sectionTitle
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return SettingsUX.TableViewHeaderFooterHeight
    }

    func filterContentForSearchText(_ searchText: String) {
        filteredSiteRecords = siteRecords.filter({( siteRecord: siteData) -> Bool in
            return siteRecord.nameOfSite.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }

    @objc func didPressEdit() {
        self.tableView.setEditing(true, animated: true)
        toolBar.items = [deleteButton, flexible, doneButton]
    }

    @objc func didPressDone() {
        self.tableView.setEditing(false, animated: true)
        toolBar.items = [flexible, editButton]
    }

    @objc func didPressDelete() {
        let selectedRows = self.tableView.indexPathsForSelectedRows
        if selectedRows != nil {
            for var selectionIndex in selectedRows! {
                while selectionIndex.item >= filteredSiteRecords.count {
                    selectionIndex.item -= 1
                }
                tableView(tableView, commit: .delete, forRowAt: selectionIndex)
            }
        }
    }

    private func updateConstraints() {
        tableView.snp.makeConstraints { (make) -> Void in
            make.edges.equalTo(view)
        }
        toolBar.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(view)
            make.right.equalTo(view)
            make.bottom.equalTo(view)
        }
    }
}

extension websiteSearchResultsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}
