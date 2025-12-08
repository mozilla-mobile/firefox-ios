// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct RelayMaskTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    // MARK: - Events

    func showPrompt() {
        gleanWrapper.recordEvent(for: GleanMetrics.AutofillEmailMask.promptShown)
    }

    func autofilled(newMask: Bool) {
        let extra = GleanMetrics.AutofillEmailMask.AutofilledExtra(isNewEmailMask: newMask)
        gleanWrapper.recordEvent(for: GleanMetrics.AutofillEmailMask.autofilled, extras: extra)
    }

    func autofillFailed(error: String) {
        let extra = GleanMetrics.AutofillEmailMask.AutofillFailedExtra(error: error)
        gleanWrapper.recordEvent(for: GleanMetrics.AutofillEmailMask.autofillFailed, extras: extra)
    }

    func learnMoreTapped() {
        gleanWrapper.recordEvent(for: GleanMetrics.AutofillEmailMask.emailMaskLearnMoreTapped)
    }

    func manageMasksTapped() {
        gleanWrapper.recordEvent(for: GleanMetrics.AutofillEmailMask.manageEmailMaskTapped)
    }
}
