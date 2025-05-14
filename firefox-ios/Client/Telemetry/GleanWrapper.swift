// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

protocol GleanWrapper {
    func handleDeeplinkUrl(url: URL)
    func setUpload(isEnabled: Bool)

    // MARK: Glean Metrics

    func recordEvent<ExtraObject>(for metric: EventMetricType<ExtraObject>,
                                  extras: EventExtras) where ExtraObject: EventExtras
    func recordEvent<NoExtras>(for metric: EventMetricType<NoExtras>) where NoExtras: EventExtras
    func incrementCounter(for metric: CounterMetricType)
    func recordString(for metric: StringMetricType, value: String)
    func recordLabel(for metric: LabeledMetricType<CounterMetricType>, label: String)
    func setBoolean(for metric: BooleanMetricType, value: Bool)
    func recordQuantity(for metric: QuantityMetricType, value: Int64)
    func recordLabeledQuantity(for metric: LabeledMetricType<QuantityMetricType>, label: String, value: Int64)
    func recordUrl(for metric: UrlMetricType, value: String)

    func incrementNumerator(for metric: RateMetricType, amount: Int32)
    func incrementDenominator(for metric: RateMetricType, amount: Int32)

    // MARK: Timing Metrics
    /// You should nullify any references to the timer after stopping it
    func startTiming(for metric: TimingDistributionMetricType) -> GleanTimerId
    func cancelTiming(for metric: TimingDistributionMetricType,
                      timerId: GleanTimerId)
    func stopAndAccumulateTiming(for metric: TimingDistributionMetricType,
                                 timerId: GleanTimerId)

    // MARK: Pings

    func submit<ReasonCodesEnum>(ping: Ping<ReasonCodesEnum>) where ReasonCodesEnum: ReasonCodes
}

/// Glean wrapper to abstract Glean from our application
struct DefaultGleanWrapper: GleanWrapper {
    private let glean: Glean

    init(glean: Glean = Glean.shared) {
        self.glean = glean
    }

    func handleDeeplinkUrl(url: URL) {
        glean.handleCustomUrl(url: url)
    }

    func setUpload(isEnabled: Bool) {
        glean.setCollectionEnabled(isEnabled)
    }

    // MARK: Glean Metrics

    func recordEvent<ExtraObject>(for metric: EventMetricType<ExtraObject>,
                                  extras: EventExtras) where ExtraObject: EventExtras {
        if let castedExtras = extras as? ExtraObject {
            metric.record(castedExtras)
        } else {
            fatalError("extras could not be cast to the expected type \(ExtraObject.self)")
        }
    }

    func recordEvent<NoExtras>(for metric: EventMetricType<NoExtras>) where NoExtras: EventExtras {
        metric.record()
    }

    func incrementCounter(for metric: CounterMetricType) {
        metric.add()
    }

    func recordString(for metric: StringMetricType, value: String) {
        metric.set(value)
    }

    func recordLabel(for metric: LabeledMetricType<CounterMetricType>, label: String) {
        metric[label].add()
    }

    func setBoolean(for metric: BooleanMetricType, value: Bool) {
        metric.set(value)
    }

    func recordQuantity(for metric: QuantityMetricType, value: Int64) {
        metric.set(value)
    }

    func recordLabeledQuantity(for metric: LabeledMetricType<QuantityMetricType>, label: String, value: Int64) {
        metric[label].set(value)
    }

    func recordUrl(for metric: UrlMetricType, value: String) {
        metric.set(value)
    }

    // MARK: RateMetricType

    func incrementNumerator(for metric: RateMetricType, amount: Int32) {
        metric.addToNumerator(amount)
    }

    func incrementDenominator(for metric: RateMetricType, amount: Int32) {
        metric.addToDenominator(amount)
    }

    // MARK: MeasurementTelemetry

    func startTiming(for metric: TimingDistributionMetricType) -> GleanTimerId {
        return metric.start()
    }

    func cancelTiming(for metric: TimingDistributionMetricType,
                      timerId: GleanTimerId) {
        metric.cancel(timerId)
    }

    func stopAndAccumulateTiming(for metric: TimingDistributionMetricType,
                                 timerId: GleanTimerId) {
        metric.stopAndAccumulate(timerId)
    }

    // MARK: Pings

    func submit<ReasonCodesEnum>(ping: Ping<ReasonCodesEnum>) where ReasonCodesEnum: ReasonCodes {
        ping.submit()
    }
}
