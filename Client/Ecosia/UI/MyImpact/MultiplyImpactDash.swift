/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class MultiplyImpactDash: UIView, NotificationThemeable {
    private weak var dash: CAShapeLayer?

    required init?(coder: NSCoder) { nil }
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false
        
        let dash = CAShapeLayer()
        dash.backgroundColor = UIColor.clear.cgColor
        dash.lineWidth = 2
        dash.lineDashPattern = [4, 4]
        layer.addSublayer(dash)
        self.dash = dash
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dash?.frame = .init(origin: .zero, size: frame.size)
        dash?.path = {
            $0.move(to: .init(x: 6, y: 0))
            $0.addLine(to: .init(x: 6, y: frame.height))
            return $0
        } (CGMutablePath())
    }
    
    func applyTheme() {
        dash?.strokeColor = UIColor.theme.ecosia.secondaryText.cgColor
    }
}
