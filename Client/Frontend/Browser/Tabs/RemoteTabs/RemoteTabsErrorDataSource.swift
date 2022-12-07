// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class RemoteTabsPanelErrorDataSource: NSObject, RemoteTabsPanelDataSource, ThemeApplicable {
    weak var remoteTabsPanel: RemoteTabsPanel?
    var error: RemoteTabsError
    private var theme: Theme

    init(remoteTabsPanel: RemoteTabsPanel,
         error: RemoteTabsError,
         theme: Theme) {
        self.remoteTabsPanel = remoteTabsPanel
        self.error = error
        self.theme = theme
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.height
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = RemoteTabsErrorCellViewModel(error: error)
        let cell = RemoteTabsErrorCell(viewModel: viewModel,
                                       theme: theme)
        cell.configure(delegate: remoteTabsPanel?.remotePanelDelegate)
        return cell
    }

    func applyTheme(theme: Theme) {
        self.theme = theme
    }
}
