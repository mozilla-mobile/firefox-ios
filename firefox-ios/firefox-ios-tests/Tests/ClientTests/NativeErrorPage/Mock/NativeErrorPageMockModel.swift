// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

final class NativeErrorPageMock {
    static var model: ErrorPageModel {
        return ErrorPageModel(
            errorTitle: "NoInternetConnection",
            errorDescription: "There’s a problem with your internet connection."
        )
    }
}
