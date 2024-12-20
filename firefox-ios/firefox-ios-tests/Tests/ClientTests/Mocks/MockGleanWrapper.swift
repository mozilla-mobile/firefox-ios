// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import UIKit
@testable import Client

class MockGleanWrapper: GleanWrapper {
    var handleDeeplinkUrlCalled = 0
    var submitPingCalled = 0
    var setUploadEnabledCalled = 0
    var submitEventMetricTypeCalled = 0
    var submitEventMetricTypeNoExtraCalled = 0
    var submitCounterMetricTypeCalled = 0
    var submitStringMetricTypeCalled = 0
    var submitLabeledMetricTypeCalled = 0
    var submitBooleanMetricTypeCalled = 0
    var submitQuantityMetricTypeCalled = 0
    var addToNumeratorRateMetricTypeCalled = 0
    var addToDenominatorRateMetricTypeCalled = 0
    var startMeasurementTelemetryCalled = 0
    var cancelMeasurementTelemetryCalled = 0
    var stopAndAccumulateCalled = 0
    var savedEvent: Any?

    var savedHandleDeeplinkUrl: URL?
    var savedSetUploadIsEnabled: Bool?
    var savedTimerId = GleanTimerId(id: 0)

    func handleDeeplinkUrl(url: URL) {
        handleDeeplinkUrlCalled += 1
        savedHandleDeeplinkUrl = url
    }

    func submitPing() {
        submitPingCalled += 1
    }

    func setUpload(isEnabled: Bool) {
        setUploadEnabledCalled += 1
        savedSetUploadIsEnabled = isEnabled
    }

    func submitEventMetricType<ExtraObject>(event: EventMetricType<ExtraObject>,
                                            extras: EventExtras) where ExtraObject: EventExtras {
        savedEvent = event
        submitEventMetricTypeCalled += 1
    }

    func submitEventMetricType<NoExtras>(event: EventMetricType<NoExtras>) where NoExtras: EventExtras {
        savedEvent = event
        submitEventMetricTypeNoExtraCalled += 1
    }

    func submitCounterMetricType(event: CounterMetricType) {
        savedEvent = event
        submitCounterMetricTypeCalled += 1
    }

    func submitStringMetricType(event: StringMetricType, value: String) {
        savedEvent = event
        submitStringMetricTypeCalled += 1
    }

    func submitLabeledMetricType(event: LabeledMetricType<CounterMetricType>, value: String) {
        savedEvent = event
        submitLabeledMetricTypeCalled += 1
    }

    func submitBooleanMetricType(event: BooleanMetricType, value: Bool) {
        savedEvent = event
        submitBooleanMetricTypeCalled += 1
    }

    func submitQuantityMetricType(event: QuantityMetricType, value: Int64) {
        savedEvent = event
        submitQuantityMetricTypeCalled += 1
    }

    func addToNumeratorRateMetricType(event: RateMetricType, amount: Int32) {
        savedEvent = event
        addToNumeratorRateMetricTypeCalled += 1
    }

    func addToDenominatorRateMetricType(event: RateMetricType, amount: Int32) {
        savedEvent = event
        addToDenominatorRateMetricTypeCalled += 1
    }

    func startMeasurementTelemetry(forMetric metric: TimingDistributionMetricType) -> GleanTimerId {
        savedEvent = metric
        startMeasurementTelemetryCalled += 1
        return savedTimerId
    }

    func cancelMeasurementTelemetry(forMetric metric: TimingDistributionMetricType,
                                    timerId: GleanTimerId) {
        savedEvent = metric
        cancelMeasurementTelemetryCalled += 1
    }

    func stopAndAccumulate(forMetric metric: TimingDistributionMetricType,
                           timerId: GleanTimerId) {
        savedEvent = metric
        stopAndAccumulateCalled += 1
    }
}
