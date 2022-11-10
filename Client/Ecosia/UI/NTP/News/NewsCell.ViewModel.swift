// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

extension NewsCell {
    struct ViewModel {
        let model: NewsModel?
        let promo: Core.Promo?

        var trackingName: String {
            return model?.trackingName ?? promo!.trackingName
        }

        var targetUrl: URL {
            return model?.targetUrl ?? promo!.targetUrl
        }

        var text: String {
            return model?.text ?? promo!.text
        }
    }
}
