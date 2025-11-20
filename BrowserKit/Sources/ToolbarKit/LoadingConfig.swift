// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

public struct LoadingConfig: Equatable, Sendable {
    public let isLoading: Bool
    let a11yLabel: String

    public init(isLoading: Bool, a11yLabel: String) {
        self.isLoading = isLoading
        self.a11yLabel = a11yLabel
    }
}
