// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

public struct PasswordGeneratorTelemetry {
    func passwordGeneratorDialogShown() {
        GleanMetrics.PasswordGenerator.shown.add()
    }

    func usePasswordButtonPressed() {
        GleanMetrics.PasswordGenerator.filled.add()
    }
}
