/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit

private struct ErrorToastDefaultUX {
    static let cornerRadius: CGFloat = 40
    static let fillColor = UIColor(red: 186/255, green: 32/255, blue: 36/255, alpha: 1)
    static let margins = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
    static let textColor = UIColor.white
}

class ErrorToast: UIView {
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = ErrorToastDefaultUX.textColor
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    var cornerRadius: CGFloat = ErrorToastDefaultUX.cornerRadius {
        didSet {
            setNeedsDisplay()
        }
    }

    var fillColor: UIColor = ErrorToastDefaultUX.fillColor {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        addSubview(textLabel)
        textLabel.snp_makeConstraints { make in
            make.edges.equalTo(self).inset(ErrorToastDefaultUX.margins)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        fillColor.setFill()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        path.fill()
    }
}
