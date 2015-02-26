/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SearchSettingsTableViewController: UITableViewController {
    private let SectionDefault = 0
    private let SectionOrder = 1

    var model: SearchEngines!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Search", comment: "Settings")

        // Temporary!
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Done", comment: "Settings"),
            style: UIBarButtonItemStyle.Done,
            target: navigationController, action: "SELdone")

        // To allow re-ordering the list of search engines at all times.
        tableView.editing = true
        // So that we push the default search engine controller on selection.
        tableView.allowsSelectionDuringEditing = true
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        var engine: OpenSearchEngine

        if indexPath.section == SectionDefault {
            engine = model.defaultEngine
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
            cell.editingAccessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        } else {
            engine = model.orderedEngines[indexPath.item]
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
            cell.showsReorderControl = true
        }

        // So that the seperator line goes all the way to the left edge.
        cell.separatorInset = UIEdgeInsetsZero

        cell.textLabel?.text = engine.shortName
        cell.imageView?.image = engine.image

        return cell
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SectionDefault {
            return 1
        } else {
            return model.orderedEngines.count
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == SectionDefault {
            return NSLocalizedString("Default", comment: "Search Settings")
        } else {
            return NSLocalizedString("Providers", comment: "Search Settings")
        }
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == SectionDefault {
            let searchEnginePicker = SearchEnginePicker()
            // Order alphabetically, so that picker is always consistently ordered.
            searchEnginePicker.engines = model.orderedEngines.sorted { e, f in e.shortName < f.shortName }
            searchEnginePicker.delegate = self
            navigationController?.pushViewController(searchEnginePicker, animated: true)
        }
        return nil
    }

    // Don't show delete button on the left.
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.None
    }

    // Don't reserve space for the delete button on the left.
    override func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    // Hide a thin vertical line that iOS renders between the accessoryView and the reordering control.
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if cell.editing {
            for v in cell.subviews as [UIView] {
                if v.frame.width == 1.0 {
                    v.backgroundColor = UIColor.clearColor()
                }
            }
        }
    }

    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == SectionDefault {
            return false
        } else {
            return true
        }
    }

    override func tableView(tableView: UITableView, moveRowAtIndexPath indexPath: NSIndexPath, toIndexPath newIndexPath: NSIndexPath) {
        let engine = model.orderedEngines.removeAtIndex(indexPath.item)
        model.orderedEngines.insert(engine, atIndex: newIndexPath.item)
        tableView.reloadData()
    }

    // Snap to first or last row of the list of engines.
    override func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        // You can't drag or drop on the default engine.
        if sourceIndexPath.section == SectionDefault || proposedDestinationIndexPath.section == SectionDefault {
            return sourceIndexPath
        }

        // The default engine is always the first row and cannot be moved.
        if sourceIndexPath.section == SectionOrder && sourceIndexPath.item == 0 {
            return sourceIndexPath
        }

        // Similarly, you can't displace the default engine from the first row.
        if proposedDestinationIndexPath.section == SectionOrder && proposedDestinationIndexPath.item == 0 {
            return sourceIndexPath
        }

        if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
            var row = 0
            if (sourceIndexPath.section < proposedDestinationIndexPath.section) {
                row = tableView.numberOfRowsInSection(sourceIndexPath.section) - 1
            }
            return NSIndexPath(forRow: row, inSection: sourceIndexPath.section)
        }


        return proposedDestinationIndexPath
    }

    func SELcancel() {
        navigationController?.popViewControllerAnimated(true)
    }
}

extension SearchSettingsTableViewController: SearchEnginePickerDelegate {
    func searchEnginePicker(searchEnginePicker: SearchEnginePicker, didSelectSearchEngine searchEngine: OpenSearchEngine?) {
        if let engine = searchEngine {
            model.defaultEngine = engine
            self.tableView.reloadData()
        }
        navigationController?.popViewControllerAnimated(true)
    }
}
