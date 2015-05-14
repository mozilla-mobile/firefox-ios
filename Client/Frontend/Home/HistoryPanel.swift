/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

import Shared
import Storage

private func getDate(#dayOffset: Int) -> NSDate {
    let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    let nowComponents = calendar.components(NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitDay, fromDate: NSDate())
    let today = calendar.dateFromComponents(nowComponents)!
    return calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitDay, value: dayOffset, toDate: today, options: nil)!
}

class HistoryPanel: SiteTableViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate? = nil

    private let NumSections = 4
    private let Today = getDate(dayOffset: 0)
    private let Yesterday = getDate(dayOffset: -1)
    private let ThisWeek = getDate(dayOffset: -7)

    private var sectionOffsets = [Int: Int]()

    private lazy var defaultIcon: UIImage = {
        return UIImage(named: "defaultFavicon")!
    }()

    private func refetchData() -> Deferred<Result<Cursor<Site>>> {
        return profile.history.getSitesByLastVisit(100)
    }

    private func setData(data: Cursor<Site>) {
        self.sectionOffsets = [Int: Int]()
        self.data = data
    }

    override func reloadData() {
        self.refetchData().uponQueue(dispatch_get_main_queue()) { result in
            if let data = result.successValue {
                self.setData(data)
                self.tableView.reloadData()
            }
            // TODO: error handling.
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        let offset = sectionOffsets[indexPath.section]!
        if let site = data[indexPath.row + offset] {
            if let cell = cell as? TwoLineTableViewCell {
                cell.setLines(site.title, detailText: site.url)
                cell.imageView?.setIcon(site.icon, withPlaceholder: self.defaultIcon)
            }
        }

        return cell
    }

    private func siteForIndexPath(indexPath: NSIndexPath) -> Site? {
        let offset = sectionOffsets[indexPath.section]!
        return data[indexPath.row + offset]
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let site = self.siteForIndexPath(indexPath) {
            if let url = NSURL(string: site.url) {
                homePanelDelegate?.homePanel(self, didSelectURL: url)
                return
            }
        }
        println("Could not click on history row")
    }

    // Functions that deal with showing header rows
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return NumSections
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title = String()
        switch section {
        case 0: title = NSLocalizedString("Today", comment: "History tableview section header")
        case 1: title = NSLocalizedString("Yesterday", comment: "History tableview section header")
        case 2: title = NSLocalizedString("Last week", comment: "History tableview section header")
        case 3: title = NSLocalizedString("Last month", comment: "History tableview section header")
        default:
            assertionFailure("Invalid history section \(section)")
        }
        return title.uppercaseString
    }

    private func isInSection(date: MicrosecondTimestamp, section: Int) -> Bool {
        let date = Double(date)
        switch section {
        case 0:
            return date > (1000000 * Today.timeIntervalSince1970)
        case 1:
            return date > (1000000 * Yesterday.timeIntervalSince1970)
        case 2:
            return date > (1000000 * ThisWeek.timeIntervalSince1970)
        default:
            return true
        }
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let current = sectionOffsets[section] {
            if let next = sectionOffsets[section+1] {
                if current == next {
                    // If this points to the same element as the next one, it's empty. Don't show it.
                    return 0
                }
            }
        } else {
            // This may not be filled in yet (for instance, if the number of rows in data is zero). If it is,
            // just return zero.
            return 0
        }

        // Return the default height for header rows
        return super.tableView(tableView, heightForHeaderInSection: section)
    }


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let size = sectionOffsets[section] {
            if let nextSize = sectionOffsets[section+1] {
                return nextSize - size
            }
        }

        var searchingSection = 0
        sectionOffsets[searchingSection] = 0

        // Loop over all the data. Record the start of each "section" of our list.
        for i in 0..<data.count {
            if let site = data[i] {
                if !isInSection(site.latestVisit!.date, section: searchingSection) {
                    searchingSection++
                    sectionOffsets[searchingSection] = i
                }

                if searchingSection == NumSections {
                    break
                }
            }
        }

        // Now fill in any sections that weren't found with data.count.
        // Note, we actually fill in one past the end of the list to make finding the length
        // of a section easier.
        searchingSection++
        for i in searchingSection...NumSections {
            sectionOffsets[i] = data.count
        }

        // This function wants the size of a section, so return the distance between two adjacent ones
        return sectionOffsets[section+1]! - sectionOffsets[section]!
    }


    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let title = NSLocalizedString("Remove", tableName: "HistoryPanel", comment: "Action button for deleting history entries in the bookmarks panel.")

        let delete = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: title, handler: { (action, indexPath) in
            if let site = self.siteForIndexPath(indexPath) {
                // Why the dispatches? Because we call success and failure on the DB
                // queue, and so calling anything else that calls through to the DB will
                // deadlock. This problem will go away when the bookmarks API switches to
                // Deferred instead of using callbacks.
                self.profile.history.removeHistoryForURL(site.url).uponQueue(dispatch_get_main_queue()) { success in
                    self.refetchData().uponQueue(dispatch_get_main_queue()) { result in
                        if let data = result.successValue {
                            self.setData(data)
                        }

                        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
                    }
                }
            }
        })

        return [delete]
    }
}
