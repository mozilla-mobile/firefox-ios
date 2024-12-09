// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol UIApplicationInterface {
    @available(iOS 18.2, *)
    @available(visionOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @MainActor
    @preconcurrency
    func isDefault(_ category: UIApplication.Category) throws -> Bool
}

extension UIApplication: UIApplicationInterface {}
