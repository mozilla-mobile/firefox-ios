// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MetricKit

class MetricKitWrapper: NSObject, MXMetricManagerSubscriber {
    private let telemetryWrapper: TelemetryWrapperProtocol
    private let measurementFormatter: MeasurementFormatter

    init(telemetryWrapper: TelemetryWrapperProtocol = TelemetryWrapper.shared) {
        self.telemetryWrapper = telemetryWrapper

        self.measurementFormatter = MeasurementFormatter()
        self.measurementFormatter.locale = Locale(identifier: "en_US")
        self.measurementFormatter.unitOptions = .providedUnit

        super.init()
        MXMetricManager.shared.add(self)
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        payloads.forEach { payload in
            payload.diskWriteExceptionDiagnostics?.forEach({ exception in
                self.handleDiskWriteException(exception)
            })
            payload.cpuExceptionDiagnostics?.forEach({ exception in
                self.handleCPUException(exception)
            })
            payload.hangDiagnostics?.forEach({ exception in
                self.handleHangException(exception)
            })
        }
    }

    private func handleDiskWriteException(_ exception: MXDiskWriteExceptionDiagnostic) {
        let size = Int32(measurementFormatter.string(from: exception.totalWritesCaused)) ?? -1
        let eventExtra = [TelemetryWrapper.EventExtraKey.size.rawValue: size]
        telemetryWrapper.recordEvent(category: .information,
                                     method: .error,
                                     object: .app,
                                     value: .largeFileWrite,
                                     extras: eventExtra)
    }

    private func handleCPUException(_ exception: MXCPUExceptionDiagnostic) {
        let size = Int32(measurementFormatter.string(from: exception.totalCPUTime)) ?? -1
        let eventExtra = [TelemetryWrapper.EventExtraKey.size.rawValue: size]
        telemetryWrapper.recordEvent(category: .information,
                                     method: .error,
                                     object: .app,
                                     value: .cpuException,
                                     extras: eventExtra)
    }

    private func handleHangException(_ exception: MXHangDiagnostic) {
        let size = Int32(measurementFormatter.string(from: exception.hangDuration)) ?? -1
        let eventExtra = [TelemetryWrapper.EventExtraKey.size.rawValue: size]
        telemetryWrapper.recordEvent(category: .information,
                                     method: .error,
                                     object: .app,
                                     value: .hangException,
                                     extras: eventExtra)
    }
}
