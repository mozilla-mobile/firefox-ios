// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

class ComponentDataSource: NSObject, UITableViewDataSource {
    var componentData = ComponentData()
    var theme: Theme = LightTheme()

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return componentData.data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ComponentCell.cellIdentifier)
        guard let cell = cell as? ComponentCell else { return UITableViewCell() }
        cell.setup(componentData.data[indexPath.row])
        cell.applyTheme(theme: theme)
        return cell
    }
}
