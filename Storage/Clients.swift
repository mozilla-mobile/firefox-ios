/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

public protocol Clients {
    init(files: FileAccessor)

    // The public API, usable by the frontend.
    func getAll() -> Deferred<[RemoteClient]>
    func get(guid: String) -> Deferred<RemoteClient?>

    // The API for Sync.
    func storeClient(client: RemoteClient)
    func wipe()
}

public class MockClients: Clients {
    required public init(files: FileAccessor) {
    }

    // The public API, usable by the frontend.
    public func getAll() -> Deferred<[RemoteClient]> {
        return Deferred(value: [])
    }

    public func get(guid: String) -> Deferred<RemoteClient?> {
        return Deferred(value: nil)
    }

    // The API for Sync.
    public func storeClient(client: RemoteClient) {}
    public func wipe() {}
}