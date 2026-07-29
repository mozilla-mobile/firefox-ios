// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest

/// Arbitrary: every caller cares that there IS an image, not how big it is.
private let sampleImageSize = CGSize(width: 40, height: 60)

extension XCTestCase {
    /// Depth-first search for the first subview of the given type.
    @MainActor
    func firstSubview<T: UIView>(ofType type: T.Type, in view: UIView?) -> T? {
        guard let view else { return nil }
        for subview in view.subviews {
            if let match = subview as? T { return match }
            if let match = firstSubview(ofType: type, in: subview) { return match }
        }
        return nil
    }

    /// A solid-colour stand-in image. Scale 1, so a fixture costs its nominal pixels rather
    /// than three times as many at device scale.
    func sampleImage(size: CGSize = sampleImageSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// `UIControl.sendActions` needs a running `UIApplication`, which logic tests lack, and it
    /// fails silently. Invoke each registered target/action directly instead. The control is
    /// non-optional so a nil lookup fails at the caller's `XCTUnwrap`, not quietly here.
    @MainActor
    func fireActions(on control: UIControl, for event: UIControl.Event) {
        for target in control.allTargets {
            let object = target as NSObject
            control.actions(forTarget: target, forControlEvent: event)?.forEach {
                object.perform(Selector($0))
            }
        }
    }
}
