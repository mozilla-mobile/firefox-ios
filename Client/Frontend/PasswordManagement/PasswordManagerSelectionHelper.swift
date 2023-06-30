// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

/// Helper that keeps track of selected login records cells for PasswordManagerListViewController
class PasswordManagerSelectionHelper {
    /// The key represents a unique identifier for the cell, composed with the hostname interpolated with user name
    private(set) var selectionCellsState: [String: Bool] = [:]

    var numberOfSelectedCells: Int {
        selectionCellsState.keys.count
    }

    func setCellSelected(with loginRecord: LoginRecord) {
        let key = getKeyFromLoginRecord(loginRecord)
        selectionCellsState[key] = true
    }

    func removeCell(with loginRecord: LoginRecord) {
        let key = getKeyFromLoginRecord(loginRecord)
        _ = selectionCellsState.removeValue(forKey: key)
    }

    func removeAllCells() {
        selectionCellsState.removeAll()
    }

    func isCellSelected(with loginRecord: LoginRecord) -> Bool {
        let key = getKeyFromLoginRecord(loginRecord)
        return selectionCellsState[key] ?? false
    }

    private func getKeyFromLoginRecord(_ loginRecord: LoginRecord) -> String {
        "\(loginRecord.hostname)\(loginRecord.decryptedUsername)"
    }
}
