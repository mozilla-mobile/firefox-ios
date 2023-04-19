// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MetricKit
import Sentry

protocol AppMetricsProvider: MXMetricManagerSubscriber {
    var metrics: [String: Any] { get set }
    func didReceive(_ payloads: [MXMetricPayload])
}

protocol HistogrammedTimeMetric {
    var histogram: MXHistogram<UnitDuration> { get }
    var average: Measurement<UnitDuration> { get }
}

extension HistogrammedTimeMetric {
    var average: Measurement<UnitDuration> {
        let buckets = histogram.bucketEnumerator.compactMap { $0 as? MXHistogramBucket }

        let totalBuckets = buckets.reduce(0) { total, bucket in
            var summingTheTotal = total
            summingTheTotal += bucket.bucketCount

            return summingTheTotal
        }

        let totalDurations: Double = buckets.reduce(0) { totalDuration, bucket in
            var totalDuration = totalDuration
            totalDuration += Double(bucket.bucketCount) * bucket.bucketEnd.value

            return totalDuration
        }

        let average = totalDurations / Double(totalBuckets)

        return Measurement(value: average, unit: UnitDuration.milliseconds)
    }
}

extension MXAppResponsivenessMetric: HistogrammedTimeMetric {
    var histogram: MXHistogram<UnitDuration> {
        histogrammedApplicationHangTime
    }
}

public class AppMetricsManager: NSObject, AppMetricsProvider {
    public static let shared = AppMetricsManager()

    private let manager: MXMetricManager
    private let sentryWrapper: SentryWrapper
    var metrics: [String: Any] = [:]

    public init(sentryWrapper: SentryWrapper = DefaultSentry()) {
        self.manager = MXMetricManager.shared
        self.sentryWrapper = sentryWrapper

        super.init()

        manager.add(self)
    }

    deinit {
        manager.remove(self)
    }

    /// This method is invoked by the system on a background queue once per day when a new `MXMetricPayload` is available.
    /// - Parameter payloads: An array of `MXMetricPayload`s
    public func didReceive(_ payloads: [MXMetricPayload]) {
        metrics = [:]
        metrics["hangtime-metrics"] = extractHangMetricsFrom(payloads)

        guard !metrics.isEmpty else { return }

        sendMetricsWith(metrics)
    }

    private func sendMetricsWith(_ metrics: [String: Any]) {
        let event = makeEventFrom(metrics)
        guard let message = event.message?.formatted else { return }

        sentryWrapper.captureMessage(message: message) { scope in
            scope.setEnvironment(event.environment)
            scope.setExtras(event.extra)
        }
    }

    private func makeEventFrom(_ metrics: [String: Any]) -> Event {
        let event = Event()

        event.message = SentryMessage(formatted: "MetricKit")
        event.tags = ["tag": LoggerCategory.metricKit.rawValue]
        event.extra = metrics

        return event
    }

    private func extractHangMetricsFrom(_ payloads: [MXMetricPayload]) -> [String: Any]? {
        var hangtimeMetrics: [String: Any] = [:]

        guard let metrics = average(for: \.applicationResponsivenessMetrics, on: payloads) else {
            return nil
        }
        hangtimeMetrics["hangtime-metrics"] = metrics

        return hangtimeMetrics
    }

    private func average<Value: HistogrammedTimeMetric>(for keyPath: KeyPath<MXMetricPayload, Value?>,
                                                        on payloads: [MXMetricPayload]) -> Measurement<UnitDuration>? {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return nil
        }
        let averages = payloads.filter { payload in
            guard !payload.includesMultipleApplicationVersions else {
                return false
            }

            return payload.latestApplicationVersion == currentVersion
        }.compactMap { payload in
            payload[keyPath: keyPath]?.average.value
        }

        guard !averages.isEmpty else { return nil }
        let average = averages.reduce(0.0, +) / Double(averages.count)

        return Measurement(value: Double(average), unit: UnitDuration.milliseconds)
    }
}
