/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

/**
 * The base thumbnails protocol.
 */
public protocol Thumbnails {
    func clear(complete: ((success: Bool) -> Void)?)
    func get(url: NSURL, complete: (thumbnail: Thumbnail?) -> Void)
    func set(url: NSURL, thumbnail: Thumbnail, complete: ((success: Bool) -> Void)?)
}

public class Thumbnail {
    public var image: UIImage

    public init(image: UIImage) {
        self.image = image
    }
}