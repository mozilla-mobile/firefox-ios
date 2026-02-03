// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

private let logTag = "AdsClientTelemetry"


// There is already a class AdsClient in FxAClient so we need to use a different name here.
public final class RustAdsClient {
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
    
    // Deprecated: Use .production instead
    public static let shared: MozAdsClient = production
    
    private init() { }
}

func getDatabaseURL(environment: MozAdsEnvironment) -> String {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let dbName = environment == .prod ? "ads-client.db" : "ads-client-staging.db"
    return documentsURL.appendingPathComponent(dbName).path
}

public final class AdsClientTelemetry: MozAdsTelemetry {
    public func recordBuildCacheError(label: String, value: String) {
        GleanMetrics.AdsClient.buildCacheError[label].set(value)
    }

    public func recordClientError(label: String, value: String) {
        GleanMetrics.AdsClient.clientError[label].set(value)
    }

    public func recordClientOperationTotal(label: String) {
        GleanMetrics.AdsClient.clientOperationTotal[label].add()
    }

    public func recordDeserializationError(label: String, value: String) {
        GleanMetrics.AdsClient.deserializationError[label].set(value)
    }

    public func recordHttpCacheOutcome(label: String, value: String) {
        GleanMetrics.AdsClient.httpCacheOutcome[label].set(value)
    }
}
