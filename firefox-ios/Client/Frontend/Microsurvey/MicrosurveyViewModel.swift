// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct MicrosurveyViewModel {
    // TODO: FXIOS-8990 - Mobile Messaging Structure
    // Title + button text can come from mobile messaging; but has a hardcoded string as fallback
    var title = String(
        format: .Microsurvey.Prompt.TitleLabel,
        AppName.shortName.rawValue
    )
    var buttonText: String = .Microsurvey.Prompt.TakeSurveyButton
    var openAction: () -> Void
    var closeAction: () -> Void
}
