/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol InfoModelProtocol {
    var image: UIImage? { get set }
    var title: String { get set }
    var description: String? { get set }
    var primaryAction: String { get set }
    var secondaryAction: String? { get set }
    var a11yIdRoot: String { get set }

    init(image: UIImage?, title: String, description: String?, primaryAction: String, secondaryAction: String?, a11yIdRoot: String)
}

struct CoverSheetInfoModel: InfoModelProtocol {
    var image: UIImage?
    var title: String
    var description: String?
    var primaryAction: String
    var secondaryAction: String?
    var a11yIdRoot: String

    init(image: UIImage?,
         title: String,
         description: String?,
         primaryAction: String,
         secondaryAction: String?,
         a11yIdRoot: String) {
        self.image = image
        self.title = title
        self.description = description
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.a11yIdRoot = a11yIdRoot
    }
}

protocol InformationContainerModel {
    var enabledCards: [IntroViewModel.InformationCards] { get }
}

extension InformationContainerModel {
    func getNextIndex(currentIndex: Int, goForward: Bool) -> Int? {
        if goForward && currentIndex + 1 < enabledCards.count {
            return currentIndex + 1
        }

        if !goForward && currentIndex > 0 {
            return currentIndex - 1
        }

        return nil
    }
}
