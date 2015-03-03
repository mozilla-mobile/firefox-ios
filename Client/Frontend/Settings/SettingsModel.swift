/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

protocol SettingsModelItem {
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
}

class SettingsModelSection {
    let title: String?
    let items: [SettingsModelItem]
    init(title: String?, items: [SettingsModelItem]) {
        self.title = title
        self.items = items
    }
}

class SettingsModel {
    let sections: [SettingsModelSection]
    init(sections: [SettingsModelSection]) {
        self.sections = sections
    }
}
