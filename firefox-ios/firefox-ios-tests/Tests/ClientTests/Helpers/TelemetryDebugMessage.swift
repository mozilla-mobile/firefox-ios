// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

struct TelemetryDebugMessage {
    let firstText = "Expected savedMetric to be of type "
    let lastText = ", but got "
    let text: String

    init<Metatype>(expectedMetric: Metatype, resultMetric: Metatype) {
        text = "\(firstText)\(expectedMetric)\(lastText)\(resultMetric)"
    }
}
