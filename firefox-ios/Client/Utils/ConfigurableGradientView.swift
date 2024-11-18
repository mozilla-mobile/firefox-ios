// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/// A view whose primary modifiable layer is a gradient layer
public class ConfigurableGradientView: UIView {
    private let logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var gradientLayer: CAGradientLayer {
        guard let gradientLayer = layer as? CAGradientLayer else {
            logger.log("Failed to cast layer to CAGradientLayer in ConfigurableGradientView class",
                       level: .fatal,
                       category: .library)
            return CAGradientLayer()
        }
        return gradientLayer
    }

    override public class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    /// The main interface through which the gradient view is configured.
    ///
    /// - Parameters:
    ///   - colors: An array outlining the colors through which the gradient will shift.
    ///   - positions: An array outlining the percentages where each colour will shift to.
    ///   This should be from [0.0, to 1.0].
    ///   - startPoint: The gradient's start point.
    ///   - endPoint: The gradient's end point.
    public func configureGradient(colors: [UIColor], positions: [CGFloat], startPoint: CGPoint, endPoint: CGPoint) {
        gradientLayer.colors = colors.map { $0.resolvedColor(with: traitCollection).cgColor }
        gradientLayer.locations = positions.map { NSNumber(value: Double($0)) }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
    }
}
