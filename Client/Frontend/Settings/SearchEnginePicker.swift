/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SearchEnginePicker: UITableViewController {
    var delegate: SearchEnginePickerDelegate?
    var engines: [OpenSearchEngine]!
    var selectedSearchEngineName: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Default Search Engine", comment: "Title for default search engine picker.")
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: "Cancel title from search engine picker"), style: .Plain, target: self, action: #selector(SearchEnginePicker.SELcancel))
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return engines.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let engine = engines[indexPath.item]
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        cell.textLabel?.text = engine.shortName
        cell.imageView?.image = engine.image?.createScaled(CGSize(width: OpenSearchEngine.PreferredIconSize, height: OpenSearchEngine.PreferredIconSize))
        if engine.shortName == selectedSearchEngineName {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let engine = engines[indexPath.item]
        delegate?.searchEnginePicker(self, didSelectSearchEngine: engine)
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
    }

    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
    }

    func SELcancel() {
        delegate?.searchEnginePicker(self, didSelectSearchEngine: nil)
    }
}
