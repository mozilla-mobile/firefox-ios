// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import UIKit
@testable import Client

class MockGleanWrapper: GleanWrapper {
    var handleDeeplinkUrlCalled = 0
    var setUploadEnabledCalled = 0
    var recordEventCalled = 0
    var recordEventNoExtraCalled = 0
    var incrementCounterCalled = 0
    var recordStringCalled = 0
    var recordLabelCalled = 0
    var setBooleanCalled = 0
    var recordQuantityCalled = 0
    var recordLabeledQuantityCalled = 0
    var recordUrlCalled = 0
    var incrementNumeratorCalled = 0
    var incrementDenominatorCalled = 0
    var startTimingCalled = 0
    var cancelTimingCalled = 0
    var stopAndAccumulateCalled = 0
    var submitPingCalled = 0
    var savedEvents: [Any]? = []
    var savedExtras: Any?
    var savedLabel: Any?
    var savedPing: Any?

    var savedHandleDeeplinkUrl: URL?
    var savedSetUploadIsEnabled: Bool?
    var savedTimerId = GleanTimerId(id: 0)

    func handleDeeplinkUrl(url: URL) {
        handleDeeplinkUrlCalled += 1
        savedHandleDeeplinkUrl = url
    }

    func setUpload(isEnabled: Bool) {
        setUploadEnabledCalled += 1
        savedSetUploadIsEnabled = isEnabled
    }

    func recordEvent<ExtraObject>(for metric: EventMetricType<ExtraObject>,
                                  extras: EventExtras) where ExtraObject: EventExtras {
        savedExtras = extras
        savedEvents?.append(metric)
        recordEventCalled += 1
    }

    func recordEvent<NoExtras>(for metric: EventMetricType<NoExtras>) where NoExtras: EventExtras {
        savedEvents?.append(metric)
        recordEventNoExtraCalled += 1
    }

    func incrementCounter(for metric: CounterMetricType) {
        savedEvents?.append(metric)
        incrementCounterCalled += 1
    }

    func recordString(for metric: StringMetricType, value: String) {
        savedEvents?.append(metric)
        recordStringCalled += 1
    }

    func recordLabel(for metric: LabeledMetricType<CounterMetricType>, label: String) {
        savedLabel = label
        savedEvents?.append(metric)
        recordLabelCalled += 1
    }

    func setBoolean(for metric: BooleanMetricType, value: Bool) {
        savedEvents?.append(metric)
        setBooleanCalled += 1
    }

    func recordQuantity(for metric: QuantityMetricType, value: Int64) {
        savedEvents?.append(metric)
        recordQuantityCalled += 1
    }

    func recordLabeledQuantity(for metric: LabeledMetricType<QuantityMetricType>, label: String, value: Int64) {
        savedEvents?.append(metric)
        recordLabeledQuantityCalled += 1
    }

    func recordUrl(for metric: UrlMetricType, value: String) {
        savedEvents?.append(metric)
        recordUrlCalled += 1
    }

    func incrementNumerator(for metric: RateMetricType, amount: Int32) {
        savedEvents?.append(metric)
        incrementNumeratorCalled += 1
    }

    func incrementDenominator(for metric: RateMetricType, amount: Int32) {
        savedEvents?.append(metric)
        incrementDenominatorCalled += 1
    }

    func startTiming(for metric: TimingDistributionMetricType) -> GleanTimerId {
        savedEvents?.append(metric)
        startTimingCalled += 1
        return savedTimerId
    }

    func cancelTiming(for metric: TimingDistributionMetricType,
                      timerId: GleanTimerId) {
        savedEvents?.append(metric)
        cancelTimingCalled += 1
    }

    func stopAndAccumulateTiming(for metric: TimingDistributionMetricType,
                                 timerId: GleanTimerId) {
        savedEvents?.append(metric)
        stopAndAccumulateCalled += 1
    }

    func submit<ReasonCodesEnum>(ping: Ping<ReasonCodesEnum>) where ReasonCodesEnum: ReasonCodes {
        savedPing = ping
        submitPingCalled += 1
    }
}
