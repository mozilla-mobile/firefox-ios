// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Auth0

/// A protocol for managing authentication credentials.
public protocol CredentialsManagerProtocol {

    /// Stores the provided credentials securely.
    ///
    /// - Parameter credentials: The credentials to store.
    /// - Returns: A boolean indicating whether the credentials were successfully stored.
    @discardableResult
    func store(credentials: Credentials) -> Bool

    /// Retrieves stored credentials asynchronously.
    ///
    /// - Returns: The stored `Credentials` object if available.
    /// - Throws: An error if retrieving credentials fails.
    func credentials() async throws -> Credentials

    /// Clears stored credentials.
    ///
    /// - Returns: A boolean indicating whether the credentials were successfully cleared.
    @discardableResult
    func clear() -> Bool

    /// Checks if stored credentials can be renewed.
    ///
    /// - Returns: A boolean indicating if credentials are renewable.
    func canRenew() -> Bool

    /// Renews credentials asynchronously if possible.
    ///
    /// - Returns: A `Credentials` object upon successful renewal.
    /// - Throws: An error if the credential renewal fails.
    func renew() async throws -> Credentials
}
