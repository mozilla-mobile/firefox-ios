// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

protocol GleanWrapper {
    func handleDeeplinkUrl(url: URL)
    func setUpload(isEnabled: Bool)
    func submitPing()

    // MARK: Glean Metrics

    func submitEventMetricType<ExtraObject>(event: EventMetricType<ExtraObject>,
                                            extras: EventExtras) where ExtraObject: EventExtras
    func submitEventMetricType<NoExtras>(event: EventMetricType<NoExtras>) where NoExtras: EventExtras
    func submitCounterMetricType(event: CounterMetricType)
    func submitStringMetricType(event: StringMetricType, value: String)
    func submitLabeledMetricType(event: LabeledMetricType<CounterMetricType>, value: String)
    func submitBooleanMetricType(event: BooleanMetricType, value: Bool)
    func submitQuantityMetricType(event: QuantityMetricType, value: Int64)

    func addToNumeratorRateMetricType(event: RateMetricType, amount: Int32)
    func addToDenominatorRateMetricType(event: RateMetricType, amount: Int32)

    func startMeasurementTelemetry(forMetric metric: TimingDistributionMetricType) -> GleanTimerId
    func cancelMeasurementTelemetry(forMetric metric: TimingDistributionMetricType,
                                    timerId: GleanTimerId)
    func stopAndAccumulate(forMetric metric: TimingDistributionMetricType,
                           timerId: GleanTimerId)
}

/// Glean wrapper to abstract Glean from our application
struct DefaultGleanWrapper: GleanWrapper {
    func handleDeeplinkUrl(url: URL) {
        Glean.shared.handleCustomUrl(url: url)
    }

    func setUpload(isEnabled: Bool) {
        Glean.shared.setCollectionEnabled(isEnabled)
    }

    func submitPing() {
        GleanMetrics.Pings.shared.firstSession.submit()
    }

    // MARK: Glean Metrics

    func submitEventMetricType<ExtraObject>(event: EventMetricType<ExtraObject>,
                                            extras: EventExtras) where ExtraObject: EventExtras {
        if let castedExtras = extras as? ExtraObject {
            event.record(castedExtras)
        } else {
            fatalError("extras could not be cast to the expected type \(ExtraObject.self)")
        }
    }

    func submitEventMetricType<NoExtras>(event: EventMetricType<NoExtras>) where NoExtras: EventExtras {
        event.record()
    }

    func submitCounterMetricType(event: CounterMetricType) {
        event.add()
    }

    func submitStringMetricType(event: StringMetricType, value: String) {
        event.set(value)
    }

    func submitLabeledMetricType(event: LabeledMetricType<CounterMetricType>, value: String) {
        event[value].add()
    }

    func submitBooleanMetricType(event: BooleanMetricType, value: Bool) {
        GleanMetrics.App.choiceScreenAcquisition.set(value)
    }

    func submitQuantityMetricType(event: QuantityMetricType, value: Int64) {
        event.set(value)
    }

    // MARK: RateMetricType

    func addToNumeratorRateMetricType(event: RateMetricType, amount: Int32) {
        event.addToNumerator(amount)
    }

    func addToDenominatorRateMetricType(event: RateMetricType, amount: Int32) {
        event.addToDenominator(amount)
    }

    // MARK: MeasurementTelemetry

    func startMeasurementTelemetry(forMetric metric: TimingDistributionMetricType) -> GleanTimerId {
        return metric.start()
    }

    func cancelMeasurementTelemetry(forMetric metric: TimingDistributionMetricType,
                                    timerId: GleanTimerId) {
        metric.cancel(timerId)
    }

    /// You should nullify any references to the timer after stopping it
    func stopAndAccumulate(forMetric metric: TimingDistributionMetricType,
                           timerId: GleanTimerId) {
        metric.stopAndAccumulate(timerId)
    }
}
