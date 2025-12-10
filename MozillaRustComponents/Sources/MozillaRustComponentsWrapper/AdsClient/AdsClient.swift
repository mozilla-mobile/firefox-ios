// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

typealias AdsClientMetrics = GleanMetrics.AdsClient

private let logTag = "AdsClientTelemetry"
private let logger = Logger(tag: logTag)


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
        logger.info("recordBuildCacheError - label: \(label), value: \(value)")
        AdsClientMetrics.buildCacheError[label].set(value)
    }

    public func recordClientError(label: String, value: String) {
        logger.info("recordClientError - label: \(label), value: \(value)")
        AdsClientMetrics.clientError[label].set(value)
    }

    public func recordClientOperationTotal(label: String) {
        logger.info("recordClientOperationTotal - label: \(label)")
        AdsClientMetrics.clientOperationTotal[label].add()
    }

    public func recordDeserializationError(label: String, value: String) {
        logger.info("recordDeserializationError - label: \(label), value: \(value)")
        AdsClientMetrics.deserializationError[label].set(value)
    }

    public func recordHttpCacheOutcome(label: String, value: String) {
        logger.info("recordHttpCacheOutcome - label: \(label), value: \(value)")
        AdsClientMetrics.httpCacheOutcome[label].set(value)
    }
}
