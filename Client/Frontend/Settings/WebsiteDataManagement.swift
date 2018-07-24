/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import WebKit

private let SectionSites = 0
private let SectionShowMore = 1
private let SectionButton = 2
private let NumberOfSections = 3
private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"

class WebsiteDataManagement: UITableViewController {
    fileprivate var clearButton: UITableViewCell?
    fileprivate var showMoreButton: UITableViewCell?
    var showMoreButtonEnabled = true

    fileprivate typealias DefaultCheckedState = Bool
    let searchController = UISearchController(searchResultsController: nil)

    struct siteData {
        let dataOfSite: WKWebsiteDataRecord
        let nameOfSite: String

        init(dataOfSite: WKWebsiteDataRecord, nameOfSite: String){
            self.dataOfSite = dataOfSite
            self.nameOfSite = nameOfSite
        }
    }
    var siteRecords = [siteData]()
    let dataStore = WKWebsiteDataStore.default()
    let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()


    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup the Search Controller
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
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { (records) in
            for record in records {
                self.siteRecords.append(siteData(dataOfSite: record, nameOfSite: record.displayName))
            }
            self.siteRecords.sort { $0.nameOfSite < $1.nameOfSite }
            if self.siteRecords.count >= 5 {
                self.siteRecords.removeLast(self.siteRecords.count - 5)
            } else {
                self.showMoreButtonEnabled = false
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
            let site = siteRecords[indexPath.item]
            cell.textLabel?.text = site.nameOfSite
        } else if indexPath.section == SectionShowMore {
            assert(indexPath.section == SectionShowMore)
            cell.textLabel?.text = "Show More"
            cell.textLabel?.textColor = showMoreButtonEnabled ? UIColor.theme.general.highlightBlue : UIColor.gray
            cell.accessibilityTraits = UIAccessibilityTraitButton
            cell.accessibilityIdentifier = "ShowMoreWebsiteData"
            showMoreButton = cell

        } else {
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
            return siteRecords.count
        } else if section == SectionShowMore {
            return 1
        }
        assert(section == SectionButton)
        return 1
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if (indexPath.section == SectionShowMore && showMoreButtonEnabled) || indexPath.section == SectionButton {
            return true
        }
        return false
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SectionShowMore {
            //get websites
            siteRecords.removeAll()
            dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { (records) in
                for record in records {
                        self.siteRecords.append(siteData(dataOfSite: record, nameOfSite: record.displayName))
                }
                self.siteRecords.sort { $0.nameOfSite < $1.nameOfSite }
                self.showMoreButtonEnabled = false
                self.tableView.reloadData()
            }
        }
        guard indexPath.section == SectionButton else { return }
        if indexPath.section == SectionButton {
            WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: .distantPast, completionHandler: {})
            siteRecords.removeAll()
            showMoreButtonEnabled = false
            tableView.reloadData()
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section == SectionSites else { return false }
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            dataStore.removeData(ofTypes: dataTypes, for: [siteRecords[indexPath.item].dataOfSite], completionHandler: { return })
            siteRecords.remove(at: indexPath.item)
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
        if section != SectionShowMore {
            return SettingsUX.TableViewHeaderFooterHeight
        }
        return 0
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
