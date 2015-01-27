/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import CoreData
import UIKit

import Storage

public class Favicon {
    public var guid: String?
    public var url: String
    public var updatedDate: NSDate
    public var image: UIImage?

    public init(url: String, image: UIImage?, date: NSDate? = nil) {
        self.url = url
        self.updatedDate = NSDate()
        self.image = image

        if let date = date {
            self.updatedDate = date
        } else {
            self.updatedDate = NSDate()
        }
    }
}
