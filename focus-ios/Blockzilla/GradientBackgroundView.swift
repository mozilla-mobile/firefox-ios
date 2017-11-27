/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class GradientBackgroundView: UIView {
    init(alpha: Float = 0.1, startPoint: CGPoint = CGPoint(x: -0.2, y: 0), endPoint: CGPoint = CGPoint(x: 1.2, y: 1)) {
        super.init(frame: CGRect.zero)

        backgroundColor = UIConstants.colors.gradientBackground

        configureGradientLayerWithPoints(start: startPoint, end: endPoint, alpha: alpha)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    private func configureGradientLayerWithPoints(start startPoint: CGPoint, end endPoint: CGPoint, alpha: Float) {
        guard let gradient = self.layer as? CAGradientLayer else { return }
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        let gradients = [UIConstants.colors.gradientLeft, UIConstants.colors.gradientMiddle, UIConstants.colors.gradientRight]
        gradient.colors = gradients.map { $0.withAlphaComponent(CGFloat(alpha)).cgColor }
    }
}

class IntroCardGradientBackgroundView: UIView {
    init(alpha: Float = 1) {
        super.init(frame: CGRect.zero)
        
        backgroundColor = UIConstants.colors.gradientBackground
        
        let gradient = self.layer as! CAGradientLayer
        let gradients = [UIColor(rgb: 0xF9F9FA), UIColor(rgb: 0xFFFFFF)]
        gradient.colors = gradients.map { $0.withAlphaComponent(CGFloat(alpha)).cgColor }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
}
