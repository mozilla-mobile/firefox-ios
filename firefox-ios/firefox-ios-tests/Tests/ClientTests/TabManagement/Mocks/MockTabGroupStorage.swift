// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

actor MockTabGroupStorage: TabGroupStorage {
    enum Failure: Error { case load, save }
    var snapshot = TabGroupSnapshot()
    var savedSnapshots: [TabGroupSnapshot] = []
    var loadCount = 0
    var failLoad = false
    var failSave = false
    private var pauseSave = false
    private var saveContinuation: CheckedContinuation<Void, Never>?
    private var saveStarted: CheckedContinuation<Void, Never>?

    func setSnapshot(_ snapshot: TabGroupSnapshot) { self.snapshot = snapshot }
    func setFailure(load: Bool = false, save: Bool = false) {
        failLoad = load
        failSave = save
    }
    func suspendNextSave() { pauseSave = true }

    func waitUntilSaving() async {
        if saveContinuation != nil { return }
        await withCheckedContinuation { saveStarted = $0 }
    }

    func resumeSave() {
        saveContinuation?.resume()
        saveContinuation = nil
    }

    func load() throws -> TabGroupSnapshot {
        loadCount += 1
        if failLoad { throw Failure.load }
        return snapshot
    }

    func save(_ snapshot: TabGroupSnapshot) async throws {
        if pauseSave {
            pauseSave = false
            await withCheckedContinuation {
                saveContinuation = $0
                saveStarted?.resume()
                saveStarted = nil
            }
        }
        if failSave { throw Failure.save }
        self.snapshot = snapshot
        savedSnapshots.append(snapshot)
    }
}
