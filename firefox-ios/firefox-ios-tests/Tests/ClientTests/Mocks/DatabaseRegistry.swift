// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

protocol Reopenable: AnyObject {
    associatedtype LifecycleResult

    func reopenIfClosed() -> LifecycleResult
    func forceClose() -> LifecycleResult
}

extension RustPlaces: Reopenable {}
extension RustLogins: Reopenable {}
extension RustRemoteTabs: Reopenable {}
extension RustAutofill: Reopenable {}
extension BrowserDB: Reopenable {}

/// Keeps every tracked database in one shared open-or-closed state.
final class DatabaseRegistry: @unchecked Sendable {
    private enum State {
        case open
        case closed
    }

    private let lock = NSLock()
    private var state = State.open
    private var databases: [any Reopenable] = []

    var isShutdown: Bool {
        lock.lock()
        defer { lock.unlock() }
        return state == .closed
    }

    /// Databases are called outside the lock: opening and closing run `queue.sync` on the database's
    /// own queue, and work already on that queue may touch another lazy database and need this lock.
    @discardableResult
    func trackLifecycle<Database: Reopenable>(of database: Database) -> Database {
        lock.lock()
        databases.append(database)
        let state = self.state
        lock.unlock()
        update(database, for: state)
        return database
    }

    func reopen() {
        update(to: .open)
    }

    func shutdown() {
        update(to: .closed)
    }

    private func update(to state: State) {
        lock.lock()
        self.state = state
        let databases = self.databases
        lock.unlock()
        databases.forEach { update($0, for: state) }
    }

    private func update(_ database: any Reopenable, for state: State) {
        switch state {
        case .open:
            _ = database.reopenIfClosed()
        case .closed:
            _ = database.forceClose()
        }
    }
}
