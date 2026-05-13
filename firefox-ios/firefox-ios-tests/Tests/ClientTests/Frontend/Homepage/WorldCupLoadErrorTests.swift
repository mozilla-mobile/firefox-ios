// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing
import Foundation
import MozillaAppServices
@testable import Client

@Suite("WorldCupLoadError mapping")
struct WorldCupLoadErrorTests {
    @Test
    func test_mapsFfiNetworkError() {
        let ffi = MerinoWorldCupApiError.Network(reason: "offline")
        let mapped = WorldCupLoadError.from(ffi)
        #expect(mapped == .network(reason: "offline"))
    }

    @Test
    func test_mapsFfiOtherError_withHttpCode() {
        let ffi = MerinoWorldCupApiError.Other(code: 503, reason: "service unavailable")
        let mapped = WorldCupLoadError.from(ffi)
        #expect(mapped == .other(code: 503, reason: "service unavailable"))
    }

    @Test
    func test_mapsFfiOtherError_withNoCode() {
        let ffi = MerinoWorldCupApiError.Other(code: nil, reason: "validation failure")
        let mapped = WorldCupLoadError.from(ffi)
        #expect(mapped == .other(code: nil, reason: "validation failure"))
    }

    @Test
    func test_mapsUnknownError_toOther() {
        let mapped = WorldCupLoadError.from(MockWorldCupClientError.network)
        #expect(mapped == .other(code: nil, reason: "network"))
    }
}
