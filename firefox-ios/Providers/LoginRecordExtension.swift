// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage
import AuthenticationServices

import struct MozillaAppServices.EncryptedLogin

extension LoginRecord {
    public var passwordCredentialIdentity: ASPasswordCredentialIdentity {
        let serviceIdentifier = ASCredentialServiceIdentifier(identifier: self.hostname, type: .URL)
        return ASPasswordCredentialIdentity(
            serviceIdentifier: serviceIdentifier,
            user: self.decryptedUsername,
            recordIdentifier: self.id
        )
    }

    public var passwordCredential: ASPasswordCredential {
        return ASPasswordCredential(user: self.decryptedUsername, password: self.decryptedPassword)
    }
}

extension LoginRecord: Swift.Comparable {
    public static func < (lhs: LoginRecord, rhs: LoginRecord) -> Bool {
        lhs.hostname.titleFromHostname < rhs.hostname.titleFromHostname
    }
}
