// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct PrivateLockDomainState: Equatable {
    enum PrivateAccessState: Equatable {
        case locked
        case unlocked
    }

    enum PrivateAuthState: Equatable {
        case idle
        case authenticating
        case failed
    }

    var access: PrivateAccessState = .locked
    var auth: PrivateAuthState = .idle
    var lastUnlockedAt: Date?
    let relockInterval: TimeInterval = 120

    var shouldRelockByTime: Bool {
        guard let lastUnlockedAt else { return true }
        return Date().timeIntervalSince(lastUnlockedAt) > relockInterval
    }

    func copy(access: PrivateAccessState? = nil,
              auth: PrivateAuthState? = nil,
              lastUnlockedAt: Date? = nil) -> PrivateLockDomainState {
        PrivateLockDomainState(access: access ?? self.access,
                               auth: auth ?? self.auth,
                               lastUnlockedAt: lastUnlockedAt ?? self.lastUnlockedAt)
    }

    func locked() -> PrivateLockDomainState {
        copy(access: .locked)
    }

    func withLastUnlocked(at: Date?) -> PrivateLockDomainState {
        PrivateLockDomainState(access: access, auth: auth, lastUnlockedAt: at)
    }
}
