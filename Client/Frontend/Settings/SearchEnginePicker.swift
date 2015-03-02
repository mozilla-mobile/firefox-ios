/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol SearchEnginePickerDelegate {
    func searchEnginePicker(searchEnginePicker: SearchEnginePicker, didSelectSearchEngine engine: OpenSearchEngine?) -> Void
}

class SearchEnginePicker: UITableViewController {
    var delegate: SearchEnginePickerDelegate?
    var engines: [OpenSearchEngine]!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Search Default", comment: "Settings")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "SELcancel")
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return engines.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let engine = engines[indexPath.item]
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        cell.textLabel?.text = engine.shortName
        cell.imageView?.image = engine.image
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let engine = engines[indexPath.item]
        delegate?.searchEnginePicker(self, didSelectSearchEngine: engine)
    }

    func SELcancel() {
        delegate?.searchEnginePicker(self, didSelectSearchEngine: nil)
    }
}
