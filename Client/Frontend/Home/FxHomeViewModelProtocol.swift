// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol FXHomeViewModelProtocol {
    // Update section data, completes when data has finished loading
    func updateData(completion: @escaping () -> Void)
}
