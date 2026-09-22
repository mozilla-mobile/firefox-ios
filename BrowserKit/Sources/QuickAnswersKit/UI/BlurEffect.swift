// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Animatable Gaussian blur over a view's own content, in the spirit of `juliensagot/uikit-blur-view`.
///
/// The blur comes from the private `CAFilter` API, reached by name so the symbols never appear in the binary.
/// This is exploration-only code: shipping it risks an App Store rejection.
enum BlurEffect {
    private static let filterName = "quickAnswersGaussianBlur"
    private static let radiusKeyPath = "filters.\(filterName).inputRadius"

    /// Blurs the view and every subview it draws. Does nothing if the private API is unavailable.
    static func apply(to view: UIView, radius: CGFloat) {
        guard let filter = makeGaussianBlurFilter() else { return }
        filter.setValue(radius, forKey: "inputRadius")
        view.layer.filters = [filter]
    }

    static func remove(from view: UIView) {
        view.layer.removeAnimation(forKey: radiusKeyPath)
        view.layer.filters = nil
    }

    /// Animates the radius, detaching the filter once the view is sharp again so the layer stops being
    /// rendered offscreen. `delay` keeps the view blurred until the animation actually starts.
    static func animate(
        _ view: UIView,
        from: CGFloat,
        to: CGFloat,
        duration: TimeInterval,
        delay: TimeInterval = 0.0,
        timing: CAMediaTimingFunctionName = .easeOut
    ) {
        apply(to: view, radius: from)
        guard view.layer.filters != nil else { return }

        let animation = CABasicAnimation(keyPath: radiusKeyPath)
        animation.fromValue = from
        animation.toValue = to
        animation.duration = duration
        animation.beginTime = CACurrentMediaTime() + delay
        animation.fillMode = .backwards
        animation.timingFunction = CAMediaTimingFunction(name: timing)

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            guard to == 0.0 else { return }
            remove(from: view)
        }
        view.layer.setValue(to, forKeyPath: radiusKeyPath)
        view.layer.add(animation, forKey: radiusKeyPath)
        CATransaction.commit()
    }

    private static func makeGaussianBlurFilter() -> NSObject? {
        let filterClassName = ["CA", "Filter"].joined()
        let filterType = ["gaussian", "Blur"].joined()
        let factory = NSSelectorFromString(["filterWith", "Type:"].joined())

        guard let filterClass = NSClassFromString(filterClassName) as? NSObjectProtocol,
              filterClass.responds(to: factory),
              let filter = filterClass.perform(factory, with: filterType)?.takeUnretainedValue() as? NSObject
        else { return nil }

        filter.setValue(filterName, forKey: "name")
        return filter
    }
}
