/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol PhotoManagerDelegate: class {
    func photoManager(_ photoManager: PhotoManager, didFinishSavingWithError error: Error?)
}

class PhotoManager: NSObject {
    weak var delegate: PhotoManagerDelegate?

    func save(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        delegate?.photoManager(self, didFinishSavingWithError: error)
    }
}
