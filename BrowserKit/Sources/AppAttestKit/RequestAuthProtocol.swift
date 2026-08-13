// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A strategy responsible for applying authentication information
/// to an outgoing URLRequest.
///
/// Conforming types may mutate headers or other request properties
/// and are allowed to perform asynchronous work (e.g. token refresh).
public protocol RequestAuthProtocol: Sendable {
    func authenticate(request: inout URLRequest) async throws
}
