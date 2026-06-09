// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

extension HorizontalAlignment {
    static let titleAlignment = HorizontalAlignment(TitleAlignment.self)
    static let descriptionAlignment = HorizontalAlignment(DescriptionAlignment.self)
}

private enum DescriptionAlignment: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        context[HorizontalAlignment.leading]
    }
}

private enum TitleAlignment: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        context[HorizontalAlignment.leading]
    }
}
