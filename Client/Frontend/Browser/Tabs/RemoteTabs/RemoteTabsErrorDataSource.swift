// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class RemoteTabsErrorDataSource: NSObject, RemoteTabsPanelDataSource, ThemeApplicable {
    enum ErrorType {
        case notLoggedIn
        case noClients
        case noTabs
        case failedToSync
        case syncDisabledByUser

        func localizedString() -> String {
            switch self {
            case .notLoggedIn: return .EmptySyncedTabsPanelNotSignedInStateDescription
            case .noClients: return .EmptySyncedTabsPanelNullStateDescription
            case .noTabs: return .RemoteTabErrorNoTabs
            case .failedToSync: return .RemoteTabErrorFailedToSync
            case .syncDisabledByUser: return .TabsTray.Sync.SyncTabsDisabled
            }
        }
    }

    weak var remoteTabsPanel: RemoteTabsPanel?
    var error: ErrorType
    private var theme: Theme

    init(remoteTabsPanel: RemoteTabsPanel,
         error: ErrorType,
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
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RemoteTabsErrorCell.cellIdentifier,
                                                       for: indexPath) as? RemoteTabsErrorCell
        else {
            return UITableViewCell()
        }

        tableView.separatorStyle = .none
        cell.configure(error: error,
                       theme: theme,
                       delegate: remoteTabsPanel?.remotePanelDelegate)
        return cell
    }

    func applyTheme(theme: Theme) {
        self.theme = theme
    }
}
