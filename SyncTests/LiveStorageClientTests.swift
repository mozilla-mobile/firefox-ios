/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Account
import Foundation
import FxA
import Shared
import Deferred
@testable import Sync

import XCTest
import SwiftyJSON

private class KeyFetchError: MaybeErrorType {
    var description: String {
        return "key fetch error"
    }
}

class LiveStorageClientTests: LiveAccountTest {
    func getKeys(kB: Data, token: TokenServerToken) -> Deferred<Maybe<Record<KeysPayload>>> {
        let endpoint = token.api_endpoint
        XCTAssertTrue(endpoint.range(of: "services.mozilla.com") != nil, "We got a Sync server.")

        let cryptoURI = URL(string: endpoint)
        let authorizer: Authorizer = {
            (r: URLRequest) -> URLRequest in
            var request = r
            let helper = HawkHelper(id: token.id, key: token.key.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
            request.addValue(helper.getAuthorizationValueFor(r), forHTTPHeaderField: "Authorization")
            return request
        }

        let keyBundle: KeyBundle = KeyBundle.fromKB(kB as Data)
        let encoder = RecordEncoder<KeysPayload>(decode: { KeysPayload($0) }, encode: { $0.json })
        let encrypter = Keys(defaultBundle: keyBundle).encrypter("crypto", encoder: encoder)

        let workQueue = DispatchQueue.global(qos: DispatchQoS.default.qosClass)
        let resultQueue = DispatchQueue.main
        let backoff = MockBackoffStorage()

        let storageClient = Sync15StorageClient(serverURI: cryptoURI!, authorizer: authorizer, workQueue: workQueue, resultQueue: resultQueue, backoff: backoff)
        let keysFetcher = storageClient.clientForCollection("crypto", encrypter: encrypter)

        return keysFetcher.get("keys").map({ res in
            // Unwrap the response.
            if let r = res.successValue {
                return Maybe(success: r.value)
            }
            return Maybe(failure: KeyFetchError())
        })
    }

    func getState(user: String, password: String) -> Deferred<Maybe<FxAState>> {
        let err: NSError = NSError(domain: FxAClientErrorDomain, code: 0, userInfo: nil)
        return Deferred(value: Maybe<FxAState>(failure: FxAClientError.local(err)))
    }

    func getTokenAndDefaultKeys() -> Deferred<Maybe<(TokenServerToken, KeyBundle)>> {
        let authState = self.syncAuthState(Date.now())

        let keysPayload: Deferred<Maybe<Record<KeysPayload>>> = authState.bind { tokenResult in
            if let (token, forKey) = tokenResult.successValue {
                return self.getKeys(kB: forKey, token: token)
            }
            XCTAssertEqual(tokenResult.failureValue!.description, "")
            return Deferred(value: Maybe(failure: KeyFetchError()))
        }

        let result = Deferred<Maybe<(TokenServerToken, KeyBundle)>>()
        keysPayload.upon { res in
            if let rec = res.successValue {
                XCTAssert(rec.id == "keys", "GUID is correct.")
                XCTAssert(rec.modified > 1000, "modified is sane.")
                let payload: KeysPayload = rec.payload as KeysPayload
                print("Body: \(payload.json.stringValue() ?? "nil")", terminator: "\n")
                XCTAssert(rec.id == "keys", "GUID inside is correct.")
                if let keys = payload.defaultKeys {
                    // Extracting the token like this is not great, but...
                    result.fill(Maybe(success: (authState.value.successValue!.token, keys)))
                    return
                }
            }

            result.fill(Maybe(failure: KeyFetchError()))
        }
        return result
    }

    func testLive() {
        let expctn = expectation(description: "Waiting on value.")
        let deferred = getTokenAndDefaultKeys()
        deferred.upon { res in
            if let (_, _) = res.successValue {
                print("Yay", terminator: "\n")
            } else {
                XCTAssertEqual(res.failureValue!.description, "")
            }
            expctn.fulfill()
        }

        // client: mgWl22CIzHiE
        waitForExpectations(timeout: 20) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }
    }

    func testStateMachine() {
        let expctn = expectation(description: "Waiting on value.")
        let authState = self.getAuthState(Date.now())

        let d = chainDeferred(authState, f: { SyncStateMachine(prefs: MockProfilePrefs()).toReady($0) })

        d.upon { result in
            if let ready = result.successValue {
                XCTAssertTrue(ready.collectionKeys.defaultBundle.encKey.count == 32)
                XCTAssertTrue(ready.scratchpad.global != nil)
                if let clients = ready.scratchpad.global?.value.engines["clients"] {
                    XCTAssertTrue(clients.syncID.characters.count == 12)
                }
            }
            XCTAssertTrue(result.isSuccess)
            expctn.fulfill()
        }

        waitForExpectations(timeout: 20) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }
    }
}
