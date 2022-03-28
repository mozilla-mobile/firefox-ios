// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class SearchBarSettingsViewController: SettingsTableViewController {

    private let viewModel: SearchBarSettingsViewModel

    init(viewModel: SearchBarSettingsViewModel) {
        self.viewModel = viewModel
        super.init(style: .grouped)
        
        title = viewModel.title
        viewModel.delegate = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        let showTop = viewModel.topSetting
        let showBottom = viewModel.bottomSetting
        let section = SettingSection(children: [showTop, showBottom])

        return [section]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .onDrag
    }
}

extension SearchBarSettingsViewController: SearchBarPreferenceDelegate {
    func didUpdateSearchBarPositionPreference() {
        tableView.reloadData()
    }
}
