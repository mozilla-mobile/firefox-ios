// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension UIView {
    private struct Positions: OptionSet {
        static let top = Positions(rawValue: 1)
        static let bottom = Positions(rawValue: 1 << 1)
        let rawValue: Int8
        
        static func derive(row: Int, totalCount: Int) -> Positions {
            var pos = Positions()
            if row == 0 { pos.insert(.top) }
            if row == totalCount - 1 { pos.insert(.bottom) }
            return pos
        }
    }
    
    /// Updates `layer.maskedCorners` based on the position of the view inside any sort of list.
    /// It masks top left and right if the view is the first of the list and bottom left and right if the view is the last.
    /// - Parameters:
    ///   - row: The position of the view.
    ///   - totalCount: The total count of views on the list.
    func setMaskedCornersUsingPosition(row: Int, totalCount: Int) {
        let pos = Positions.derive(row: row, totalCount: totalCount)
        var masked: CACornerMask = []
        if pos.contains(.top) {
            masked.formUnion(.layerMinXMinYCorner)
            masked.formUnion(.layerMaxXMinYCorner)
        }
        if pos.contains(.bottom) {
            masked.formUnion(.layerMinXMaxYCorner)
            masked.formUnion(.layerMaxXMaxYCorner)
        }
        layer.maskedCorners = masked
    }
}
