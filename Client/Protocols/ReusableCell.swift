// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol ReusableCell: AnyObject {
    static var cellIdentifier: String { get }
}

extension ReusableCell where Self: UICollectionViewCell {
    static var cellIdentifier: String { return String(describing: self) }
}

extension ReusableCell where Self: UITableViewCell {
    static var cellIdentifier: String { return String(describing: self) }
}
