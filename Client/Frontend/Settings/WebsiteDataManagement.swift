/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import WebKit

private let SectionSites = 0
private let SectionButton = 1
private let NumberOfSections = 2
private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"

class WebsiteDataManagement: UITableViewController {
    fileprivate var clearButton: UITableViewCell?

    fileprivate typealias DefaultCheckedState = Bool
    let searchController = UISearchController(searchResultsController: nil)

    var websites: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup the Search Controller
        // searchController.searchResultsUpdater = self as! UISearchResultsUpdating
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter Sites"
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            // Fallback on earlier versions
        }
        definesPresentationContext = true

        title = Strings.SettingsWebsiteDataTitle

        //get websites
        let dataTypes = Set([WKWebsiteDataTypeCookies, WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeSessionStorage, WKWebsiteDataTypeWebSQLDatabases, WKWebsiteDataTypeIndexedDBDatabases])
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: dataTypes) { (records) in
            for record in records {
                self.websites.append(record.displayName)
//                if record.displayName.contains("cnn") {
//                    dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: [record], completionHandler: {
//                        print("Deleted: " + record.displayName);
//                    })
//                }
            }
            self.tableView.reloadData()
        }

        tableView.register(ThemedTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)

        tableView.separatorColor = UIColor.theme.tableView.separator
        tableView.backgroundColor = UIColor.theme.tableView.headerBackground
        let footer = ThemedTableSectionHeaderFooterView(frame: CGRect(width: tableView.bounds.width, height: SettingsUX.TableViewHeaderFooterHeight))
        footer.showBottomBorder = false
        tableView.tableFooterView = footer

        //edit feature
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)

        if indexPath.section == SectionSites {
            assert(indexPath.section == SectionSites)
            cell.textLabel?.text = websites[indexPath.item]
        }else {
            assert(indexPath.section == SectionButton)
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
        if section == SectionSites {
            return websites.count
        }
        assert(section == SectionButton)
        return 1

    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        //    guard indexPath.section == SectionButton else { return }
        if indexPath.section == SectionSites {
            print("hi")
        }
        if indexPath.section == SectionButton {
            clearprivatedata()
        }

        tableView.deselectRow(at: indexPath, animated: false)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section == SectionSites else { return false }
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            websites.remove(at: indexPath.item)
            tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderFooterIdentifier) as! ThemedTableSectionHeaderFooterView
        var sectionTitle: String?
        if section == SectionSites {
            sectionTitle = NSLocalizedString("WEBSITE DATA", comment: "Title for website data section.")
        } else {
            sectionTitle = nil
        }
        headerView.titleLabel.text = sectionTitle

        return headerView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return SettingsUX.TableViewHeaderFooterHeight
    }

    func clearprivatedata() {
        guard self.presentedViewController == nil else {
            return
        }
        let controller = AlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: "Clear All", style: .destructive, handler: { _ in
            print("Clear All")
        }), accessibilityIdentifier: "toolbarTabButtonLongPress.newTab")
        controller.addAction(UIAlertAction(title: "Clear Last Week", style: .destructive, handler: { _ in
            print("Clear Last Week")
        }), accessibilityIdentifier: "toolbarTabButtonLongPress.newPrivateTab")
        controller.addAction(UIAlertAction(title: "Clear Last Day", style: .destructive, handler: { _ in
            print("Clear Last Day")
        }), accessibilityIdentifier: "toolbarTabButtonLongPress.closeTab")
        controller.addAction(UIAlertAction(title: "Clear Last Hour", style: .destructive, handler: { _ in
            print("Clear Last Hour")
        }), accessibilityIdentifier: "toolbarTabButtonLongPress.closeTab")
        controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Label for Cancel button"), style: .cancel, handler: nil), accessibilityIdentifier: "toolbarTabButtonLongPress.cancel")
        //controller.popoverPresentationController?.sourceRect = button.frame
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        present(controller, animated: true, completion: nil)
    }

}
