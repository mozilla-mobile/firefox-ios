// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import StoreKit.SKAdNetwork

#if os(iOS)

public protocol SKAdNetworkProtocol {
    @available(iOS, introduced: 11.3, deprecated: 15.4)
    static func registerAppForAdNetworkAttribution()
    @available(iOS, introduced: 14.0, deprecated: 15.4)
    static func updateConversionValue(_ conversionValue: Int)
    @available(iOS 15.4, *)
    static func updatePostbackConversionValue(_ conversionValue: Int) async throws
    @available(iOS 16.1, *)
    static func updatePostbackConversionValue(_ fineValue: Int, coarseValue: Int?, lockWindow: Bool) async throws
}

extension SKAdNetwork: SKAdNetworkProtocol {
    @available(iOS 16.1, *)
    public static func updatePostbackConversionValue(_ fineValue: Int, coarseValue: Int?, lockWindow: Bool) async throws {
        var coarseConversionValue: CoarseConversionValue?
        switch coarseValue {
        case 0: coarseConversionValue = .low
        case 1: coarseConversionValue = .medium
        case 2: coarseConversionValue = .high
        default: break
        }
        if let value = coarseConversionValue {
            try await updatePostbackConversionValue(fineValue, coarseValue: value, lockWindow: lockWindow)
        } else {
            try await updatePostbackConversionValue(fineValue)
        }
    }
}

#endif
