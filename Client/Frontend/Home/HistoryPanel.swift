/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

import Shared
import Storage
import XCGLogger

private let log = XCGLogger.defaultInstance()

private func getDate(#dayOffset: Int) -> NSDate {
    let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    let nowComponents = calendar.components(NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitDay, fromDate: NSDate())
    let today = calendar.dateFromComponents(nowComponents)!
    return calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitDay, value: dayOffset, toDate: today, options: nil)!
}

private typealias SectionNumber = Int
private typealias CategoryNumber = Int
private typealias CategorySpec = (section: SectionNumber?, rows: Int, offset: Int)

class HistoryPanel: SiteTableViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate? = nil

    private let NumSections = 4
    private let Today = getDate(dayOffset: 0)
    private let Yesterday = getDate(dayOffset: -1)
    private let ThisWeek = getDate(dayOffset: -7)

    // Category number (index) -> (UI section, row count, cursor offset).
    private var categories: [CategorySpec] = [CategorySpec]()

    // Reverse lookup from UI section to data category.
    private var sectionLookup = [SectionNumber: CategoryNumber]()

    private lazy var defaultIcon: UIImage = {
        return UIImage(named: "defaultFavicon")!
    }()

    var refreshControl: UIRefreshControl?

    override func viewDidLoad() {
        super.viewDidLoad()

        let refresh = UIRefreshControl()
        refresh.attributedTitle = NSAttributedString(string: NSLocalizedString("Pull to Sync", comment: "The pull-to-refresh string for syncing in the history panel."))
        refresh.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refresh
        self.tableView.addSubview(refresh)
    }

    @objc func refresh() {
        self.refreshControl?.beginRefreshing()
        profile.syncManager.syncHistory().uponQueue(dispatch_get_main_queue()) { result in
            if result.isSuccess {
                self.reloadData()
            }
        }
    }

    private func refetchData() -> Deferred<Result<Cursor<Site>>> {
        return profile.history.getSitesByLastVisit(100)
    }

    private func setData(data: Cursor<Site>) {
        self.data = data
        self.computeSectionOffsets()
    }

    override func reloadData() {
        self.refetchData().uponQueue(dispatch_get_main_queue()) { result in
            if let data = result.successValue {
                self.setData(data)
                self.tableView.reloadData()
            }

            // Always end refreshing, even if we failed!
            self.refreshControl?.endRefreshing()

            // TODO: error handling.
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        let category = self.categories[indexPath.section]
        if let site = data[indexPath.row + category.offset] {
            if let cell = cell as? TwoLineTableViewCell {
                cell.setLines(site.title, detailText: site.url)
                cell.imageView?.setIcon(site.icon, withPlaceholder: self.defaultIcon)
            }
        }

        return cell
    }

    private func siteForIndexPath(indexPath: NSIndexPath) -> Site? {
        let offset = self.categories[sectionLookup[indexPath.section]!].offset
        return data[indexPath.row + offset]
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let site = self.siteForIndexPath(indexPath),
           let url = NSURL(string: site.url) {
            let visitType = VisitType.Typed    // Means History, too.
            homePanelDelegate?.homePanel(self, didSelectURL: url, visitType: visitType)
            return
        }
        log.warning("No site or no URL when selecting row.")
    }

    // Functions that deal with showing header rows.
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var count = 0
        for category in self.categories {
            if category.rows > 0 {
                count++
            }
        }
        return count
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title = String()
        switch sectionLookup[section]! {
        case 0: title = NSLocalizedString("Today", comment: "History tableview section header")
        case 1: title = NSLocalizedString("Yesterday", comment: "History tableview section header")
        case 2: title = NSLocalizedString("Last week", comment: "History tableview section header")
        case 3: title = NSLocalizedString("Last month", comment: "History tableview section header")
        default:
            assertionFailure("Invalid history section \(section)")
        }
        return title.uppercaseString
    }

    func categoryForDate(date: MicrosecondTimestamp) -> Int {
        let date = Double(date)
        if date > (1000000 * Today.timeIntervalSince1970) {
            return 0
        }
        if date > (1000000 * Yesterday.timeIntervalSince1970) {
            return 1
        }
        if date > (1000000 * ThisWeek.timeIntervalSince1970) {
            return 2
        }
        return 3
    }

    private func isInCategory(date: MicrosecondTimestamp, category: Int) -> Bool {
        return self.categoryForDate(date) == category
    }

    func computeSectionOffsets() {
        var counts = [Int](count: NumSections, repeatedValue: 0)

        // Loop over all the data. Record the start of each "section" of our list.
        for i in 0..<data.count {
            if let site = data[i] {
                counts[categoryForDate(site.latestVisit!.date)]++
            }
        }

        var section = 0
        var offset = 0
        self.categories = [CategorySpec]()
        for i in 0..<NumSections {
            let count = counts[i]
            if count > 0 {
                log.debug("Category \(i) has \(count) rows, and thus is section \(section).")
                self.categories.append((section: section, rows: count, offset: offset))
                sectionLookup[section] = i
                offset += count
                section++
            } else {
                log.debug("Category \(i) has 0 rows, and thus has no section.")
                self.categories.append((section: nil, rows: 0, offset: offset))
            }
        }
    }

    // UI sections disappear as categories empty. We need to translate back and forth.
    private func uiSectionToCategory(section: SectionNumber) -> CategoryNumber {
        for i in 0..<self.categories.count {
            if let s = self.categories[i].section where s == section {
                return i
            }
        }
        return 0
    }

    private func categoryToUISection(category: CategoryNumber) -> SectionNumber? {
        return self.categories[category].section
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.categories[uiSectionToCategory(section)].rows
    }


    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let title = NSLocalizedString("Remove", tableName: "HistoryPanel", comment: "Action button for deleting history entries in the history panel.")

        let delete = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: title, handler: { (action, indexPath) in
            if let site = self.siteForIndexPath(indexPath) {
                // Compute the section in advance -- if we try to do this below, naturally the category
                // will be empty, and so there will be no section in the CategorySpec!
                let category = self.categoryForDate(site.latestVisit!.date)
                let section = self.categoryToUISection(category)!

                // Why the dispatches? Because we call success and failure on the DB
                // queue, and so calling anything else that calls through to the DB will
                // deadlock. This problem will go away when the history API switches to
                // Deferred instead of using callbacks.
                self.profile.history.removeHistoryForURL(site.url)
                    .upon { res in
                        self.refetchData().uponQueue(dispatch_get_main_queue()) { result in

                            // If a section will be empty after removal, we must remove the section itself.
                            if let data = result.successValue {
                                tableView.beginUpdates()
                                self.data = data
                                self.computeSectionOffsets()

                                let spec = self.categories[category]
                                if spec.rows == 0 {
                                    // Remove the section. Sections can't be empty.
                                    self.tableView.deleteSections(NSIndexSet(index: section), withRowAnimation: UITableViewRowAnimation.Left)
                                } else {
                                    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
                                }

                                tableView.endUpdates()
                            }
                        }
                }
            }
        })
        return [delete]
    }
}
