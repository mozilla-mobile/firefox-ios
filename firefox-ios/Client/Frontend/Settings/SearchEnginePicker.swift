// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class SearchEnginePicker: ThemedTableViewController {
    weak var delegate: SearchEnginePickerDelegate?
    var engines: [OpenSearchEngine] = []
    var selectedSearchEngineName: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = .SearchEnginePickerTitle
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: .SearchEnginePickerCancel,
            style: .plain,
            target: self,
            action: #selector(cancel)
        )
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return engines.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let engine = engines[indexPath.item]
        let cell = dequeueCellFor(indexPath: indexPath)
        cell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        cell.textLabel?.text = engine.shortName
        let size = CGSize(width: OpenSearchEngine.UX.preferredIconSize,
                          height: OpenSearchEngine.UX.preferredIconSize)
        cell.imageView?.image = engine.image.createScaled(size)
        if engine.shortName == selectedSearchEngineName {
            cell.accessoryType = .checkmark
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let engine = engines[indexPath.item]
        delegate?.searchEnginePicker(self, didSelectSearchEngine: engine)
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark

        NotificationCenter.default.post(name: .DefaultSearchEngineUpdated, object: self)
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }

    @objc
    func cancel() {
        delegate?.searchEnginePicker(self, didSelectSearchEngine: nil)
    }
}
