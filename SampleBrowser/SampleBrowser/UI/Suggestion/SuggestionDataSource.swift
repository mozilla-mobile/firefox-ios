// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class SuggestionDataSource: NSObject, UITableViewDataSource {
    var suggestions = [String]() {
        didSet {
            buildModels()
        }
    }

    var models = [SuggestionCellViewModel]()
    func buildModels() {
        models = []
        for suggestion in suggestions {
            models.append(SuggestionCellViewModel(title: suggestion))
        }
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SuggestionCell.identifier,
                                                       for: indexPath) as? SuggestionCell
        else {
            return UITableViewCell()
        }
        cell.configureCell(viewModel: models[indexPath.row])
        return cell
    }
}
