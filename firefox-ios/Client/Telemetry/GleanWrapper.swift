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

// Just for the sake of trying them in this branch easily
class TelemetryExample {
    let wrapper = DefaultGleanWrapper()

    func eventMetricType() {
        let didConfirmExtra = GleanMetrics.PrivateBrowsing.DataClearanceIconTappedExtra(didConfirm: true)
        wrapper.submitEventMetricType(event: GleanMetrics.PrivateBrowsing.dataClearanceIconTapped,
                                      extras: didConfirmExtra)
    }

    func eventMetricTypeNoExtra() {
        wrapper.submitEventMetricType(event: GleanMetrics.Addresses.autofillPromptDismissed)
    }

    func counterMetricType() {
        wrapper.submitCounterMetricType(event: GleanMetrics.DefaultBrowserCard.dismissPressed)
    }

    func stringMetricType() {
        wrapper.submitStringMetricType(event: GleanMetrics.Preferences.newTabExperience,
                                       value: "Example")
    }

    func labeledMetricType() {
        wrapper.submitLabeledMetricType(event: GleanMetrics.Bookmarks.add,
                                        value: "Example")
    }

    func booleanMetricType() {
        wrapper.submitBooleanMetricType(event: GleanMetrics.App.choiceScreenAcquisition,
                                        value: true)
    }

    func quantityMetricType() {
        wrapper.submitQuantityMetricType(event:  GleanMetrics.Bookmarks.mobileBookmarksCount,
                                         value: 5)
    }

    func measurementTelemetry() {
        let timerId = wrapper.startMeasurementTelemetry(forMetric: GleanMetrics.Awesomebar.queryTime)
        wrapper.stopAndAccumulate(forMetric: GleanMetrics.Awesomebar.queryTime, timerId:
                                    timerId)
        wrapper.cancelMeasurementTelemetry(forMetric: GleanMetrics.Awesomebar.queryTime,
                                           timerId: timerId)
    }

    func rateMetricType() {
        wrapper.addToNumeratorRateMetricType(event: GleanMetrics.PlacesHistoryMigration.migrationEndedRate,
                                             amount: 1)
        wrapper.addToDenominatorRateMetricType(event: GleanMetrics.PlacesHistoryMigration.migrationEndedRate,
                                             amount: 1)
    }
}
