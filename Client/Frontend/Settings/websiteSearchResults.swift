//
//  websiteSearchResults.swift
//  Client
//
//  Created by Meera Rachamallu on 8/2/18.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import UIKit

private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"

class websiteSearchResults: UITableViewController {

    let flexible = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
    let editButton: UIBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(didPressEdit))
    let doneButton: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(didPressDone))
    let deleteButton: UIBarButtonItem = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(didPressDelete))
    private var myToolbar: UIToolbar!
    
    private var filteredSiteRecords = [String]()
    private var siteRecords : [siteData]
    var test = ["1", "2", "3"]
    init(data:[siteData]) {
        self.siteRecords = data
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.allowsMultipleSelectionDuringEditing = true
        //toolbar
        let border = CGRect(x: 0, y: 10.0, width: self.view.bounds.size.width, height: 40.0)
        myToolbar = UIToolbar(frame: border)
        myToolbar.layer.position = CGPoint(x: self.view.bounds.width/2, y: self.view.bounds.height-80.0)
        myToolbar.barStyle = .default
        myToolbar.items = [flexible, editButton]
        self.view.addSubview(myToolbar)

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
        return test.count//filteredSiteRecords.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let site = filteredSiteRecords[indexPath.item]
        cell.textLabel?.text = site//site.nameOfSite
        return cell
    }

//    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
//        if self.isEditing {
//            return true
//        }
//        return false
//    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            test.remove(at: indexPath.item)
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
        filteredSiteRecords = test//siteRecords.filter({( siteRecord : siteData) -> Bool in
            //return siteRecord.nameOfSite.lowercased().contains(searchText.lowercased())
       // })
        tableView.reloadData()
    }

    @objc func didPressEdit() {
        self.tableView.setEditing(true, animated: true)
        myToolbar.items = [deleteButton, flexible, doneButton]
    }

    @objc func didPressDone() {
        self.tableView.setEditing(false, animated: true)
        myToolbar.items = [flexible, editButton]
    }

    @objc func didPressDelete() {
        let selectedRows = self.tableView.indexPathsForSelectedRows
        if selectedRows != nil {
            for var selectionIndex in selectedRows! {
                while selectionIndex.item >= test.count {
                    selectionIndex.item -= 1
                }
                tableView(tableView, commit: .delete, forRowAt: selectionIndex)
            }
        }
    }
}

extension websiteSearchResults: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}



