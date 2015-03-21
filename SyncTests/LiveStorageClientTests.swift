/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import FxA
import Shared
import Account
import XCTest

private class KeyFetchError: ErrorType {
    var description: String {
        return "key fetch error"
    }
}

class LiveStorageClientTests : LiveAccountTest {
    func getToken(state: MarriedState) -> Deferred<Result<TokenServerToken>> {
        let audience = TokenServerClient.getAudienceForURL(ProductionSync15Configuration().tokenServerEndpointURL)
        let clientState = FxAClient10.computeClientState(state.kB)
        let client = TokenServerClient()
        println("Fetching token.")
        return client.token(state.generateAssertionForAudience(audience), clientState: clientState)
    }

    func getKeys(married: MarriedState, token: TokenServerToken) -> Deferred<Result<Record<KeysPayload>>> {
        let endpoint = token.api_endpoint
        XCTAssertTrue(endpoint.rangeOfString("services.mozilla.com") != nil, "We got a Sync server.")

        let cryptoURI = NSURL(string: endpoint + "/storage/")
        let authorizer: Authorizer = {
            (r: NSMutableURLRequest) -> NSMutableURLRequest in
            let helper = HawkHelper(id: token.id, key: token.key.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
            r.addValue(helper.getAuthorizationValueFor(r), forHTTPHeaderField: "Authorization")
            return r
        }

        let keyBundle: KeyBundle = KeyBundle.fromKB(married.kB)
        let f: (JSON) -> KeysPayload = {
            j in
            return KeysPayload(j)
        }
        let keysFactory: (String) -> KeysPayload? = Keys(defaultBundle: keyBundle).factory("keys", f)

        let workQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        let resultQueue = dispatch_get_main_queue()

        let storageClient = Sync15StorageClient(serverURI: cryptoURI!, authorizer: authorizer, workQueue: workQueue, resultQueue: resultQueue)
        let keysFetcher = storageClient.collectionClient("crypto", factory: keysFactory)

        return keysFetcher.get("keys").map({
            // Unwrap the response.
            res in
            if let r = res.successValue {
                return Result(success: r.value)
            }
            return Result(failure: KeyFetchError())
        })
    }

    func getState(user: String, password: String) -> Deferred<Result<FxAState>> {
        let err: NSError = NSError(domain: FxAClientErrorDomain, code: 0, userInfo: nil)
        return Deferred(value: Result<FxAState>(failure: FxAClientError.Local(err)))
    }

    func getTokenAndDefaultKeys() -> Deferred<Result<(TokenServerToken, KeyBundle)>> {
        let user = "holygoat+permatest@gmail.com"
        let state = getState(user, password: user)

        println("Got state.")
        let token = state.bind {
            (stateResult: Result<FxAState>) -> Deferred<Result<TokenServerToken>> in

            println("Got state bound.")
            if let s = stateResult.successValue as? MarriedState {

                println("Got state: \(s)")
                return self.getToken(s)
            } else {
                println("State wasn't successful. \(stateResult.failureValue)")
            }
            return Deferred(value: Result(failure: stateResult.failureValue!))
        }

        let keysPayload: Deferred<Result<Record<KeysPayload>>> = token.bind {
            tokenResult in
            if let married = state.value.successValue as? MarriedState {
                if let token = tokenResult.successValue {
                    return self.getKeys(married, token: token)
                }
            }
            return Deferred(value: Result(failure: KeyFetchError()))
        }

        let result = Deferred<Result<(TokenServerToken, KeyBundle)>>()
        keysPayload.upon {
            res in
            if let rec = res.successValue {
                XCTAssert(rec.id == "keys", "GUID is correct.")
                XCTAssert(rec.modified > 1000, "modified is sane.")
                let payload: KeysPayload = rec.payload as KeysPayload
                println("Body: \(payload.toString(pretty: false))")
                XCTAssert(rec.id == "keys", "GUID inside is correct.")
                let arr = payload["default"].asArray![0].asString
                if let keys = payload.defaultKeys {
                    result.fill(Result(success: (token.value.successValue!, keys)))
                    return
                }
            }

            result.fill(Result(failure: KeyFetchError()))
        }
        return result
    }

    func testLive() {
        let expectation = expectationWithDescription("Waiting on value.")
        let deferred = getTokenAndDefaultKeys()
        deferred.upon {
            res in
            /*
            if let (token, keyBundle) = res.successValue {
                println("Yay")
            } else {
                XCTFail("Couldn't get keys etc.")
            }
            */
            expectation.fulfill()
        }

        // client: mgWl22CIzHiE
        waitForExpectationsWithTimeout(20) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }
}