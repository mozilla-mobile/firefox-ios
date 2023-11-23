// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol SurveySurfaceInfoProtocol {
    var image: UIImage { get set }
    var text: String { get set }
    var takeSurveyButtonLabel: String { get set }
    var dismissActionLabel: String { get set }

    init(text: String, takeSurveyButtonLabel: String, dismissActionLabel: String, image: UIImage)
}

struct SurveySurfaceInfoModel: SurveySurfaceInfoProtocol {
    var image: UIImage
    var text: String
    var takeSurveyButtonLabel: String
    var dismissActionLabel: String

    init(text: String,
         takeSurveyButtonLabel: String,
         dismissActionLabel: String,
         image: UIImage
    ) {
        self.image = image
        self.text = text
        self.takeSurveyButtonLabel = takeSurveyButtonLabel
        self.dismissActionLabel = dismissActionLabel
    }
}
