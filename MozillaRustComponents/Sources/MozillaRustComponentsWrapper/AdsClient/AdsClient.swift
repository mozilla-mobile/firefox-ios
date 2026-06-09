// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean


// There is already a class AdsClient in FxAClient so we need to use a different name here.
public struct RustAdsClient {
    public static let production: MozAdsClient = {
        let cacheConfig = MozAdsCacheConfig(dbPath: getDatabaseURL(environment: .prod), defaultCacheTtlSeconds: nil, maxSizeMib: nil)
        return MozAdsClientBuilder()
            .environment(environment: .prod)
            .cacheConfig(cacheConfig: cacheConfig)
            .telemetry(telemetry: AdsClientTelemetry())
            .build()
    }()

    public static let staging: MozAdsClient = {
        let cacheConfig = MozAdsCacheConfig(dbPath: getDatabaseURL(environment: .staging), defaultCacheTtlSeconds: nil, maxSizeMib: nil)
        return MozAdsClientBuilder()
            .environment(environment: .staging)
            .cacheConfig(cacheConfig: cacheConfig)
            .telemetry(telemetry: AdsClientTelemetry())
            .build()
    }()

    private init() { }

    private static func getDatabaseURL(environment: MozAdsEnvironment) -> String {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dbName = environment == .prod ? "ads-client.db" : "ads-client-staging.db"
        return documentsURL.appendingPathComponent(dbName).path
    }
}
