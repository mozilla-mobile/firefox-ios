//
//  websiteSearchResultsViewController.swift
//  Client
//
//  Created by Meera Rachamallu on 8/2/18.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import UIKit

private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"

class websiteSearchResultsViewController: UITableViewController {

    let flexible = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
    let editButton: UIBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(didPressEdit))
    let doneButton: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(didPressDone))
    let deleteButton: UIBarButtonItem = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(didPressDelete))
    private var toolBar: UIToolbar!
    
    private var filteredSiteRecords = [siteData]()
    var siteRecords = [siteData]()

//    init(data:[siteData]) {
//        self.siteRecords = data
//        super.init(nibName: nil, bundle: nil)
//    }
//
//    required init(coder: NSCoder) {
//        fatalError("NSCoding not supported")
//    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.allowsMultipleSelectionDuringEditing = true
        self.navigationController?.setToolbarHidden(false, animated: false)
        //toolbar
        let border = CGRect(x: 0, y: 10.0, width: self.view.bounds.size.width, height: 44.0)
        toolBar = UIToolbar(frame: border)
        toolBar.layer.position = CGPoint(x: self.view.bounds.width/2, y: self.view.bounds.height-88.0)
        toolBar.barStyle = .default
        toolBar.items = [flexible, editButton]
        self.view.addSubview(toolBar)

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredSiteRecords.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let site = filteredSiteRecords[indexPath.item]
        cell.textLabel?.text = site.nameOfSite
        return cell
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if self.tableView.isEditing {
            return true
        }
        return false
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            dataStore.removeData(ofTypes: dataTypes, for: [filteredSiteRecords[indexPath.item].dataOfSite], completionHandler: { return })
            filteredSiteRecords.remove(at: indexPath.item)
            tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderFooterIdentifier) as! ThemedTableSectionHeaderFooterView
        return headerView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return SettingsUX.TableViewHeaderFooterHeight
    }

    func filterContentForSearchText(_ searchText: String) {
        filteredSiteRecords = siteRecords.filter({( siteRecord : siteData) -> Bool in
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
}

extension websiteSearchResultsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}



