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
    public static let shared: MozAdsClient = {
        let cacheConfig = MozAdsCacheConfig(dbPath: getDatabaseURL(), defaultCacheTtlSeconds: nil, maxSizeMib: nil)
        let config = MozAdsClientConfig(environment: .prod, cacheConfig: cacheConfig, telemetry: AdsClientTelemetry())
        return MozAdsClient(clientConfig: config)
    }()
    private init() { }
}

func getDatabaseURL() -> String {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    return documentsURL.appendingPathComponent("ads-client.db").path
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
