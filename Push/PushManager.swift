/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Deferred
import Shared

public class PushManager {

    let client: PushClient

    convenience init(endpointURL: NSURL) {
        self.init(client: PushClient(endpointURL: endpointURL))
    }

    init(client: PushClient) {
        self.client = client
    }

    public func register(apnsToken: String) -> Deferred<Maybe<PushRegistration>> {
        if let creds = getCredentials() {
            return client.updateUAID(apnsToken, creds: creds) >>> { deferMaybe(creds) }
        } else {
            return client.registerUAID(apnsToken) >>== { creds in
                self.storeCredentials(creds)
                return deferMaybe(creds)
            }
        }
    }

    public func unregister() -> Success {
        guard let creds = getCredentials() else {
            return succeed()
        }

        return client.unregister(creds)
    }

}

extension PushManager {
    private func getCredentials() -> PushRegistration? {
        return nil
    }

    private func storeCredentials(creds: PushRegistration) {
        // TODO
    }

    private func deleteCredentials() {
        // TODO
    }
}
