// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@MainActor
protocol VPNControllerProtocol {
    var isRunning: Bool { get }
    func start(privateOnly: Bool, completion: @escaping (Result<Void, Error>) -> Void)
    func stop()
}

enum VPNError: Error {
    case unsupportedOS    // used by StubVPNController on iOS < 17
    case notSignedIn      // used by VPNController's FxA mint strategy
    case noServerFound    // Thrown when the Selected Server was not dound
}

@MainActor
final class StubVPNController: VPNControllerProtocol {
    var isRunning: Bool { false }
    func start(privateOnly: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.failure(VPNError.unsupportedOS))
    }
    func stop() {}
}
