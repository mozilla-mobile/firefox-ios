/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON
@testable import Sync

class MockBackoffStorage: BackoffStorage {
    var serverBackoffUntilLocalTimestamp: Timestamp?

    func clearServerBackoff() {
        serverBackoffUntilLocalTimestamp = nil
    }

    func isInBackoff(_ now: Timestamp) -> Timestamp? {
        return nil
    }
}

class MockSyncCollectionClient<T: CleartextPayloadJSON>: Sync15CollectionClient<T> {
    let uploader: BatchUploadFunction
    let infoConfig: InfoConfiguration

    init(uploader: @escaping BatchUploadFunction,
         infoConfig: InfoConfiguration,
         collection: String,
         encrypter: RecordEncrypter<T>,
         client: Sync15StorageClient = getClient(server: getServer(preStart: { _ in })),
         serverURI: URL = URL(string: "http://localhost/collections")!)
    {
        self.uploader = uploader
        self.infoConfig = infoConfig
        super.init(client: client, serverURI: serverURI, collection: collection, encrypter: encrypter)
    }
    
    override func newBatch(ifUnmodifiedSince: Timestamp? = nil, onCollectionUploaded: @escaping (POSTResult, Timestamp?) -> DeferredTimestamp) -> Sync15BatchClient<T> {
        let infoConfig = InfoConfiguration(maxRequestBytes: 1000,
                                           maxPostRecords: 10,
                                           maxPostBytes: 1000,
                                           maxTotalRecords: 10,
                                           maxTotalBytes: 1000)
        return Sync15BatchClient(config: infoConfig,
                                 ifUnmodifiedSince: ifUnmodifiedSince,
                                 serializeRecord: self.serializeRecord,
                                 uploader: self.uploader,
                                 onCollectionUploaded: onCollectionUploaded)
    }
}

// MARK: Various mocks

// Non-encrypting 'encrypter'.
func getEncrypter() -> RecordEncrypter<CleartextPayloadJSON> {
    let serializer: (Record<CleartextPayloadJSON>) -> JSON? = { $0.payload.json }
    let factory: (String) -> CleartextPayloadJSON = { CleartextPayloadJSON($0) }
    return RecordEncrypter(serializer: serializer, factory: factory)
}

func getClient(server: MockSyncServer) -> Sync15StorageClient {
    let url = server.baseURL.asURL!
    let authorizer: Authorizer = identity
    let queue = DispatchQueue.global(qos: DispatchQoS.background.qosClass)
    
    return Sync15StorageClient(serverURI: url, authorizer: authorizer, workQueue: queue, resultQueue: queue, backoff: MockBackoffStorage())
}

func getServer(username: String = "1234567", preStart: (MockSyncServer) -> Void) -> MockSyncServer {
    let server = MockSyncServer(username: username)
    preStart(server)
    server.start()
    return server
}
