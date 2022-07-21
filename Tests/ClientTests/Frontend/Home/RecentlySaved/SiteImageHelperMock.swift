// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Foundation
import LinkPresentation
import Storage

class SiteImageHelperMock: SiteImageHelperProtocol {
    func fetchImageFor(site: Site,
                       imageType: SiteImageType,
                       shouldFallback: Bool,
                       metadataProvider: LPMetadataProvider,
                       completion: @escaping (UIImage?) -> Void) {

    }

    
}
